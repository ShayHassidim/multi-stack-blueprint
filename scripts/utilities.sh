#!/bin/bash

### utility functions ###

# check if the provided packe is already installed
function package_is_installed() {
	local INSTALLED=0
	for PACKAGE in `yum list installed | grep $1`; do
	        if [[ $PACKAGE == "$1"* ]]; then
			P=${PACKAGE%.*}
			if [ "$P" == "$1" ]; then
				INSTALLED=1
			fi
		fi
	done
	echo $INSTALLED
}
