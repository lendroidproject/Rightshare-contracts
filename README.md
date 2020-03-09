# LeaseERC721
Protocol to support leasing of ERC721 standard Tokens

## Framework
The smart contracts have been written in [Vyper version 0.1.16](https://vyper.readthedocs.io "Vyper ReadTheDocs") and compiled using using the [Brownie Framework](https://eth-brownie.readthedocs.io "eth-brownie"). Unit and functional test cases have been written using the Pytest framework.

Please use Git commits according to this article: https://chris.beams.io/posts/git-commit

## Installation and setup
* Clone this repository

  `git clone <repo>`

* cd into the cloned repo

  `cd protocol.2.0`

* Install dependencies via npm

  `npm install ganache-cli@istanbul -g`


* Install Python and Vyper v0.1.0-beta.16

  * Python 3.7 is a pre-requisite, and can be installed from [here](https://www.python.org/downloads "Python version downloads")

  * Install virtualenv from pip

    `pip install virtualenv` or `pip3 install virtualenv`

  * Create a virtual environment

    `virtualenv -p python3.7 --no-site-packages ~/vyper-venv`

  * Activate Vyper's virtual environment

    `source ~/vyper-venv/bin/activate`

  * Install dependencies from requirements.txt via pip

    `pip install -r requirements.txt`

## Test and development

* Activate Vyper's virtual environment

  `source ~/vyper-venv/bin/activate`


* Compile using brownie

  `brownie compile`

* Run the tests with coverage

  `brownie test --coverage`

  <i>Note : Version 1.5.1 of brownie requires the following patch:
  * Within the virtual env, navigate to the brownie package installed in python3 site-packages.
  * edit `brownie/network/transaction.py` and add a `try, catch` around the line `pc = last["pc_map"][trace[i]["pc"]]` like this
  ```
  try:
      pc = last["pc_map"][trace[i]["pc"]]
  except KeyError:
      continue
  ```
  </i>


_Note_: When the development / testing session ends, deactivate the virtualenv

`(vyper-venv) $ deactivate`
