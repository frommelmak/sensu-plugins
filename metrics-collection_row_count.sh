#!/bin/bash
#
# A wrapper arround the check_mondodb.py check plugin to get row count metric from a given collection
#
# author: frommelmak@gmail.com
#
# Graphite output format:
#
# hostname.collection.row_count value timestamp
#

hostname=$(hostname)
if [ "$#" -ne 3 ]; then
    echo "USAGE: $0 mongo_host database collection"
    exit 1
fi
mongo_host=$1
database=$2
collection=$3
timestamp=$(date +%s)

value=$(/etc/sensu/plugins/check_mongodb.py -A row_count -d $database -c $collection -H $mongo_host -P 27017 | cut -d':' -f 2 |sed 's/^ *//g')
echo "$hostname.$database.$collection.row_count $value $timestamp"
