// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/StdUtils.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge {
    function deposit_reward_token(address _reward_token, uint256 _amount, uint256 _epoch) external;
    function add_reward(address _rewards_token) external;
    function totalSupply() external view returns (uint256);
    function deposit(uint256 _value) external;
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claim_rewards() external;
    function set_gauge_manager(address) external; 
    function manager() external view returns(address);
    function reward_queue(address _reward_token) external view returns(uint256);

    struct Reward {
        address token;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }
    function reward_data(address) external returns(Reward memory);
}

contract LiquidityGaugePermissionLess3Test is Test {

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
        liquidityGauge = ILiquidityGauge(deployCode("LiquidityGaugePermissionless3", abi.encode(lpToken)));
        
        vm.prank(liquidityGauge.manager());
        liquidityGauge.set_gauge_manager(manager);
        
        // Deal lp tokens to users
        deal(lpToken, alice, lpAmount);
        deal(lpToken, bob, lpAmount);
        deal(lpToken, charlie, lpAmount);
        deal(lpToken, david, lpAmount);

        // Deal reward tokens to users
        deal(rewardToken, alice, rewardTokenAmount);
        deal(rewardToken, bob, rewardTokenAmount);
        deal(rewardToken, charlie, rewardTokenAmount);

        // Add SDT as extra reward
        vm.prank(manager);
        liquidityGauge.add_reward(rewardToken);
    }

    function testDepositRewardToken() public {

        uint256 depositRewardAmount = 1 ether;
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, WEEK);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);
    }

    function testDepositRewardTokenMultipleDepositors() public {

        uint256 depositRewardAmount = 1 ether;

        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, WEEK);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 3*depositRewardAmount);

        vm.expectRevert("Shortening current distribution is not allowed");
        liquidityGauge.deposit_reward_token(rewardToken, 3*depositRewardAmount, WEEK/2);
        vm.expectRevert("Diluting current distribution is not allowed");
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, 10*WEEK);

        liquidityGauge.deposit_reward_token(rewardToken, 3*depositRewardAmount, 2*WEEK);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, 2*depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + 2*WEEK);
    }

    function testDepositDifferentTimestamps() public {
        uint256 depositRewardAmount = 1 ether;
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount, WEEK);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, (4 * depositRewardAmount) / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        skip(8 days);

        // As previous reward distribution is finished, Bob can deposit at a lower rate
        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, WEEK);
        vm.stopPrank();
    
        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

    }

    function testClaimableAndClaim() public {
        uint256 depositLpAmount = 10 ether;
        uint256 depositRewardAmount = 1 ether;

        // David deposits lp into the gauge
        vm.startPrank(david);
        IERC20(lpToken).approve(address(liquidityGauge), depositLpAmount);
        liquidityGauge.deposit(depositLpAmount);
        vm.stopPrank();   
     
        // Alice deposits rewards into the gauge
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, WEEK);
        vm.stopPrank();

        skip(4 days);

        // David should be able to claim around 4 7th of the deposit
        uint256 expectedClaimable = 4 * depositRewardAmount / 7;
        assertApproxEqRel(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, 10e8);

        // Bob deposits rewards into the gauge, it will be placed into the reward_queue
        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount, 3* WEEK);
        vm.stopPrank();

        uint256 expectedNewRate = (3 * depositRewardAmount / 7 + 4 * depositRewardAmount) / (3*WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).rate, expectedNewRate);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + 3*WEEK);

        skip(22 days);

        // First distribution is over, david should be able to claim all the deposited rewards (minus roundings)
        expectedClaimable = 5 * depositRewardAmount;
        assertApproxEqRel(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, 10e8);

        vm.prank(david);
        liquidityGauge.claim_rewards();

        assertApproxEqRel(IERC20(rewardToken).balanceOf(david), expectedClaimable, 10e10);
    }

    function testMultipleDepositorsAndLp() public {
        uint256 depositLpAmount = 10 ether;
        uint256 depositRewardAmount = 1 ether;

        // David deposits lp into the gauge
        vm.startPrank(david);
        IERC20(lpToken).approve(address(liquidityGauge), depositLpAmount);
        liquidityGauge.deposit(depositLpAmount);
        vm.stopPrank();   
     
        // Alice deposits rewards into the gauge
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount, WEEK);
        vm.stopPrank();

        skip(4 days);

        // David should be able to claim around 4 7th of the deposit
        uint256 expectedClaimable = 4 * depositRewardAmount / 7;
        assertApproxEqRel(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, 10e8);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount, 3*WEEK);
        vm.stopPrank();

        // Charlie deposits twice as much lp as David
        vm.startPrank(charlie);
        IERC20(lpToken).approve(address(liquidityGauge), 2*depositLpAmount);
        liquidityGauge.deposit(2*depositLpAmount);
        vm.stopPrank();  

        skip(7 days);

        uint256 expectedNewRate = (3 * depositRewardAmount / 7 + 4 * depositRewardAmount) / (3*WEEK);

        uint256 expectedClaimableDavid = 4 * depositRewardAmount/7 + expectedNewRate * WEEK / 3;
        uint256 expectedClaimableCharlie = expectedNewRate * WEEK * 2 / 3;

        assertApproxEqRel(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimableDavid, 10e8);
        assertApproxEqRel(liquidityGauge.claimable_reward(charlie, rewardToken), expectedClaimableCharlie, 10e8);

        // Bob deposits lp into the gauge
        vm.startPrank(bob);
        IERC20(lpToken).approve(address(liquidityGauge), depositLpAmount);
        liquidityGauge.deposit(depositLpAmount);
        vm.stopPrank();

        skip(21 days);

        // compute each user share of rewards and check the claimable
        uint256 expectedClaimableBob = expectedNewRate * 14 days / 4;
        expectedClaimableCharlie += expectedNewRate * 14 days / 2;
        expectedClaimableDavid += expectedNewRate * 14 days / 4;

        assertApproxEqRel(liquidityGauge.claimable_reward(bob, rewardToken), expectedClaimableBob, 10e8);
        assertApproxEqRel(liquidityGauge.claimable_reward(charlie, rewardToken), expectedClaimableCharlie, 10e8);
        assertApproxEqRel(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimableDavid, 10e8);

        // David claims rewards
        vm.prank(david);
        liquidityGauge.claim_rewards();

        assertApproxEqRel(IERC20(rewardToken).balanceOf(david), expectedClaimableDavid, (expectedClaimableDavid) / 10e8);
    }
}
