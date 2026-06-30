# Methodology

## Objective

This project monitors USDC supply movement and estimated reserve coverage using Dune SQL.

The dashboard is designed to demonstrate how public blockchain data can support stablecoin operations, supply monitoring, and reconciliation-style review.

## Data Sources

### On-Chain Data

On-chain data is sourced from Dune's token transfer dataset. The dashboard focuses on USDC on Ethereum.

USDC mint and burn activity is identified through ERC-20 Transfer events involving the zero address.

### Off-Chain Reserve Data

Reserve figures are manually entered from issuer-published reserve disclosures or assurance reports.

Because reserve figures are off-chain, the dashboard uses the latest available reserve figure as of each date. This approach provides an estimated monitoring view rather than a real-time attestation.

## Calculations

### Daily Minted Amount

Daily minted amount is the total USDC transferred from the zero address on a given date.

### Daily Burned Amount

Daily burned amount is the total USDC transferred to the zero address on a given date.

### Daily Net Supply Change

```text
daily net supply change = daily minted amount - daily burned amount
