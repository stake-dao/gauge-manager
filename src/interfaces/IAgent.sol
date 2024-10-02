// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IAgent {
    function execute(address target, uint256 value, bytes memory data) external;
}
