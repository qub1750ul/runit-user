#!/usr/bin/bash
# shellcheck disable=2034

# configure --mode=tui
# Set configure parameters interactively using graphical selectors

set -o errexit
set -o nounset
set -o pipefail

#------------------------------------------#
# Script configuration and basic utilities #
#------------------------------------------#

source tools/configure/libconf.bash

# Set dialog return codes
declare -rix \
	DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 \
	DIALOG_TIMEOUT=5 DIALOG_ESC=6 DIALOG_ERROR=7

declare -i dialogRet=0 # Return code of the last dialog invocation
declare dialogSel=""   # Selection code of the last dialog invocation
declare errid=""       # Error id used by s_err
declare errmsg=""      # Error message used by s_err

declare dialogBacktitle="RUnit-user Build Configuration Program"

##
# Invoke dialog, parse the output and set the appropriate status variables
function dialog
{
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
# Activate a screen of the TUI
# The screen to activate depends on the `dialogSel` variable
function gotoScreen
{
	case "$dialogRet" in
		"$DIALOG_ESC" ) dialogSel="exit" ;;
	esac

	if ! "s_${dialogSel:-err}" 2> /dev/null ; then
		dialogSel=err ; errid=NoScreen
		s_err
	fi
}

#-----------------------------#
# Screen Management functions #
#-----------------------------#

# Each `s_name` function implements the logic for the screen named `name`
# Each `name` is a vaild value for `dialogSel`

function s_exit
{
	dialog --erase-on-exit --title "EXIT"        \
		--yes-label "Save" --no-label "Discard"    \
		--yesno "Save current configuration ?" 0 0

	! [ "$dialogRet" -eq "$DIALOG_OK" ] || writeConf

	# Signal the main loop to terminate the program
	dialogSel="term"
}

# Error screen
function s_err
{
	: ${errid:=NoSel}

	dialog --title "ERROR" --msgbox "err${errid}\n${errmsg}" 0 0

	# Reset error info
	errid="NoSel"
	errmsg=""

	# Return to main menu
	dialogSel="main"
}

# Main screen
function s_main
{
		dialog --no-tags \
			--ok-label "Enter" --cancel-label "Return" \
			--menu "Main Menu" 0 0 0          \
			autocfg "Automatic Configuration" \
			wizcfg  "Configuration wizard"    \
			params  "Project parameters"      \
			devctn  "Devcontainer"            \
			

		! [ "$dialogRet" -eq "$DIALOG_CANCEL" ] || dialogSel="exit"

		gotoScreen
}

##
# Visualize and edit project parameters
function s_params
{
	declare -a forms

	for key in "${configurables[@]}" ; do
		forms+=( "$key" "$( getConf "$key" )" )
	done

	dialog \
		--cancel-label "Return" \
		--inputmenu "Project parameters" 0 0 0 \
		"${forms[@]}"

	dialogSel="main"
}

#--------------------#
# Script entry point #
#--------------------#

if loadConf ; then
	dialogSel="main"
else
	dialogSel="err"
	errid="LoadConf"
fi

while [ "$dialogSel" != "term" ] ; do
	gotoScreen
done