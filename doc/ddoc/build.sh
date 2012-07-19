#!/bin/sh

dmd -c -o- -Df../pfft.pfft.html ../../pfft/pfft.d ../candydoc/candy.ddoc modules.ddoc additional-macros.ddoc
dmd -c -o- -Df../pfft.stdapi.html ../../pfft/stdapi.d ../candydoc/candy.ddoc modules.ddoc additional-macros.ddoc
dmd -c -o- -Df../pfft.clib.html clib.d ../candydoc/candy.ddoc modules.ddoc additional-macros.ddoc
