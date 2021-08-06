#!/usr/bin/bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

# libconf
# Build configuration management library

declare -r CONF_HOME_DIR="build/config"

declare -t defaultCfgFile="tools/configure/default.conf"

##
# The main project configuration file
# It is the main product of the configure script and stores configuration
# in a tool-agnostic way.
# It is the source file for all the latter configuration files.
declare -r mainCfgFile="${CONF_HOME_DIR}/main"
declare -r makeCfgFile="${CONF_HOME_DIR}/make"
declare -r sppCfgFile="${CONF_HOME_DIR}/spp"

##
# A list of the parameters configurable by this configure script
declare -a configurables

##
# The in-memory configuration store
# It is a key-value associative array where each key is a configurable from
# $configurables
declare -A configuration

declare -a makeParams sppParams

##
# Load the project configuration in memory
# if the configuration file doesn't exist, load the default config
function loadConf
{
	declare key value
	declare srcFile="$mainCfgFile"

	! [ -e "$srcFile" ] && srcFile="$defaultCfgFile"

	echo "Reading $srcFile"

	sed -ne '/^[^#]/p' "$srcFile" |\
	while IFS="=" read -r key value ; do
		configurables+=( "$key" )
		changeConf "$key" "$value"
	done
}

##
# Synthesize the project configuration files
function writeConf
{
	# Create CONF_HOME_DIR and make sure it's clean
	mkdir -p "${CONF_HOME_DIR}"
	rm -rf "${CONF_HOME_DIR:?}"/*

	# Serialize main configuration
	echo "Writing $mainCfgFile"
	for key in "${configurables[@]}" ; do
		echo "${key}=$( getConf "$key" )" >> $mainCfgFile
	done

	# Serialize make configuration
	echo "Writing $makeCfgFile"
	for key in "${makeParams[@]}" ; do
		echo "${key} = $( getConf "$key" )" >> $makeCfgFile
	done

	# Serialize spp configuration
	echo "Writing $sppCfgFile"
	for key in "${sppParams[@]}" ; do
		echo "${key} = $( getConf "$key" )" >> $sppCfgFile
	done
}

##
# Changes a configuration value
#
# @param $1 configuration key
# @param $2 new value
function changeConf
{
	configuration["$1"]="$2"
}

##
# Get the value associated to a configuration key
#
# @param $1 configuration key
function getConf
{
	if [ -z "${1:-}" ] ; then
		echo "ERROR: getConf needs \$1" >&2
		return 1
	fi

	echo "${configuration["$1"]}"
}
