// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGaugeManager {
    function CHAIN_ID() external view returns (uint256);

    function AGENT() external view returns (address);
    function FACTORY() external view returns (address);
    function GAUGE_IMPLEMENTATION() external view returns (address);

    function deploy_gauge(address lpToken) external returns (address);
    function set_manager(address gauge, address manager) external;
    function add_reward(address gauge, address token) external;
    function deposit_reward_token(address gauge, address token, uint256 amount) external;
}
