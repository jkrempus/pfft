#!/bin/sh

dmd -c -o- -Dfpfft.pfft.html ../pfft/pfft.d candydoc/candy.ddoc candydoc/modules.ddoc additional-macros.ddoc
dmd -c -o- -Dfpfft.stdapi.html ../pfft/stdapi.d candydoc/candy.ddoc candydoc/modules.ddoc additional-macros.ddoc
