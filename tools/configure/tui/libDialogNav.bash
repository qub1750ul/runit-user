#!/usr/bin/bash

# Set dialog return codes
declare -rix \
	DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 \
	DIALOG_TIMEOUT=5 DIALOG_ESC=6 DIALOG_ERROR=7

declare -i dialogRet=0  # Return code of the last dialog invocation
declare dialogSel=""    # Selection code of the last dialog invocation
declare renderErrId=""  # Error id used by s_err
declare renderErrMsg="" # Error message used by s_err

declare dialogBacktitle="RUnit-user Build Configuration Program"

##
# Invoke dialog, parse the output and set the appropriate status variables
function dialog
{
	set +o errexit
	set -o pipefail
	shopt -s lastpipe

	exec 3>&1

	{
		command dialog --keep-tite --backtitle "$dialogBacktitle" "$@" \
			2>&1 1>&3 3>&- ;
		
		echo ",$?" 3>&-
	
	} | IFS="," read -r dialogSel dialogRet 3>&-

	exec 3>&-
}

##
# Set the renderer thread in error mode
# Expects to be called within a rendering thread
#
# @param $1 error id
# @param $@ extended error message
function setErr
{
	targetScreen=err
	renderErrId="$1"
	shift
	renderErrMsg="$*"
}

##
# Start a rendering thread for the specified screen
#
# @param $1 screen to render, if not provided copies $dialogSel
# @param $2 dialog action code, if not provided copies $dialogRet
#
# shellcheck disable=2120
# SC2120: The function assumes default arguments
function renderSubScreen
{
	declare targetScreen="${1:-$dialogSel}"
	declare -i actionCode="${2:-$dialogRet}"

	# Start rendering loop
	while true ; do

		# Test for exit conditions
		case "$targetScreen" in
			"caller") break ;;
		esac

		case "$actionCode" in
			"$DIALOG_ESC" ) targetScreen="exit" ;;
		esac

		# Check for invalid $targetScreen values
		# and show the appropriate error screen if appropriate
		if [ -z "${targetScreen:-}" ] ; then

			setErr NoScreenSelected
		
		elif ! command -v "s_${targetScreen}" > /dev/null ; then

			setErr NoSuchScreen \
				"Detected invalid target screen.\n" \
				"Extended info:\n"                  \
				"targetScreen = ${targetScreen}\n"  \
				"actionCode = ${actionCode}\n"

		fi

		# Render the selected screen
		"s_${targetScreen}"

	done
}