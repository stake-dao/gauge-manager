// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface ILiquidityGaugeV1 {
    struct Reward {
        address token;
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }

    function reward_data(address token) external view returns (Reward memory);
}
