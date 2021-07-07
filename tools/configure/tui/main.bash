#!/usr/bin/bash
# shellcheck disable=2034

set -o errexit
set -o nounset
set -o pipefail

# Set dialog exit codes
declare -rix DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3
declare -rix DIALOG_ITEM_HELP=4 DIALOG_TIMEOUT=5 DIALOG_ESC=6 DIALOG_ERROR=7

declare -i dialogRet
declare dialogSel

function dialog
{
	shopt -s lastpipe
	exec 3>&1

	{
		command dialog --keep-tite \
		--backtitle "runit-user Project Configuration Program" "$@" \
		2>&1 1>&3 3>&- ;
		
		echo ",$?" 3>&-
	
	} | IFS="," read -r dialogSel dialogRet 3>&-

	exec 3>&-
}

function gotoScreen
{
	# shellcheck disable=2086
	# SC2086: Resplitting is necessary for this code to work correctly
	s_${dialogSel:-err NoSel} 2>/dev/null || s_err NoScreen
}

# Screens

function s_err
{
	dialog --title "ERROR" --msgbox "err$1" 0 0
}

function s_main
{
	while true ; do

		dialog --erase-on-exit --no-tags --menu "Main Menu" 0 0 0 \
			autocfg "Automatic Configuration" \
			wizcfg  "Configuration wizard"    \
			params  "Project parameters"      \
			devctn  "Devcontainer"

		[ $dialogRet -eq "$DIALOG_ESC"    ] && break
		[ $dialogRet -eq "$DIALOG_CANCEL" ] && break

		gotoScreen

	done
}

##
# Visualize and edit project parameters
function s_params
{
	dialog --inputmenu "Project parameters" 0 0 0 \
		"var1" "value" \
		"var2" "value"
}

# Run TUI

dialogSel=main
gotoScreen
