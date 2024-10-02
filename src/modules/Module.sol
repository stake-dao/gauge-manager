// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IStrategy} from "src/interfaces/IStrategy.sol";

abstract contract Module {
    address public constant LOCKER = 0x52f541764E6e90eeBc5c21Ff570De0e2D63766B6;

    IStrategy public constant STRATEGY = IStrategy(0x69D61428d089C2F35Bf6a472F540D0F82D1EA2cd);

    function _executeWithLocker(address target, bytes memory data) internal {
        bytes memory lockerData = abi.encodeWithSelector(IStrategy.execute.selector, target, 0, data);

        STRATEGY.execute(LOCKER, 0, lockerData);
    }
}
