// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";
import "forge-std/src/StdUtils.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityGauge {
    function initialize(address _lp_token, address _manager) external;
    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function add_reward(address _rewards_token) external;
    function totalSupply() external view returns (uint256);
    function deposit(uint256 _value) external;
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claim_rewards() external;

    struct Reward {
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }
    function reward_data(address) external returns(Reward memory);
}

contract LiquidityGaugePermissionlessTest is Test {

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
        liquidityGauge = ILiquidityGauge(deployCode("LiquidityGaugePermissionless", abi.encode(address(this))));
        liquidityGauge.initialize(lpToken, manager);

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

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        assertEq(liquidityGauge.reward_data(rewardToken).rate, 2 * depositRewardAmount / WEEK);
        assertEq(liquidityGauge.reward_data(rewardToken).period_finish, block.timestamp + WEEK);
    }

    function testDepositDifferentTimestamps() public {
        uint256 depositRewardAmount = 1 ether;
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        skip(4 days);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 2 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 2 * depositRewardAmount);
        vm.stopPrank();

        // expect 3/7 * first deposit as leftover, plus new deposit amount
        uint256 expectedRate = (3 * depositRewardAmount / 7 + 2 * depositRewardAmount) / WEEK;

        assertEq(liquidityGauge.reward_data(rewardToken).rate, expectedRate);
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
     
        vm.startPrank(alice);
        IERC20(rewardToken).approve(address(liquidityGauge), depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, depositRewardAmount);
        vm.stopPrank();

        skip(4 days);

        uint256 expectedClaimable = 4 * depositRewardAmount / 7;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        vm.startPrank(bob);
        IERC20(rewardToken).approve(address(liquidityGauge), 2 * depositRewardAmount);
        liquidityGauge.deposit_reward_token(rewardToken, 2 * depositRewardAmount);
        vm.stopPrank();

        skip(8 days);

        expectedClaimable = 3 * depositRewardAmount;
        assertApproxEqAbs(liquidityGauge.claimable_reward(david, rewardToken), expectedClaimable, expectedClaimable / 10e10);

        vm.prank(david);
        liquidityGauge.claim_rewards();

        assertApproxEqAbs(IERC20(rewardToken).balanceOf(david), expectedClaimable, expectedClaimable / 10e10);

    }
}
