# Convert Monero Seeds Between Wordlists

A 25-word Monero wallet seed can be converted between wordlists with a simple program.

For example, if you have a seed in the old English wordlist that you'd like to convert to the newer English wordlist, this script will help you.

This program uses [monero-python](https://github.com/monero-ecosystem/monero-python) with a modification.

## Instructions

1. Clone the [GitHub repository](https://github.com/monero-ecosystem/monero-python) for monero-python.
2. Install the dependencies with `pip install -r requirements.txt`.
3. Open the code, and navigate into [monero/wordlists/\_\_init_\_\.py](./monero/wordlists/__init__.py), and add the following after line 2:
```python
from .english_old import EnglishOld
```
4. Copy the file [english_old.py](./english_old.py) to the [monero/wordlists](./monero/wordlists) directory.
5. Run [this program](./convert_seed.py). It will ask you for your seed, original wordset, then convert it.

As always, read the code between running it.
