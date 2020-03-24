# Rightshare-contracts
Rightshare Smart Contracts. Refer https://rinkeby-rightshare.lendroid.com

## Framework
The architecture comprises 4 main smart contracts:

1. Right.sol
2. FRight.sol
3. IRight.sol
4. RightsDao.vy

The Rights have been written in Solidity v.6.0, while the Dao has been written in [Vyper version 0.1.16](https://vyper.readthedocs.io "Vyper ReadTheDocs").

Please use Git commits according to this article: https://chris.beams.io/posts/git-commit

## Installation and setup
* Clone this repository

  `git clone <repo>`

* cd into the cloned repo

  `cd Rightshare-contracts`

* Install dependencies via npm

  `npm install`


* Install Python and Vyper v0.1.0-beta.16

  * Python 3.7 is a pre-requisite, and can be installed from [here](https://www.python.org/downloads "Python version downloads")

  * Install virtualenv from pip

    `pip install virtualenv` or `pip3 install virtualenv`

  * Create a virtual environment

    `virtualenv -p python3.7 --no-site-packages ~/venv-rightshare`

  * Activate the virtual environment

    `source ~/venv-rightshare/bin/activate`

  * Install dependencies from requirements.txt via pip

    `pip install -r requirements.txt`

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
