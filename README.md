# usdc-supply-coverage-dashboard
Project Overview

This project uses Dune SQL to build a stablecoin monitoring dashboard for USDC on Ethereum. The dashboard analyses USDC minting, burning, net supply change, circulating supply trend, and estimated reserve coverage ratio.

The purpose of this project is to connect traditional finance reconciliation logic with stablecoin operations. It demonstrates how public on-chain data can be used to monitor token supply movement, while issuer-published reserve disclosures can be incorporated to estimate reserve coverage on an as-of basis.

This is a learning-based portfolio project. It is not a production-grade reserve attestation system.

Key Outputs

The dashboard includes:

USDC circulating supply trend
Daily minted amount
Daily burned amount
Daily net supply change
Estimated reserve surplus
Estimated reserve coverage ratio
Latest dashboard KPI summary
Methodology
1. Circulating Supply

USDC supply movement is calculated from ERC-20 Transfer events.

Minting is identified when USDC is transferred from the zero address:

from = 0x0000000000000000000000000000000000000000

Burning is identified when USDC is transferred to the zero address:

to = 0x0000000000000000000000000000000000000000

The daily net supply change is calculated as:

daily net supply change = daily minted amount - daily burned amount

Circulating supply is calculated as the cumulative sum of daily net supply changes.

2. Reserve Coverage Ratio

Reserve figures are manually entered from issuer-published reserve disclosures or assurance reports.

Because reserve data is off-chain, the dashboard uses the latest available reserve figure as of each date. This means the coverage ratio is an estimated monitoring view, not a real-time reserve attestation.

The estimated coverage ratio is calculated as:

coverage ratio = latest reported reserves / on-chain circulating supply
3. Important Limitation

On-chain supply is directly observable from blockchain data. Reserve assets are off-chain and must be sourced from issuer disclosures or independent assurance reports. Therefore, this dashboard should be understood as an operating and reconciliation-style monitoring project, not a complete audit or attestation system.

Token Information
Token: USDC
Blockchain: Ethereum
Contract Address: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
Decimals: 6
Dashboard Design

Recommended Dune dashboard sections:

Chart 1 — USDC Circulating Supply Trend
X-axis: day
Y-axis: circulating_supply
Chart type: Line chart
Chart 2 — Daily Minted vs Burned Amount
X-axis: day
Y-axis: daily_minted, daily_burned
Chart type: Bar chart or area chart
Chart 3 — Daily Net Supply Change
X-axis: day
Y-axis: daily_net_change
Chart type: Bar chart
Chart 4 — Estimated Reserve Coverage Ratio
X-axis: day
Y-axis: coverage_ratio_pct
Chart type: Line chart
KPI Cards
Latest circulating supply
Latest reported reserves
Latest reserve surplus
Latest coverage ratio
Coverage status
Repository Structure
usdc-supply-coverage-dashboard/
├── README.md
├── sql/
│   ├── 01_usdc_supply_trend.sql
│   ├── 02_usdc_reserve_coverage_ratio.sql
│   └── 03_latest_dashboard_kpis.sql
├── docs/
│   ├── methodology.md
│   └── reserve_data_template.md
└── screenshots/
    ├── usdc_supply_trend.png
    ├── mint_burn_activity.png
    └── reserve_coverage_ratio.png
Portfolio Relevance

This project demonstrates practical understanding of stablecoin supply monitoring, reserve coverage logic, and reconciliation-style exception review. It connects my traditional finance operations background with stablecoin operations and on-chain analytics use cases.
