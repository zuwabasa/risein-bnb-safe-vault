# Safe Vault for BNB Chain

Final project for [Rise In BNB Chain Course 3](https://www.risein.com/courses/smart-contract-and-dapp-development-on-bnb-chain/smart-contract-final-project).

Safe Vault holds a supported ERC-20 token for a user-selected period. Each account has one independent active position. Only the depositing account can use the contract's methods to read or withdraw that position. Blockchain state is public.

The contract calculates a simple annual reward of 5%, prorated by elapsed time and capped at the unlock date. It returns the deposited principal on withdrawal. The calculated reward appears in the frontend and in the withdrawal event. The allowed lock period is one second through 365 days.

## Run locally

If you are viewing the course submission on GitHub, download and extract `risein-bnb-safe.zip` to get the complete project with its folder structure.

Requires Node.js 20 or newer and npm.

```sh
npm install
npm run compile
npm test
npm run demo
```

Open [the demo](http://127.0.0.1:4173). Claim the test tokens and select a deposit amount and duration. Approve and lock the deposit. Switch to the second demo account to see its independent position. Switch back to the original account and withdraw after maturity. The local blockchain starts fresh each time the demo restarts.

## Files

- `contracts/SafeVault.sol` contains the token lock, reward calculation and withdrawal logic.
- `contracts/DemoToken.sol` supplies test tokens for the local demo.
- `web/` contains the browser UI for the local deployment.
- `tests/vault.test.cjs` covers deposits, input validation, failed transfers, isolation, maturity, reward calculation and withdrawals.

## Deployment scope

The project was compiled with Solidity 0.8.30 targeting Shanghai and tested on a local EVM. The local UI uses pre-funded demo accounts through a loopback-only endpoint. For a BNB Chain deployment, use a conventional ERC-20 token that returns standard transfer results and preserves exact transfer amounts. Fee-on-transfer and rebasing tokens are outside the supported model. The demo token is intended for local testing.
