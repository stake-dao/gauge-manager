// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/mocks/MockERC20.sol";

import "src/GaugeManager.sol";
import "src/interfaces/ILiquidityGauge.sol";

abstract contract BaseTest is Test {
    uint256 public blockNumber;

    string public chain;
    address lpToken;
    address public gauge;
    address public agent;
    address public factory;
    address public gaugeImplementation;

    MockERC20 public rewardToken;

    GaugeManager public gaugeManager;

    address public constant ROOT_GAUGE_FACTORY = address(0x306A45a1478A000dC701A6e1f7a569afb8D9DCD6);

    constructor(
        string memory _chain,
        address _gauge,
        address _agent,
        address _factory,
        address _lpToken,
        uint256 _blockNumber
    ) {
        chain = _chain;
        agent = _agent;
        factory = _factory;
        lpToken = _lpToken;
        gauge = _gauge;
        blockNumber = _blockNumber;
    }

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl(chain), blockNumber);

        gaugeImplementation = address(deployCode("LiquidityGauge"));
        gaugeManager = new GaugeManager(agent, factory, gaugeImplementation);

        rewardToken = new MockERC20();
        rewardToken.initialize("Reward Token", "RT", 18);

        if (factory != address(0)) {
            vm.prank(IFactory(factory).future_owner());
            IFactory(factory).accept_transfer_ownership();
        }
    }

    function testDeployment() public view {
        assertEq(gaugeManager.AGENT(), agent);
        assertEq(gaugeManager.FACTORY(), factory);
        assertEq(gaugeManager.GAUGE_IMPLEMENTATION(), gaugeImplementation);
        assertEq(gaugeManager.CHAIN_ID(), block.chainid);
    }

    function test_deployGauge() public {
        address _gauge = gaugeManager.deployGauge(lpToken);
        assertNotEq(_gauge, address(0));
        assertEq(ILiquidityGauge(_gauge).lp_token(), lpToken);

        if (block.chainid == 1) {
            vm.expectRevert("Gauge is already initialized");
        } else {
            vm.expectRevert();
        }
        ILiquidityGauge(_gauge).initialize(lpToken, address(gaugeManager));

        assertEq(gaugeManager.managers(_gauge), address(this));

        /// 1. Test transferring the gauge to another manager
        address newManager = address(0x123);

        vm.expectRevert(GaugeManager.NotManager.selector);
        vm.prank(address(0xBEEF));
        gaugeManager.setManager(_gauge, newManager);

        gaugeManager.setManager(_gauge, newManager);
        assertEq(gaugeManager.managers(_gauge), newManager);

        /// 2. Test adding a reward token
        vm.expectRevert(GaugeManager.NotManager.selector);
        vm.prank(address(0xBEEF));
        gaugeManager.addReward(_gauge, address(rewardToken));

        vm.prank(newManager);
        gaugeManager.addReward(_gauge, address(rewardToken));

        assertEq(ILiquidityGauge(_gauge).reward_count(), 1);
        assertEq(ILiquidityGauge(_gauge).reward_tokens(0), address(rewardToken));

        ILiquidityGauge.Reward memory reward = ILiquidityGauge(_gauge).reward_data(address(rewardToken));
        assertEq(reward.distributor, address(gaugeManager));

        /// 3. Test depositing a reward token
        deal(address(rewardToken), address(this), 100 ether);
        rewardToken.approve(address(gaugeManager), 100 ether);
        gaugeManager.depositRewardToken(_gauge, address(rewardToken), 100 ether);

        assertEq(rewardToken.balanceOf(address(_gauge)), 100 ether);
        reward = ILiquidityGauge(_gauge).reward_data(address(rewardToken));
        assertEq(reward.periodFinish, block.timestamp + 1 weeks);
        assertEq(reward.lastUpdate, block.timestamp);

        /// 4. CURVE ADMIN: Test setting the gauge manager
        vm.expectRevert(GaugeManager.NotAgent.selector);
        gaugeManager.setGaugeManager(_gauge, address(0xBEEF));

        vm.prank(agent);
        gaugeManager.setGaugeManager(_gauge, address(0xBEEF));
        assertEq(ILiquidityGauge(_gauge).manager(), address(0xBEEF));

        /// 6. CURVE ADMIN: Test setting the reward distributor
        vm.expectRevert(GaugeManager.NotAgent.selector);
        gaugeManager.setRewardDistributor(_gauge, address(rewardToken), address(0xBEEF));

        vm.prank(agent);
        gaugeManager.setRewardDistributor(_gauge, address(rewardToken), address(0xBEEF));
        assertEq(ILiquidityGauge(_gauge).reward_data(address(rewardToken)).distributor, address(0xBEEF));

        uint256 chainId = block.chainid;
        if (chainId != 1) {
            vm.createSelectFork(vm.rpcUrl("mainnet"));
            bytes32 salt = bytes32(abi.encode(lpToken, address(gaugeManager)));
            address _rootGauge = IFactory(ROOT_GAUGE_FACTORY).deploy_gauge(chainId, salt);
            assertEq(ILiquidityGauge(_rootGauge).child_gauge(), _gauge);
        }
    }

    function test_migrateGauge() public {
        address _agent = agent;
        if (block.chainid != 1) {
            agent = IFactory(ILiquidityGauge(gauge).factory()).owner();
        }

        uint256 rewardCount = ILiquidityGauge(gauge).reward_count();
        for (uint256 i; i < rewardCount; i++) {
            address _rewardToken = ILiquidityGauge(gauge).reward_tokens(i);

            vm.prank(agent);
            ILiquidityGauge(gauge).set_reward_distributor(_rewardToken, address(gaugeManager));
        }

        vm.prank(agent);
        ILiquidityGauge(gauge).add_reward(address(rewardToken), agent);

        vm.prank(agent);
        if (block.chainid == 1) {
            ILiquidityGauge(gauge).set_gauge_manager(address(gaugeManager));
        } else {
            ILiquidityGauge(gauge).set_manager(address(gaugeManager));
        }

        vm.prank(_agent);
        vm.expectRevert(GaugeManager.InvalidRewardDistributor.selector);
        gaugeManager.claimManager(gauge, address(0xBEEF));

        // assertEq(gaugeManager.managers(gauge), address(0xBEEF));
        // assertEq(ILiquidityGauge(gauge).manager(), address(gaugeManager));
    }
}
