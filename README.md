[![Lint](https://github.com/ivivanov/vending-machine-sol/actions/workflows/lint.yml/badge.svg?branch=master)](https://github.com/ivivanov/vending-machine-sol/actions/workflows/lint.yml)
[![Tests](https://github.com/ivivanov/vending-machine-sol/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/ivivanov/vending-machine-sol/actions/workflows/tests.yml)

# Vending Machine Smart Contract

## Environment

Make sure to create `.env` file. Use `.env.example` for reference.

## How to use

- Install dependencies

  ```
  yarn
  ```

- Testing (with gas reporter)

  ```
  yarn test
  ```

- Deploy on the default network

  ```
  yarn deploy
  ```

- Deploy & verify contracts on Ropsten

  ```
  yarn deploy --network ropsten
  ```

- Generate coverage report. See `./coverage/index.html`.

  ```
  yarn coverage
  ```

- Fixes linting errors for common files in the project (.sol, .js, .md, ...)
  ```
  yarn lint:fix
  ```

## Other

- Deployment is done with [hardhat-deploy](https://github.com/wighawag/hardhat-deploy/tree/master) plugin.

- Slither reports [here](https://github.com/ivivanov/vending-machine-sol/actions/workflows/slither.yml).

## Known issues

- Currently we have potential DOS attack vector on `function setPrice` because of the strict equality in the require
- Anybody can send cola token to the machine address and essentially re-stock it.

## TODOs

- Add dockerfile to run Slither locally. Currently runs only in gh-actions
- Add more tests
- Test abstract contract Operated without ColaMachine
- Improve documentation
- Think about splitting IColaMachine interface and make new one IColaMachineAdmin
- Think about extracting DAI payments as separate module
- Add testnet deploy pipeline
