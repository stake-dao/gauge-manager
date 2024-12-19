// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/StdUtils.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge {
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function add_reward(address _rewards_token, address _manager) external;
    function totalSupply() external view returns (uint256);
    function deposit(uint256 _value) external;
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claim_rewards() external;
    function set_gauge_manager(address) external; 
    function manager() external view returns(address);

    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }
    function reward_data(address) external returns(Reward memory);
}

contract LiquidityGaugeTest is Test {

    ILiquidityGauge liquidityGauge;

    // Liquidity gauge params
    address manager = makeAddr("manager");
    address lpToken = address(0xCA0253A98D16e9C1e3614caFDA19318EE69772D0); // sdCRV/CRV lp token
    address rewardToken = address(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F); // SDT

    // Users
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address david = makeAddr("david");

    // Amounts
    uint256 lpAmount = 100 ether;
    uint256 rewardTokenAmount = 100 ether;
    uint256 WEEK = 1 weeks;

    function setUp() public {
        // Deploy Liquidity gauge contract
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        
        liquidityGauge = ILiquidityGauge(deployCode("LiquidityGaugeCurrent", abi.encode(lpToken)));
        
        // Deal lp tokens to users
        deal(lpToken, alice, lpAmount);
        // deal(lpToken, bob, lpAmount);
        // deal(lpToken, charlie, lpAmount);
        // deal(lpToken, david, lpAmount);

        // Deal reward tokens to users
        deal(rewardToken, manager, 10 * rewardTokenAmount);

        // Add SDT as extra reward
        vm.prank(liquidityGauge.manager());
        liquidityGauge.add_reward(rewardToken, manager);
    }

    function testLiquidityGauge() public {

        uint256 depositRewardAmount = 1 ether;
        vm.startPrank(alice);
        IERC20(lpToken).approve(address(liquidityGauge), lpAmount);
        liquidityGauge.deposit(lpAmount);
        vm.stopPrank();

        vm.startPrank(manager);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);
    
        skip(7 days);

        uint256 expectedClaimable = depositRewardAmount;
        console.log(liquidityGauge.claimable_reward(alice, rewardToken));
        assertApproxEqAbs(liquidityGauge.claimable_reward(alice, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        vm.startPrank(manager);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        expectedClaimable = depositRewardAmount;
        console.log(liquidityGauge.claimable_reward(alice, rewardToken));
        assertApproxEqAbs(liquidityGauge.claimable_reward(alice, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        skip(7 days);

        expectedClaimable = 2*depositRewardAmount;
        console.log(liquidityGauge.claimable_reward(alice, rewardToken));
        assertApproxEqAbs(liquidityGauge.claimable_reward(alice, rewardToken), expectedClaimable, expectedClaimable / 10e10);

    }

}
