// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "script/Deploy.s.sol";

string constant MAINNET = "mainnet";
address constant MAINNET_AGENT = address(0x40907540d8a6C65c637785e8f8B742ae6b0b9968);
address constant MAINNET_FACTORY = address(0x0000000000000000000000000000000000000000);

contract Mainnet is Deploy(MAINNET, MAINNET_AGENT, MAINNET_FACTORY) {}

string constant ARBITRUM = "arbitrum";
address constant ARBITRUM_AGENT = address(0x452030a5D962d37D97A9D65487663cD5fd9C2B32);
address constant ARBITRUM_FACTORY = address(0x988d1037e9608B21050A8EFba0c6C45e01A3Bce7);

contract Arbitrum is Deploy(ARBITRUM, ARBITRUM_AGENT, ARBITRUM_FACTORY) {}

string constant BASE = "base";
address constant BASE_AGENT = address(0x2c163fe0f079d138b9c04f780d735289344C8B80);
address constant BASE_FACTORY = address(0xe35A879E5EfB4F1Bb7F70dCF3250f2e19f096bd8);

contract Base is Deploy(BASE, BASE_AGENT, BASE_FACTORY) {}

string constant OPTIMISM = "optimism";
address constant OPTIMISM_AGENT = address(0x28c4A1Fa47EEE9226F8dE7D6AF0a41C62Ca98267);
address constant OPTIMISM_FACTORY = address(0x871fBD4E01012e2E8457346059e8C189d664DbA4);

contract Optimism is Deploy(OPTIMISM, OPTIMISM_AGENT, OPTIMISM_FACTORY) {}

string constant POLYGON = "polygon";
address constant POLYGON_AGENT = address(0xbD2D41dBBC5A13B1c883F6c62b14924AeAef4483);
address constant POLYGON_FACTORY = address(0x55a1C26CE60490A15Bdd6bD73De4F6346525e01e);

contract Polygon is Deploy(POLYGON, POLYGON_AGENT, POLYGON_FACTORY) {}

string constant FRAX = "frax";
address constant FRAX_AGENT = address(0x4BbdFEd5696b3a8F6B3813506b5389959C5CDC57);
address constant FRAX_FACTORY = address(0x0B8D6B6CeFC7Aa1C2852442e518443B1b22e1C52);

contract Frax is Deploy(FRAX, FRAX_AGENT, FRAX_FACTORY) {}
