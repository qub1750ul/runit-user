#!/usr/bin/bash
# shellcheck disable=2034

# configure --mode=tui
# Set configure parameters interactively using graphical selectors

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

source tools/configure/libconf.bash
source tools/configure/tui/libDialogNav.bash

#-----------------------------#
# Screen Management functions #
#-----------------------------#

# Each `s_name` function implements the logic for the screen named `name`
# Each `name` is a vaild value for `targetScreen`

# Main screen
function s_main
{
		dialog --no-tags --title "Main Menu"   \
			--ok-label "Enter" --cancel-label "Return" \
			--menu  "" 0 0 0         \
			save    "Save current configuration" \
			autocfg "Automatic Configuration" \
			wizcfg  "Configuration wizard"    \
			devctn  "Devcontainer"            \
			allvar  "All parameters"          \
			reload  "Reload old configuration"

		case "$dialogRet" in
			"$DIALOG_OK"    ) renderSubScreen     ;;
			"$DIALOG_CANCEL") targetScreen="exit" ;;
		esac
}

function s_save
{
	dialog --title "Save" --yesno "Save current configuration ?" 0 0

	! [ "$dialogRet" -eq "$DIALOG_OK" ] || writeConf

	targetScreen="caller"
}

function s_exit
{
	dialog --erase-on-exit --title "EXIT"        \
		--yes-label "Save" --no-label "Discard"    \
		--yesno "Save current configuration ?" 0 0

	! [ "$dialogRet" -eq "$DIALOG_OK" ] || writeConf

	exit 0
}

# Error screen
function s_err
{
	dialog --title "ERROR" --msgbox "err${renderErrId:-}\n${renderErrMsg:-}" 0 0

	# Reset error info
	declare -g renderErrId="" renderErrMsg=""

	# Return to the invoking screen
	targetScreen="caller"
}

function s_autocfg
{
	dialog --title "Automatic Configuration" \
		--msgbox "Running ./configure --mode=default" 0 0

	./configure --mode=default

	targetScreen="caller"
}

##
# Visualize and edit project parameters
function s_allvar
{
	declare -ra menutxt=(
		"WARNING: do not remove enclosing hypens"
	)

	declare -a forms=()

	for key in "${configurables[@]}" ; do
		forms+=( "'${key}'" "'$( getConf "$key" )'" )
	done

	dialog --title "All parameters" \
		--extra-label "Edit" --cancel-label "Return" \
		--inputmenu "${menutxt[*]}" 0 0 0 \
		"${forms[@]}"

	# Manage dialog actions
	case "$dialogRet" in
		"$DIALOG_OK") return ;;
		"$DIALOG_CANCEL") targetScreen="caller" ; return ;;
	esac

	# Parse edit
	# 'op' and 'space' are placeholders used to discard unwanted data
	declare op key space val
	IFS="'" read -r op key space val <<< "$dialogSel"

	changeConf "$key" "$val"
}

function s_reload
{
	if loadConf ; then
	
		dialog --title "INFO" --msgbox "Configuration reloaded from disk" 0 0
		targetScreen="caller"

	else

		setErr loadConf

	fi
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

renderSubScreen
