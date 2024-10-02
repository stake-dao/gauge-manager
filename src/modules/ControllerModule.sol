// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// Libraries
import {LibString} from "solady/src/utils/LibString.sol";

/// Project Interfaces
import {Module} from "src/modules/Module.sol";
import {IAgent} from "src/interfaces/IAgent.sol";
import {IGauge} from "src/interfaces/IGauge.sol";
import {IVoting} from "src/interfaces/IVoting.sol";
import {IGaugeController} from "src/interfaces/IGaugeController.sol";

/// @title ControllerModule
/// @notice A module for proposing and executing gauge additions through a voting mechanism
contract ControllerModule is Module {
    /// @notice Identifier for the call script
    bytes4 public constant CALLSCRIPT_ID = 0x00000001;

    /// @notice Address of the voting contract for ownership decisions
    address public constant VOTING_OWNERSHIP = 0xE478de485ad2fe566d49342Cbd03E49ed7DB3356;

    /// @notice Address of the agent contract
    address public constant AGENT = 0x40907540d8a6C65c637785e8f8B742ae6b0b9968;

    /// @notice Address of the gauge controller contract
    address public constant GAUGE_CONTROLLER = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;

    /// @notice Mapping from day timestamp to an array of queued gauges
    mapping(uint256 => address[]) public queuedGauges;

    /// @notice Address of the current governance
    address public governance;

    /// @notice Address of the future governance (used in governance transfer process)
    address public futureGovernance;

    /// @notice Maximum number of gauges that can be proposed per day
    uint256 public limitPerDay;

    /// @notice Emitted when gauges are proposed
    /// @param day The timestamp of the day when gauges were proposed
    /// @param gauges Array of proposed gauge addresses
    event GaugesProposed(uint256 indexed day, address[] gauges);

    /// @notice Emitted when trying to execute votes before the required time has passed
    error VotesTooEarly();

    /// @notice Emitted when trying to execute votes for a day with no queued gauges
    error NoQueuedGauges();

    /// @notice Emitted when trying to propose more gauges than the daily limit allows
    error TooManyGauges();

    /// @notice Emitted when a non-governance address attempts to call a governance-only function
    error NotGovernance();

    /// @notice Emitted when trying to propose an invalid gauge address
    error InvalidGauge();

    /// @notice Ensures that only the governance address can call the function
    modifier onlyGovernance() {
        if (msg.sender != governance) {
            revert NotGovernance();
        }
        _;
    }

    /// @notice Initializes the ControllerModule
    /// @param _governance Address of the initial governance
    /// @param _limitPerDay Maximum number of gauges that can be proposed per day
    constructor(address _governance, uint256 _limitPerDay) {
        governance = _governance;
        limitPerDay = _limitPerDay;
    }

    /// @notice Propose gauges to be added
    /// @param gauges Array of gauge addresses to propose
    function proposeGauges(address[] memory gauges) external {
        uint256 day = block.timestamp / 1 days * 1 days;

        if (queuedGauges[day].length + gauges.length > limitPerDay) {
            revert TooManyGauges();
        }

        address gauge;
        for (uint256 i = 0; i < gauges.length; i++) {
            gauge = gauges[i];
            if (gauge == address(0)) {
                revert InvalidGauge();
            }
            queuedGauges[day].push(gauge);
        }

        emit GaugesProposed(day, gauges);
    }

    /// @notice Execute the queued votes for a specific day
    /// @param day The timestamp of the day to execute votes for
    function executeQueuedVotes(uint256 day) external {
        if (block.timestamp < day + 1 days) {
            revert VotesTooEarly();
        }

        address[] storage gauges = queuedGauges[day];
        if (gauges.length == 0) {
            revert NoQueuedGauges();
        }

        bytes memory executionScript = _getExecutionScript(GAUGE_CONTROLLER, gauges);

        string memory description = "Add ";
        for (uint256 i = 0; i < gauges.length; i++) {
            description = LibString.concat(description, IGauge(gauges[i]).symbol());
            if (i < gauges.length - 1) {
                description = LibString.concat(description, " ");
            }
        }

        bytes memory newVoteData =
            abi.encodeWithSelector(IVoting.newVote.selector, executionScript, description, false, false);

        _executeWithLocker(VOTING_OWNERSHIP, newVoteData);

        delete queuedGauges[day];
    }

    /// @notice Generate the execution script for adding gauges
    /// @param _gaugeController Address of the gauge controller
    /// @param _gauges Array of gauge addresses to add
    /// @return bytes The generated execution script
    function _getExecutionScript(address _gaugeController, address[] memory _gauges)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory callScript = abi.encodePacked(CALLSCRIPT_ID);

        bytes memory gaugeCalldata;
        bytes memory agentCalldata;

        for (uint256 i = 0; i < _gauges.length; i++) {
            gaugeCalldata = abi.encodeWithSelector(IGaugeController.add_gauge.selector, _gauges[i], 0, 0);
            agentCalldata = abi.encodeWithSelector(IAgent.execute.selector, _gaugeController, 0, gaugeCalldata);

            uint32 length = uint32(agentCalldata.length);

            callScript = abi.encodePacked(callScript, AGENT, length, agentCalldata);
        }

        return callScript;
    }

    /// @notice Set the maximum number of gauges that can be proposed per day
    /// @param _limitPerDay New limit of gauges per day
    function setLimitPerDay(uint256 _limitPerDay) external onlyGovernance {
        limitPerDay = _limitPerDay;
    }

    /// @notice Get the list of queued gauges for a specific day
    /// @param _day The timestamp of the day to get queued gauges for
    /// @return An array of queued gauge addresses for the specified day
    function getQueuedGauges(uint256 _day) external view returns (address[] memory) {
        return queuedGauges[_day];
    }

    /// @notice Replace the queued gauges for a specific day
    /// @param _day The timestamp of the day to replace gauges for
    /// @param _gauges Array of gauge addresses to replace with
    function replaceQueuedGauges(uint256 _day, address[] memory _gauges) external onlyGovernance {
        queuedGauges[_day] = _gauges;
    }

    /// @notice Cancel the queued gauges for a specific day
    /// @param _day The timestamp of the day to cancel gauges for
    function cancelQueuedVotes(uint256 _day) external onlyGovernance {
        delete queuedGauges[_day];
    }

    /// @notice Initiate the governance transfer process
    /// @param _futureGovernance Address of the proposed future governance
    function transferGovernance(address _futureGovernance) external onlyGovernance {
        futureGovernance = _futureGovernance;
    }

    /// @notice Complete the governance transfer process
    /// @dev Can only be called by the address set as futureGovernance
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) {
            revert NotGovernance();
        }

        governance = msg.sender;

        futureGovernance = address(0);
    }
}