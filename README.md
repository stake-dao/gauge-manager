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

### Migration of an existing gauge

In order to migrate an existing gauge and set the manager to the gauge manager, the steps are the following:

Gauge manager:
1. On the gauge manager, call `transferManager(gauge)` with the manager address. This steps is necessary to retrieve the manager ROLE later.

Gauge:

2. Set the reward distributor of all extra rewards to the gauge manager.
3. Transfer the manager to the gauge manager using `set_gauge_manager(gaugeManager)`.

Gauge manager:

4. Call `claimManager(gauge, manager, isV1)` with the manager address. This steps is necessary to complete the migration. It'll check that the previous steps were correctly executed and set the maanger address as allowed address to provide extra rewards.

If using the manager address is not possible, this process can be done using the Curve Governance veCRV, doing all the steps starting from the step 2 for the gauge.



### Controller Module

The controller module is a module that allows to propose and add new votes for  gauge additions in the Gauge Controller using the Stake DAO CRV Locker.

| Chain    | Controller Module Address |
|----------|------------------------|
| Mainnet  | [0xE56cE16f36f9A92281d6296ef9Ca14c271bdE0b4](https://etherscan.io/address/0xE56cE16f36f9A92281d6296ef9Ca14c271bdE0b4) |