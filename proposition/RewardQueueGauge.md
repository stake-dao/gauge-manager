# Permissionless Extra Reward Management

## Current State

Currently, Curve gauges must define a `depositor` associated with an extra reward to prevent other users from overriding the reward period end. This avoids scenarios where users could:

- Instantly distribute the total amount of rewards,
- Force the distribution to span an excessively long period, effectively reducing the distribution rate to nearly zero.

## Why Make Extra Rewards Permissionless?

With the rise of various vote incentive platforms and the feature of setting a maximum price per vote, a key question has emerged: *"What should be done with unused tokens?"*

### Possible Solutions

1. **Roll Over to the Next Incentive Period**
   - Some protocols cannot adopt this approach due to governance-imposed incentive budgets per period, which must be adhered to.

2. **Directly Incentivize Liquidity**
   - Unused tokens can be deposited directly as extra rewards to incentivize liquidity providers.

As many vote incentive platforms are seeking to incorporate this feature, they all require the ability to deposit extra rewards, provided these are added to the extra reward list.

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
