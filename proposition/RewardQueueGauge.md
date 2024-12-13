# Permissionless Extra Reward Management

## Current State

Currently, Curve gauges must define a `depositor` associated with an extra reward to prevent other users from overriding the reward period end. This avoids scenarios where users could:

- Instantly distribute the total amount of rewards,
- Force the distribution to span an excessively long period, effectively reducing the distribution rate to nearly zero.

## Why Make Extra Rewards Permissionless?

Defining a `depositor` introduces **Inefficiency for Incentive Depositors**. Having a predefined depositor makes it difficult for multiple actors to collaborate or deposit, and could lead to multiple governance proposals to transfer depositor rights between actors.

Addressing this issue requires a permissionless approach, enabling any participant to deposit rewards without disrupting existing setups.

## Proposed Solution

The proposed solution involves adding a reward queue feature to Curve liquidity gauges to enable permissionless extra rewards. The mechanics would work as follows:

- **Reward Period**: Always set to one week.
- **No Active Rewards Streaming**: If `period_finish` in the reward data is less than the current `block.timestamp`, the current logic remains unchanged.
- **Active Rewards Streaming**:
  - Any newly added rewards are deposited into a `reward_queue` variable.
  - This queue keeps track of rewards deposited by any user.
- **Checkpoint Process**:
  - During a `checkpoint_reward` call, if rewards are not currently streaming and the `reward_queue` contains tokens, the rewards are moved into the active stream using the existing reward logic.

This approach allows multiple incentive platforms and depositors to add rewards permissionlessly without interfering with each other's deposits.

## For Already Deployed Gauges

A gauge manager contract could be deployed to replicate this reward queue behavior and act as the `depositor` for the gauge. However, the reward queue distribution would need to be managed externally (e.g., via a bot), as it cannot be directly integrated into the `checkpoint_reward` process.
