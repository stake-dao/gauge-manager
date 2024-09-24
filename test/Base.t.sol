// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/mocks/MockERC20.sol";

import "src/GaugeManager.sol";
import "src/interfaces/ILiquidityGauge.sol";

abstract contract Base is Test {
    uint256 public blockNumber;

    string public chain;
    address lpToken;
    address public agent;
    address public factory;
    address public gaugeImplementation;

    MockERC20 public rewardToken;

    GaugeManager public gaugeManager;

    constructor(string memory _chain, address _agent, address _factory, address _lpToken, uint256 _blockNumber) {
        chain = _chain;
        agent = _agent;
        factory = _factory;
        lpToken = _lpToken;

        blockNumber = _blockNumber;
    }

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl(chain), blockNumber);

        gaugeImplementation = address(deployCode("LiquidityGauge"));
        gaugeManager = new GaugeManager(agent, factory, gaugeImplementation);

        rewardToken = new MockERC20();
        rewardToken.initialize("Reward Token", "RT", 18);
    }

    function testDeployment() public view {
        assertEq(gaugeManager.AGENT(), agent);
        assertEq(gaugeManager.FACTORY(), factory);
        assertEq(gaugeManager.GAUGE_IMPLEMENTATION(), gaugeImplementation);
        assertEq(gaugeManager.CHAIN_ID(), block.chainid);
    }

    function test_deployGauge() public {
        address gauge = gaugeManager.deployGauge(lpToken);
        assertNotEq(gauge, address(0));
        assertEq(ILiquidityGauge(gauge).lp_token(), lpToken);

        if (block.chainid == 1) {
            vm.expectRevert("Gauge is already initialized");
        } else {
            vm.expectRevert();
        }
        ILiquidityGauge(gauge).initialize(lpToken, address(gaugeManager));

        assertTrue(gaugeManager.managers(gauge, address(this)));
        assertFalse(gaugeManager.managers(gauge, address(0xBEEF)));

        /// 1. Test transferring the gauge to another manager
        address newManager = address(0x123);

        vm.expectRevert(GaugeManager.NotManager.selector);
        vm.prank(address(0xBEEF));
        gaugeManager.setManager(gauge, newManager);

        gaugeManager.setManager(gauge, newManager);
        assertTrue(gaugeManager.managers(gauge, newManager));
        assertFalse(gaugeManager.managers(gauge, address(this)));

        /// 2. Test adding a reward token
        vm.expectRevert(GaugeManager.NotManager.selector);
        vm.prank(address(0xBEEF));
        gaugeManager.addReward(gauge, address(rewardToken));

        vm.prank(newManager);
        gaugeManager.addReward(gauge, address(rewardToken));

        assertEq(ILiquidityGauge(gauge).reward_count(), 1);
        assertEq(ILiquidityGauge(gauge).reward_tokens(0), address(rewardToken));

        ILiquidityGauge.Reward memory reward = ILiquidityGauge(gauge).reward_data(address(rewardToken));
        assertEq(reward.distributor, address(gaugeManager));

        /// 3. Test depositing a reward token
        deal(address(rewardToken), address(this), 100 ether);
        rewardToken.approve(address(gaugeManager), 100 ether);
        gaugeManager.depositRewardToken(gauge, address(rewardToken), 100 ether);

        assertEq(rewardToken.balanceOf(address(gauge)), 100 ether);
        reward = ILiquidityGauge(gauge).reward_data(address(rewardToken));
        assertEq(reward.periodFinish, block.timestamp + 1 weeks);
        assertEq(reward.lastUpdate, block.timestamp);

        /// 4. CURVE ADMIN: Test setting the gauge manager
        vm.expectRevert(GaugeManager.NotAgent.selector);
        gaugeManager.setGaugeManager(gauge, address(0xBEEF));

        if (block.chainid == 1) { 
            vm.prank(agent);
            gaugeManager.setGaugeManager(gauge, address(0xBEEF));
            assertEq(ILiquidityGauge(gauge).manager(), address(0xBEEF));

            /// 5. CURVE ADMIN: Test setting the killed flag
            vm.expectRevert(GaugeManager.NotAgent.selector);
            gaugeManager.setKilled(gauge, true);

            vm.prank(agent);
            gaugeManager.setKilled(gauge, true);
            assertTrue(ILiquidityGauge(gauge).is_killed());

            vm.prank(agent);
            gaugeManager.setKilled(gauge, false);
            assertFalse(ILiquidityGauge(gauge).is_killed());

            /// 6. CURVE ADMIN: Test setting the reward distributor
            vm.expectRevert(GaugeManager.NotAgent.selector);
            gaugeManager.setRewardDistributor(gauge, address(rewardToken), address(0xBEEF));

            vm.prank(agent);
            gaugeManager.setRewardDistributor(gauge, address(rewardToken), address(0xBEEF));
            assertEq(ILiquidityGauge(gauge).reward_data(address(rewardToken)).distributor, address(0xBEEF));
        }
    }
}
