// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface ILiquidityGauge {
    struct RewardV1 {
        address token;
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }
    struct Reward {
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }

    function initialize(address lpToken, address manager) external;

    function add_reward(address token, address distributor) external;
    function deposit_reward_token(address token, uint256 amount) external;
    function reward_data(address token) external view returns (Reward memory);

    function set_killed(bool isKilled) external;
    function set_manager(address manager) external;
    function set_gauge_manager(address manager) external;
    function set_reward_distributor(address token, address distributor) external;

    function manager() external view returns (address);
    function factory() external view returns (address);
    function lp_token() external view returns (address);
    function child_gauge() external view returns (address);
    function reward_count() external view returns (uint256);
    function reward_tokens(uint256 index) external view returns (address);
    function is_killed() external view returns (bool);
}
