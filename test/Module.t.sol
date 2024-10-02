// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/src/Test.sol";

import "src/interfaces/IStrategy.sol";
import "src/modules/ControllerModule.sol";

contract ModuleTest is Test {
    ControllerModule public controllerModule;

    address convexProxy = 0x989AEb4d175e16225E39E87d0D97A3360524AD80;

    function setUp() public virtual {
        /// Block number is only for caching.
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20_878_555);

        controllerModule = new ControllerModule(address(0xBEEF), 10);

        IStrategy strategy = controllerModule.STRATEGY();
        address governance = strategy.governance();
        vm.prank(governance);
        strategy.allowAddress(address(controllerModule));
    }

    function test_proposeGauges() public {
        address[] memory gauges = new address[](3);
        gauges[0] = address(1);
        gauges[1] = address(2);
        gauges[2] = address(3);

        controllerModule.proposeGauges(gauges);

        uint256 day = block.timestamp / 1 days * 1 days;

        address[] memory queuedGauges = controllerModule.getQueuedGauges(day);

        assertEq(queuedGauges.length, 3);

        assertEq(queuedGauges[0], address(1));
        assertEq(queuedGauges[1], address(2));
        assertEq(queuedGauges[2], address(3));

        gauges = new address[](7);

        vm.expectRevert(ControllerModule.InvalidGauge.selector);
        controllerModule.proposeGauges(gauges);

        for (uint256 i = 0; i < 7; i++) {
            gauges[i] = address(uint160(i + 1));
        }

        controllerModule.proposeGauges(gauges);

        queuedGauges = controllerModule.getQueuedGauges(day);
        assertEq(queuedGauges.length, 10);

        vm.expectRevert(ControllerModule.TooManyGauges.selector);
        controllerModule.proposeGauges(gauges);

        gauges = new address[](1);
        gauges[0] = address(0xCAFE);

        vm.prank(address(0xBEEF));
        controllerModule.replaceQueuedGauges(day, gauges);

        queuedGauges = controllerModule.getQueuedGauges(day);
        assertEq(queuedGauges.length, 1);
        assertEq(queuedGauges[0], address(0xCAFE));

        vm.prank(address(0xBEEF));
        controllerModule.cancelQueuedVotes(day);

        queuedGauges = controllerModule.getQueuedGauges(day);
        assertEq(queuedGauges.length, 0);
    }

    function test_executeQueuedVotes() public {
        address[] memory gauges = new address[](3);
        gauges[0] = address(0x97826750c5B66EDce3Ce503783B5BE2938Ec6e5A);
        gauges[1] = address(0x0C5fa0C51C63CE937C588225C202b04c30F3CEeE);
        gauges[2] = address(0x2CBEecEE6140e6392Ac770D0F30D80d7EFD82240);

        uint256 day = block.timestamp / 1 days * 1 days;

        controllerModule.proposeGauges(gauges);

        vm.expectRevert(ControllerModule.VotesTooEarly.selector);
        controllerModule.executeQueuedVotes(day);

        skip(1 days);
        controllerModule.executeQueuedVotes(day);

        address voting = controllerModule.VOTING_OWNERSHIP();
        vm.prank(convexProxy);
        IVoting(voting).votePct(860, 1e18, 0, false);

        address locker = controllerModule.LOCKER();

        vm.prank(locker);
        IVoting(voting).votePct(860, 1e18, 0, false);

        skip(7 days + 1);
        IVoting(voting).executeVote(860);

        IVoting.Vote memory vote = IVoting(voting).getVote(860);
        assertEq(vote.executed, true);
    }

    function test_transferGovernance() public {
        address newGovernance = address(0xDEAD);

        vm.expectRevert(ControllerModule.NotGovernance.selector);
        controllerModule.transferGovernance(newGovernance);

        vm.prank(address(0xBEEF));
        controllerModule.transferGovernance(newGovernance);

        assertEq(controllerModule.futureGovernance(), newGovernance);

        skip(1 days);

        vm.expectRevert(ControllerModule.NotGovernance.selector);
        controllerModule.acceptGovernance();

        vm.prank(newGovernance);
        controllerModule.acceptGovernance();

        assertEq(controllerModule.governance(), newGovernance);
        assertEq(controllerModule.futureGovernance(), address(0));
    }
}
