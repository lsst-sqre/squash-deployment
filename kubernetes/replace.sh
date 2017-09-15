#!/bin/bash

usage(){
	echo "Usage: $0 <configuration template> <configuration>"
	exit 1
}

if [ "$1" == "" ] || [ "$2" == "" ]; then
    usage
fi

sed -e "
s/{{ NAMESPACE }}/${NAMESPACE}/
" $1 > $2
