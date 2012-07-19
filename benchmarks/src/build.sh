#!/bin/sh 
printf "`cat layout.html`" "`markdown index.md`" > ../index.html
