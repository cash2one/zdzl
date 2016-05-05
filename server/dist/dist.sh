#!/bin/bash
script_dir=`dirname $0`
fab -f fabfile.py -u game -H $1 $2 $3 $4 $5 $6 $7 $8
