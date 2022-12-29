# Rightshare package
The Rightshare package comprises the following tools. Please feel free to use them (in any combination) to deploy your own Rightshare ecosystem.

## Smart contracts
The architecture comprises 4 main smart contracts:

1. Right.sol
2. FRight.sol
3. IRight.sol
4. RightsDao.sol

All the contracts in this repository have been written in Solidity v.5.11.

- [Github](https://github.com/lendroidproject/Rightshare-contracts)
- [Audit report](https://github.com/lendroidproject/Rightshare-contracts/blob/master/audit-report.pdf)
- [PoC](https://rinkeby-rightshare.lendroid.com)

## Javascript library
Nodejs implementation for user interface to interact with the smart contracts.
- [Github](https://github.com/lendroidproject/Rightshare-js)
## UI template
A base template of the user interface.
- [Github](https://github.com/lendroidproject/Rightshare-ui)
## Frontend server
A server implementation on Google Cloud (Python)
- [Github](https://github.com/lendroidproject/Rightshare-frontend)
## Metadata server
An API server implementation on Google Cloud (Python) to create an image based on on-chain metadata
- [Github](https://github.com/lendroidproject/Rightshare-metadata)
## Technical Documentation
Technical Documentation on how to use the Javascript library and UI template
- [Github](https://github.com/lendroidproject/Rightshare-documentation)

## How to use this repo

### Installation and setup
* Clone this repository

  `git clone <repo>`

* cd into the cloned repo

  `cd Rightshare-contracts`

* Install dependencies via npm

  `npm install`


### Test and development

* Open new terminal, run ganache

  `ganache-cli`

* Open new terminal, activate the virtual environment

  `source ~/venv-rightshare/bin/activate`

* Compile using truffle

  `truffle compile`

* Run the tests

  `truffle test`

_Note_: When the development / testing session ends, deactivate the virtualenv

`(venv-rightshare) $ deactivate`
