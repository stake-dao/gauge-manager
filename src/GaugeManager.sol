// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "src/interfaces/IFactory.sol";
import "src/interfaces/ILiquidityGauge.sol";

import "solady/src/utils/LibClone.sol";
import "solady/src/utils/SafeTransferLib.sol";

/// @title GaugeManager
contract GaugeManager {
    using LibClone for address;

    /// @notice Address of Curve.fi Agent.
    address public immutable AGENT;

    /// @notice Chain ID
    uint256 public immutable CHAIN_ID;

    /// @notice Factory to deploy gauges.
    address public immutable FACTORY;

    /// @notice Gauge Implementation
    address public immutable GAUGE_IMPLEMENTATION;

    /// @notice Mapping of managers for gauges.
    mapping(address => address) public managers;

    constructor(address _agent, address _factory, address _gaugeImplementation) {
        CHAIN_ID = block.chainid;
        AGENT = _agent;
        FACTORY = _factory;
        GAUGE_IMPLEMENTATION = _gaugeImplementation;
    }

    /// @notice Emitted when a gauge is deployed.
    event GaugeDeployed(address gauge, address manager);

    /// @notice Error thrown when the manager is not the gauge manager.
    error InvalidManager();

    /// @notice Error thrown when the reward distributor is not the agent.
    error InvalidRewardDistributor();

    /// @notice Error thrown when the caller is not a manager of the given gauge.
    error NotManager();

    /// @notice Error thrown when the caller is not the agent.
    error NotAgent();

    /// @notice Error thrown when the gauge is already claimed.
    error AlreadyClaimed();

    /// @notice Error thrown when the caller is not the agent.
    modifier onlyAgent() {
        if (msg.sender != AGENT) revert NotAgent();
        _;
    }

    /// @notice Modifier to check if the caller is a manager of the given gauge.
    modifier onlyManagerOrAgent(address gauge) {
        if (managers[gauge] != msg.sender && msg.sender != AGENT) revert NotManager();
        _;
    }

    /// @notice Deploy a gauge for the given lpToken.
    /// @dev If the CHAIN_ID is 1, we clone the gauge implementation. Otherwise, we deploy the gauge from the FACTORY.
    /// The gauge implementation from official factories on sidechains allows to set a custom manager, while the factories on mainnet do not.
    function deployGauge(address lpToken) public returns (address gauge) {
        if (CHAIN_ID == 1) {
            gauge = LibClone.clone(GAUGE_IMPLEMENTATION);
            ILiquidityGauge(gauge).initialize(lpToken, address(this));
        } else {
            bytes32 salt = bytes32(abi.encode(lpToken, address(this)));
            gauge = IFactory(FACTORY).deploy_gauge(lpToken, salt, address(this));
        }

        /// Set the manager.
        managers[gauge] = msg.sender;

        emit GaugeDeployed(gauge, msg.sender);
    }

    /// @notice Set the manager of the given gauge.
    function setManager(address gauge, address manager) public onlyManagerOrAgent(gauge) {
        managers[gauge] = manager;
    }

    /// @notice Add a reward token to the given gauge.
    function addReward(address gauge, address token) public onlyManagerOrAgent(gauge) {
        ILiquidityGauge(gauge).add_reward(token, address(this));
    }

    function depositRewardToken(address gauge, address token, uint256 amount) public {
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amount);
        SafeTransferLib.safeApproveWithRetry(token, gauge, amount);
        ILiquidityGauge(gauge).deposit_reward_token(token, amount);
    }

    ////////////////////////////////////////////////////////////
    /// --- CURVE ADMIN FUNCTIONS
    /// @dev These functions are used by the Curve.fi Agent, and most likely can be triggered only on L1. (for now)
    ////////////////////////////////////////////////////////////

    function claimManager(address gauge, address manager) public onlyAgent {
        if (managers[gauge] != address(0)) revert AlreadyClaimed();
        if (ILiquidityGauge(gauge).manager() != address(this)) revert InvalidManager();

        uint256 rewardCount = ILiquidityGauge(gauge).reward_count();

        for (uint256 i = 0; i < rewardCount; i++) {
            address token = ILiquidityGauge(gauge).reward_tokens(i);
            ILiquidityGauge.Reward memory reward = ILiquidityGauge(gauge).reward_data(token);
            if (reward.distributor != address(this)) {
                revert InvalidRewardDistributor();
            }
        }

        managers[gauge] = manager;
    }

    function setGaugeManager(address gauge, address manager) public onlyAgent {
        ILiquidityGauge(gauge).set_gauge_manager(manager);
    }

    function setRewardDistributor(address gauge, address token, address distributor) public onlyAgent {
        ILiquidityGauge(gauge).set_reward_distributor(token, distributor);
    }

    /// @notice Returns the address of this contract.
    /// @dev To be compatible with the gauge implementation, with minimum changes.
    function admin() public view returns (address) {
        return address(this);
    }
}
