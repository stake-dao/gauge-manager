# Gauge Manager

## Overview

Gauge Manager is a contract that allows to deploy liquidity gauges on multiple networks, be the common reward distributor for all of them, with permissionless access, and allows the deployer to manage them, by adding extra rewards.

Regular admin functions are restricted to the on-chain governance of the platform built-upon, here Curve.fi.

It is built to overcome the limitation where only one eligible address can provide extra rewards to a gauge, by being the reward distributor.


Diffchecker between the original and the forked curve gauge: [Diffchecker](https://www.diffchecker.com/DgtQBG6Y)


## Deployments

| Chain    | Gauge Manager Address |
|----------|------------------------|
| Mainnet  | [0x00502000990000205700324b0811BAAA2Fff00aE](https://etherscan.io/address/0x00502000990000205700324b0811BAAA2Fff00aE) |
| Arbitrum | [0x00502000990000205700324b0811BAAA2Fff00aE](https://arbiscan.io/address/0x00502000990000205700324b0811BAAA2Fff00aE) |
| Base     | [0x00502000990000205700324b0811BAAA2Fff00aE](https://basescan.org/address/0x00502000990000205700324b0811BAAA2Fff00aE) |
| Optimism | [0x00502000990000205700324b0811BAAA2Fff00aE](https://optimistic.etherscan.io/address/0x00502000990000205700324b0811BAAA2Fff00aE) |
| Polygon  | [0x00502000990000205700324b0811BAAA2Fff00aE](https://polygonscan.com/address/0x00502000990000205700324b0811BAAA2Fff00aE) |
| Frax     | [0x00502000990000205700324b0811BAAA2Fff00aE](https://fraxscan.com/address/0x00502000990000205700324b0811BAAA2Fff00aE) |


## How to use

### Mainnet

The mainnet gauge manager uses a custom liquidity gauge implementation. Just hit deploy.

### Sidechains

For the sidechains, the gauge manager uses the Curve Factory. 
Process is in two steps:
1. Deploy the gauge using the gauge manager.
2. With the salt used in the first step, create the curve gauge on the mainnet using the `ROOT_FACTORY` address`

ROOT_FACTORY: https://etherscan.io/address/0x306A45a1478A000dC701A6e1f7a569afb8D9DCD6#code