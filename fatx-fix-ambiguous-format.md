Attempting to compile [fatx](https://sourceforge.net/projects/fatx/) [may fail](https://sourceforge.net/p/fatx/tickets/11/).

To fix:

In `src/fatx.cpp` and `src/fatx.hpp`, replace all instances of `(format` with `(boost::format` (include the parenthesis). From there, run `make` and it should work.
