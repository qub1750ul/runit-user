#!/usr/bin/bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

declare -r home=tools/configure

# shellcheck source=tools/configure/libconf.bash
source $home/libconf.bash

# Detect mode
grep -Eoe '--mode=[a-Z]+' <<< "$*" | cut -d= -f2 | read -r mode || true

case "$mode" in

	"tui")
		exec $home/tui/main.bash "$#"
		;;

	"cli")
		exec $home/cli/main.bash "$@"
		;;

	""|"default")
		rm -f "$mainCfgFile"
		exec $home/cli/main.bash "$@"
		;;

	*)
		echo "ERROR: Unsupported configure mode"
		exit 1
		;;

esac