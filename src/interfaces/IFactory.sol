// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IFactory {
    function deploy_gauge(address lpToken, address manager) external returns (address);
    function deploy_gauge(address lpToken, bytes32 salt, address manager) external returns (address);
    function owner() external view returns (address);
}
