#!/bin/bash

for i in {4..22} 
do 
	echo -en "$i\t"; ./$1 $i
done
