# Rightshare-contracts
Rightshare Smart Contracts. Refer https://rinkeby-rightshare.lendroid.com

## Framework
The architecture comprises 4 main smart contracts:

1. Right.sol
2. FRight.sol
3. IRight.sol
4. RightsDao.sol

All the contracts in this repository have been written in Solidity v.5.11.

Please use Git commits according to this article: https://chris.beams.io/posts/git-commit

## Installation and setup
* Clone this repository

  `git clone <repo>`

* cd into the cloned repo

  `cd Rightshare-contracts`

* Install dependencies via npm

  `npm install`


## Test and development

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
