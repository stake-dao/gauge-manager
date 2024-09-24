// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Base} from "./Base.t.sol";

string constant MAINNET = "mainnet";
address constant MAINNET_LP_TOKEN = address(0x73e4BeC1A111869F395cBB24F6676826BF86d905);
address constant MAINNET_AGENT = address(0x40907540d8a6C65c637785e8f8B742ae6b0b9968);
address constant MAINNET_FACTORY = address(0x0000000000000000000000000000000000000000);

contract Mainnet is Base(MAINNET, MAINNET_AGENT, MAINNET_FACTORY, MAINNET_LP_TOKEN, 20_521_327) {}

string constant ARBITRUM = "arbitrum";
address constant ARBITRUM_LP_TOKEN = address(0x096A8865367686290639bc50bF8D85C0110d9Fea);
address constant ARBITRUM_AGENT = address(0x452030a5D962d37D97A9D65487663cD5fd9C2B32);
address constant ARBITRUM_FACTORY = address(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

contract Arbitrum is Base(ARBITRUM, ARBITRUM_AGENT, ARBITRUM_FACTORY, ARBITRUM_LP_TOKEN, 236_267_630) {}
