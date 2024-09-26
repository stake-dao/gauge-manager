// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IFactory {
    function deploy_gauge(uint256 chaindID, bytes32 salt) external payable returns (address);
    function deploy_gauge(address lpToken, address manager) external returns (address);
    function deploy_gauge(address lpToken, bytes32 salt, address manager) external returns (address);
    function owner() external view returns (address);

    function future_owner() external view returns (address);
    function accept_transfer_ownership() external;
}
