// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "forge-std/src/Script.sol";

import "src/GaugeManager.sol";

interface IImmutableFactory {
    function deployCreate3(bytes32 salt, bytes memory initializationCode) external payable returns (address);
}

abstract contract Deploy is Script {
    string chain;
    address agent;
    address factory;

    address public constant FACTORY = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;
    address public constant DEPLOYER = 0x000755Fbe4A24d7478bfcFC1E561AfCE82d1ff62;

    constructor(string memory _chain, address _agent, address _factory) {
        chain = _chain;
        agent = _agent;
        factory = _factory;
    }

    function run() public {
        vm.createSelectFork(vm.rpcUrl(chain));
        vm.startBroadcast(DEPLOYER);

        bytes32 salt = bytes32(0x000755fbe4a24d7478bfcfc1e561afce82d1ff6200c332bd460c10be0287c6e2);

        /// 1. Deploy the LiquidityGauge Implementation.
        bytes memory gaugeImplementationCode = vm.getCode("LiquidityGauge");

        address gaugeImplementation;

        if (block.chainid == 1) {
            gaugeImplementation = IImmutableFactory(FACTORY).deployCreate3(salt, gaugeImplementationCode);
        } else {
            gaugeImplementation = address(0);
        }

        salt = bytes32(0x000755fbe4a24d7478bfcfc1e561afce82d1ff620035656a98d28a73027aa15f);

        /// 2. Deploy the GaugeManager.
        IImmutableFactory(FACTORY).deployCreate3(
            salt, abi.encodePacked(type(GaugeManager).creationCode, abi.encode(agent, factory, gaugeImplementation))
        );

        vm.stopBroadcast();
    }
}
