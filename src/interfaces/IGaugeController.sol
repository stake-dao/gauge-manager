// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IGaugeController {
    function add_gauge(address addr, int128 gauge_type, uint256 weight) external;
}
