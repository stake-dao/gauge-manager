// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/StdUtils.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge {
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
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

contract LiquidityGaugeRewardQueueTest is Test {

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
        liquidityGauge = ILiquidityGauge(deployCode("LiquidityGaugeRewardQueue", abi.encode(lpToken)));
        
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
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);
    }

    function testDepositRewardTokenMultipleDepositors() public {

        uint256 depositRewardAmount = 1 ether;

        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        // Expect deposit to be streamed 
        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        // Expect reward_queue to be almost empty (less than a seconds in a week), should be the rounding difference
        uint256 roundingDiff = depositRewardAmount - (depositRewardAmount / WEEK) * WEEK;
        assertLt(liquidityGauge.reward_queue(rewardToken), WEEK);
        assertEq(liquidityGauge.reward_queue(rewardToken), roundingDiff);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 2*depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 2*depositRewardAmount);
        vm.stopPrank();

        // Expect stream to be unchanged 
        assertEq(liquidityGauge.reward_data(rewardToken).rate, depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        // Expect second deposit to be in reward_queue, with rounding difference of first deposit
        assertEq(liquidityGauge.reward_queue(rewardToken), 2*depositRewardAmount + roundingDiff);
    }

    function testDepositDifferentTimestamps() public {
        uint256 depositRewardAmount = 1 ether;
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        uint256 roundingDiff = depositRewardAmount - (depositRewardAmount / WEEK) * WEEK;

        skip(8 days);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount);
        vm.stopPrank();
    
        // Expect new deposit + rounding diff from previous deposit to be streaming
        assertEq(liquidityGauge.reward_data(rewardToken).rate, (4 * depositRewardAmount + roundingDiff) / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        // Expect reward_queue amount to be the rounding left of the new deposit + rounding diff from previous deposits
        uint256 newRoundingDiff = (4 * depositRewardAmount + roundingDiff) - ((4 * depositRewardAmount + roundingDiff) / WEEK) * WEEK;
        assertEq(liquidityGauge.reward_queue(rewardToken), newRoundingDiff);

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
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        skip(4 days);

        // David should be able to claim around 4 7th of the deposit
        uint256 expectedClaimable = 4 * depositRewardAmount / 7;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        // Bob deposits rewards into the gauge, it will be placed into the reward_queue
        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount);
        vm.stopPrank();

        skip(7 days);

        // First distribution is over, david should be able to claim all the first deposit rewards (minus roundings)
        expectedClaimable = depositRewardAmount;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        vm.prank(david);
        liquidityGauge.claim_rewards();

        // Claim should trigger the distribution of reward_queue
        uint256 roundingDiff = depositRewardAmount - (depositRewardAmount / WEEK) * WEEK;

        assertEq(liquidityGauge.reward_data(rewardToken).rate, (4 * depositRewardAmount + roundingDiff) / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);

        skip(8 days);

        uint256 expectedClaimable2 = 4 * depositRewardAmount;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable2, expectedClaimable2 / 10e10);

        vm.prank(david);
        liquidityGauge.claim_rewards();

        assertApproxEqAbs(IERC20(rewardToken).balanceOf(david), expectedClaimable + expectedClaimable2, (expectedClaimable+ expectedClaimable2) / 10e10);
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
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        skip(4 days);

        // David should be able to claim around 4 7th of the deposit
        uint256 expectedClaimable = 4 * depositRewardAmount / 7;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        // Bob deposits rewards into the gauge, it will be placed into the reward_queue
        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 4 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 4 * depositRewardAmount);
        vm.stopPrank();

        // Charlie deposits twice as much lp as David
        vm.startPrank(charlie);
        IERC20(lpToken).approve(address(liquidityGauge), 2*depositLpAmount);
        liquidityGauge.deposit(2*depositLpAmount);
        vm.stopPrank();  

        skip(7 days);

        // First distribution is over, david should be able to claim 4/7 of the first deposit rewards before charlie deposit, and one third of the rewards left for the period, total 5/7 (minus roundings)
        // Charlie should be able to claim the rest of it, total - 5/7 of the first deposit
        expectedClaimable = 5 * depositRewardAmount/7 ;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);
        assertApproxEqAbs(liquidityGauge.claimable_reward(charlie, rewardToken), (depositRewardAmount - expectedClaimable), (depositRewardAmount - expectedClaimable) / 10e10);

        // Bob deposits lp into the gauge
        vm.startPrank(bob);
        IERC20(lpToken).approve(address(liquidityGauge), depositLpAmount);
        liquidityGauge.deposit(depositLpAmount);
        vm.stopPrank();

        // Deposit should trigger the distribution of reward_queue
        uint256 roundingDiff = depositRewardAmount - (depositRewardAmount / WEEK) * WEEK;

        ILiquidityGauge.Reward memory reward_data = liquidityGauge.reward_data(rewardToken);
        assertEq(reward_data.rate, (4 * depositRewardAmount + roundingDiff) / WEEK);
        assertEq(reward_data.period_finish, block.timestamp + WEEK);

        skip(8 days);

        // compute each user share of rewards and check the claimable
        uint256 expectedClaimableBob = depositRewardAmount;
        uint256 expectedClaimableCharlie = 2 * depositRewardAmount + 2*depositRewardAmount / 7;
        uint256 expectedClaimableDavid = depositRewardAmount + 5*depositRewardAmount / 7;

        assertApproxEqAbs(liquidityGauge.claimable_reward(bob, rewardToken), expectedClaimableBob, expectedClaimableBob / 10e10);
        assertApproxEqAbs(liquidityGauge.claimable_reward(charlie, rewardToken), expectedClaimableCharlie, expectedClaimableCharlie / 10e10);
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimableDavid, expectedClaimableDavid / 10e10);

        // David claims rewards
        vm.prank(david);
        liquidityGauge.claim_rewards();

        assertApproxEqAbs(IERC20(rewardToken).balanceOf(david), expectedClaimableDavid, (expectedClaimableDavid) / 10e10);

        // As no new reward has been pushed, reward distribution should remain unchanged
        assertEq(reward_data.rate, liquidityGauge.reward_data(rewardToken).rate);
        assertEq(reward_data.period_finish, liquidityGauge.reward_data(rewardToken).period_finish);
    }
}
