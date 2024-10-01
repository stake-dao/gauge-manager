# Gauge Manager

## Overview

Gauge Manager is a contract that allows to deploy liquidity gauges on multiple networks, be the common reward distributor for all of them, with permissionless access, and allows the deployer to manage them, by adding extra rewards.

Regular admin functions are restricted to the on-chain governance of the platform built-upon, here Curve.fi.

It is built to overcome the limitation where only one eligible address can provide extra rewards to a gauge, by being the reward distributor.


Diffchecker between the original and the forked curve gauge: [Diffchecker](https://www.diffchecker.com/DgtQBG6Y)


## Deployments

| Chain    | Gauge Manager Address |
|----------|------------------------|
| Mainnet  | [0x740000c9192a33004F2002D988210000C173cB00](https://etherscan.io/address/0x740000c9192a33004F2002D988210000C173cB00) |
| Arbitrum | [0x740000c9192a33004F2002D988210000C173cB00](https://arbiscan.io/address/0x740000c9192a33004F2002D988210000C173cB00) |
| Base     | [0x740000c9192a33004F2002D988210000C173cB00](https://basescan.org/address/0x740000c9192a33004F2002D988210000C173cB00) |
| Optimism | [0x740000c9192a33004F2002D988210000C173cB00](https://optimistic.etherscan.io/address/0x740000c9192a33004F2002D988210000C173cB00) |
| Polygon  | [0x740000c9192a33004F2002D988210000C173cB00](https://polygonscan.com/address/0x740000c9192a33004F2002D988210000C173cB00) |
| Frax     | [0x740000c9192a33004F2002D988210000C173cB00](https://fraxscan.com/address/0x740000c9192a33004F2002D988210000C173cB00) |


## How to use

### Mainnet

The mainnet gauge manager uses a custom liquidity gauge implementation. Just hit deploy.

### Sidechains

For the sidechains, the gauge manager uses the Curve Factory. 
Process is in two steps:
1. Deploy the gauge using the gauge manager.
2. With the salt used in the first step, create the curve gauge on the mainnet using the `ROOT_FACTORY` address and the function `deploy_gauge`.

ROOT_FACTORY: [0x306A45a1478A000dC701A6e1f7a569afb8D9DCD6](https://etherscan.io/address/0x306A45a1478A000dC701A6e1f7a569afb8D9DCD6)

The result of step 2 should be a gauge on the mainnet, with `child_gauge()` pointing to the gauge deployed in step 1.