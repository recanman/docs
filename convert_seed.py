# made by recanman
# This is a script that converts a 25-word mnemonic seed from one wordset
# to another wordset.
from monero.seed import Seed
from monero.wordlists import wordlist

def convert_seed(seed, old_wordset, new_wordset):
    old_seed = Seed(seed, old_wordset)
    new_seed = Seed(old_seed.hex, new_wordset)
    return new_seed.phrase

def convert_seed_test():
    test_seed = "sighting pavements mocked dilute lunar king bygones niece tonic noises ostrich ecstatic hoax gawk bays wiring total emulate update bypass asked pager geometry haystack geometry"
    test_old_wordset = "English"
    test_new_wordset = "Spanish"

    test_new_seed = convert_seed(test_seed, test_old_wordset, test_new_wordset)
    if test_seed == convert_seed(test_new_seed, test_new_wordset, test_old_wordset):
        print("Test PASSED")
    else:
        print("Test FAILED")

    print("----------")

convert_seed_test()

print("Available wordlists:")
for wordlist in wordlist.list_wordlists():
    print("- " + wordlist)

seed = input("Enter your 25-word seed: ")
old_wordset = input("Enter the wordset of the seed: ")
new_wordset = input("Enter the wordset to convert to: ")

new_seed = convert_seed(seed, old_wordset, new_wordset)
print("Your new seed is:", new_seed)
