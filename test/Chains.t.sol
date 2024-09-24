// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/Base.t.sol";

string constant MAINNET = "mainnet";
address constant MAINNET_LP_TOKEN = address(0x73e4BeC1A111869F395cBB24F6676826BF86d905);
address constant MAINNET_AGENT = address(0x40907540d8a6C65c637785e8f8B742ae6b0b9968);
address constant MAINNET_FACTORY = address(0x0000000000000000000000000000000000000000);

contract Mainnet is BaseTest(MAINNET, MAINNET_AGENT, MAINNET_FACTORY, MAINNET_LP_TOKEN, 20_521_327) {}

string constant ARBITRUM = "arbitrum";
address constant ARBITRUM_LP_TOKEN = address(0x096A8865367686290639bc50bF8D85C0110d9Fea);
address constant ARBITRUM_AGENT = address(0x452030a5D962d37D97A9D65487663cD5fd9C2B32);
address constant ARBITRUM_FACTORY = address(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

contract Arbitrum is BaseTest(ARBITRUM, ARBITRUM_AGENT, ARBITRUM_FACTORY, ARBITRUM_LP_TOKEN, 236_267_630) {}

string constant BASE = "base";
address constant BASE_LP_TOKEN = address(0xf6C5F01C7F3148891ad0e19DF78743D31E390D1f);
address constant BASE_AGENT = address(0xe8269B33E47761f552E1a3070119560d5fa8bBD6);
address constant BASE_FACTORY = address(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

contract Base is BaseTest(BASE, BASE_AGENT, BASE_FACTORY, BASE_LP_TOKEN, 3_481_165) {}

string constant OPTIMISM = "optimism";
address constant OPTIMISM_LP_TOKEN = address(0xd8dD9a8b2AcA88E68c46aF9008259d0EC04b7751);
address constant OPTIMISM_AGENT = address(0x28c4A1Fa47EEE9226F8dE7D6AF0a41C62Ca98267);
address constant OPTIMISM_FACTORY = address(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

contract Optimism is BaseTest(OPTIMISM, OPTIMISM_AGENT, OPTIMISM_FACTORY, OPTIMISM_LP_TOKEN, 118_200_613) {}


string constant POLYGON = "polygon";
address constant POLYGON_LP_TOKEN = address(0x864490Cf55dc2Dee3f0ca4D06F5f80b2BB154a03);
address constant POLYGON_AGENT = address(0xbD2D41dBBC5A13B1c883F6c62b14924AeAef4483);
address constant POLYGON_FACTORY = address(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

contract Polygon is BaseTest(POLYGON, POLYGON_AGENT, POLYGON_FACTORY, POLYGON_LP_TOKEN, 53_080_567) {}