#!/bin/bash

# $1 - the path to xwiki.[cfg|properties]
# $2 - the setting/property to set
# $3 - the new value

sed -i s~"\#\? \?$2 \?=.*"~"$2=$3"~g "$1"