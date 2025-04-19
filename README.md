# STX Bond Vault Smart Contract

## Description

The **STX Bond Vault** is a Clarity smart contract designed for the Stacks blockchain that allows users to lock STX tokens for a fixed period in exchange for a guaranteed yield. It enables decentralized and trustless bond issuance, encouraging long-term participation and liquidity locking through customizable bond terms.

## Features

- 🔒 **Bond Locking:** Users can create bond positions by locking STX for a predefined period.
- 📈 **Guaranteed Yield:** Earn fixed rewards based on the bond tier and lock duration.
- 🕒 **Bond Maturity:** Users can redeem their STX and rewards once the bond matures.
- ⚙️ **Customizable Tiers:** Supports multiple bond tiers with different durations and reward rates.
- 💼 **Admin Controls:** Admin can set bond parameters and fund the reward pool.

## Core Functions

- `create-bond`: Lock STX to create a bond based on a chosen tier.
- `redeem-bond`: Redeem the principal and yield after the bond matures.
- `add-bond-tier`: Admin-only function to define new bond tiers.
- `fund-rewards`: Add STX to the reward pool for bond payouts.
- `get-user-bonds`: View active and matured bonds for a user.
- `get-bond-info`: View bond tier configurations and vault statistics.

## Setup & Testing

Built with [Clarinet](https://docs.stacks.co/docs/clarity/clarinet/overview/) for smart contract development on Stacks.

### Run Tests

```bash
clarinet test
