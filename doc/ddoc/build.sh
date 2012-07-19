#!/bin/sh

dmd -c -o- -Df../pfft.pfft.html ../../pfft/pfft.d candy.ddoc modules.ddoc additional-macros.ddoc
dmd -c -o- -Df../pfft.stdapi.html ../../pfft/stdapi.d candy.ddoc modules.ddoc additional-macros.ddoc
dmd -c -o- -Df../pfft.clib.html clib.d candy.ddoc modules.ddoc additional-macros.ddoc
