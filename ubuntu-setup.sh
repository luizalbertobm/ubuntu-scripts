#!/bin/bash
#===================================================================================

function failure()
{
	printf "\n$@\n"
	exit 2
}

function aptinstall {
    echo ===========================================
    echo installing $1
    shift
    sudo apt-get -y -f -qq install "$@"
}

function snapinstall {
    echo ===========================================
    echo installing $1
    shift
    sudo snap install "$@"
}
APTGETCMD=`echo "sudo apt-get $QUIET_OPT $SIM_OPT"`

#Find which dialog tool is available
function find_dialog()
{
	if [ ! -z "$DISPLAY" ] ; then
		DIALOG=`which kdialog`

		if [ ! -z "$DIALOG" ]; then
			DIALOG_TYPE=kdialog
		else
			DIALOG=`which Xdialog`

			if [ ! -z "$DIALOG" ]; then
				DIALOG_TYPE=dialog
			fi
		fi

		if [ -z "$DIALOG" ]; then
			DIALOG=`which zenity`

			if [ ! -z "$DIALOG" ]; then
				DIALOG_TYPE=zenity
			fi
		fi
	fi

	if [ -z "$DIALOG" ]; then
		DIALOG=`which dialog`

		if [ ! -z "$DIALOG" ]; then
			DIALOG_TYPE=dialog
		fi
	fi

	if [ -z "$DIALOG" ]; then
		failure "You need kdialog, xenity or dialog application to run this script,\nplease install it using 'apt-get install packagename' where packagename is\n'kdebase-bin' for kdialog, 'xdialog' for dialog, 'dialog' for dialog.\nIf you are using text-mode, you need to install dialog."
	fi
}


function dialog_menu()
{
	DESCRIPTION="$1"
	shift

	declare -a PARAMS

	if [ "$DIALOG_TYPE" = "zenity" ]; then
		declare -i i=0
		for v; do
			PARAMS[$i]="$v"
			i+=1
		done
		$DIALOG --list --text "$DESCRIPTION" --column "" "${PARAMS[@]}" --width=500 --height=400
	else
		if [ "$DIALOG_TYPE" = "kdialog" ] ; then
			declare -i i=0
			for v; do
				PARAMS[$i]="$v"
				i+=1
				PARAMS[$i]="$v" #yes, 2 times as kdialog requires key and value
				i+=1
			done
			$DIALOG --menu "$DESCRIPTION" "${PARAMS[@]}"
		else
			declare -i i=0
			for v; do
				PARAMS[$i]="$v"
				i+=1
				PARAMS[$i]="Language"
				i+=1
			done
			$DIALOG --stdout --menu "$DESCRIPTION" 20 30 10 "${PARAMS[@]}"
		fi
	fi
}

function dialog_multi_choice()
{
	DESCRIPTION="$1"
	shift

	if [ "$DIALOG_TYPE" = "zenity" ]; then
		for i; do
			PARAMS="$PARAMS $i $i"
		done
		$DIALOG --separator $'\n' --list --checklist --multiple --text "$DESCRIPTION" --column "" --column ""  $PARAMS --width=500 --height=400
	else
		if [ "$DIALOG_TYPE" = "kdialog" ] ; then
			for i; do
				PARAMS="$PARAMS $i $i 0"
			done
			$DIALOG --separate-output --checklist "$DESCRIPTION" $PARAMS
		else
			for i; do
				PARAMS="$PARAMS $i Language 0"
			done
			$DIALOG --stdout --separate-output --checklist "$DESCRIPTION" 20 30 10 $PARAMS
		fi
	fi

	RESULT=$?
	return $RESULT
}

function dialog_line_input()
{
	DESCRIPTION="$1"
	INITIAL_VALUE="$2"

	if [ "$DIALOG_TYPE" = "zenity" ] ; then
		$DIALOG --entry --text "$DESCRIPTION" --entry-text "$INITIAL_VALUE"
	else
		if [ "$DIALOG_TYPE" = "kdialog" ] ; then
			$DIALOG --inputbox "$DESCRIPTION" "$INITIAL_VALUE"
		else
			$DIALOG --stdout --inputbox "$DESCRIPTION" 20 30 "$INITIAL_VALUE"
		fi
	fi

	RESULT=$?
	return $RESULT
}

function dialog_choose_file()
{
	TITLE="$1"

	if [ "$DIALOG_TYPE" = "zenity" ] ; then
		$DIALOG --title "$TITLE" --file-selection "`pwd`/"
	else
		if [ "$DIALOG_TYPE" = "kdialog" ] ; then
			$DIALOG --title "$TITLE" --getopenfilename "`pwd`/"
		else
			$DIALOG --stdout --title "$TITLE" --fselect "`pwd`/" 20 80
		fi
	fi
}

function dialog_msgbox()
{
	TITLE="$1"
	TEXT="$2"

	if [ "$DIALOG_TYPE" = "zenity" ]; then
		echo -n "$TEXT" | $DIALOG --title "$TITLE" --text-info --width=500 --height=400
	else
		$DIALOG --title "$TITLE" --msgbox "$TEXT" 20 80
	fi
	return $?
}

function dialog_question()
{
	TITLE="$1"
	TEXT="$2"

	if [ "$DIALOG_TYPE" = "zenity" ]; then
		$DIALOG --title "$TITLE" --question --text "$TEXT"
	else
		$DIALOG --title "$TITLE" --yesno "$TEXT" 20 80
	fi
	THEMES=$?
	return $THEMES
}


function show_welcome_msg
{
	dialog_msgbox Instalador "Este script foi criado para configurar o ambiente de desenvolvimento para utilizadores de Ubuntu e seus derivados (Kunbuntu, Xunbuntu, etc). Nos próximos passos você deverá escolher quais ferramentas deseja instalar. Você deseja prosseguir?".
	NEXT=$?
	return $NEXT
}

#***********************************************************************************
#	GET SECURITY UPDATES
#***********************************************************************************
function update_packages()
{
	sudo apt-get update
	sudo apt-get upgrade
}

#***********************************************************************************
#	ESSENTIAL (NON-DEVELOPPER) TOOLS
#***********************************************************************************
function install_mandatories()
{
	aptinstall Synaptic synaptic		#User-friendly package manager 
	aptinstall SNAP snap
	aptinstall WGET wget
	aptinstall SSH ssh
	aptinstall CURL curl
	aptinstall SAMBA samba 
	aptinstall "SAMBA FILE SYSTEM" smbfs
}

#***********************************************************************************
#	CREATE TEMPORARY FOLDER
#***********************************************************************************
function clean_temp_files()
{
	if [ -a ~/post_install_tmp ]; then
	    echo "Removendo arquivos temporários..."
	    rm -rf ~/post_install_tmp
	fi
}

#***********************************************************************************
#	DEV TOOLS
#***********************************************************************************
function install_dev_tools()
{
	for i in $DEV_TOOLS; do
		case $i in
		"composer")
			aptinstall COMPOSER composer
			composer -v;;
		"npm")
			aptinstall NPM npm
			npm -v;;
		"nvm")
			aptinstall NVM nvm
			nvm -v;;
		"git")
			aptinstall GIT git && git -v;;
		"node")
			curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
			aptinstall NODE nodejs && nodejs -v;;
		"vs-code")
			echo '==========================================='
    		echo 'installing VS-CODE'
			sudo snap install code --classic;; # or code-insiders
		"flutter")
			echo '==========================================='
    		echo 'installing FLUTTER'
			sudo snap install flutter --classic;;
		"android-studio")
			sudo snap install android-studio --classic
			sudo apt-get install android-tools-adb android-tools-fastboot;;
		"docker")
		 	echo '==========================================='
    		echo 'installing DOCKER'
			sudo apt-get remove docker docker-engine docker.io containerd runc; 
			sudo curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh;;
		esac
	done
}

#***********************************************************************************
#	OTHER SOFTWARES
#***********************************************************************************
function install_softwares()
{
	for i in $SOFTWARES; do
		case $i in
		"chrome")
			wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install ./google-chrome-stable_current_amd64.deb;;
		"gimp")
			aptinstall GIMP gimp;;
		"office-writer")
			aptinstall OFFICE libre-office-writer;;
		"office-calc")
			aptinstall OFFICE libre-office-calc;;
		"postman")
			snapinstall POSTMAN postman;;
		esac
	done
}

#***********************************************************************************
#	VS CODE EXTENSIONS
#***********************************************************************************
function install_vs_code_extensions()
{
	for i in $VSCODE_EXTENSIONS; do
		case $i in
		"pt-br")
			code --install-extension ms-ceintl.vscode-language-pack-pt-br
			code --enable-proposed-api ms-ceintl.vscode-language-pack-pt-br;;
		"html-css")
			code --install-extension ecmel.vscode-html-css;;
		"dart")
			code --install-extension dart-code.dart-code;;
		"flutter")
			code --install-extension dart-code.flutter;;
		"docker")
			code --install-extension ms-azuretools.vscode-docker;;
		"php-intelephense")
			code --install-extension bmewburn.vscode-intelephense-client;;
		"php-debug")
			code --install-extension felixfbecker.php-debug;;
		"material-icon-theme")
			code --install-extension pkief.material-icon-theme;;
		"vue")
			code --install-extension jcbuisson.vue
			code --install-extension hollowtree.vue-snippets;;
		esac
	done
}

#***********************************************************************************
#*** Initialization ***
#***********************************************************************************

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
clean_temp_files
mkdir ~/post_install_tmp
cd ~/post_install_tmp

#Set Dialog tool
DIALOG=
DIALOG_TYPE=
find_dialog

#dialog_question "Instalação?" "Tem certeza disto?"
#dialog_multi_choice "Quais voce quer instalar?" b2 c3
#dialog_line_input param1 param2 
#dialog_msgbox param1 param2
#dialog_menu param1 param2 param3

show_welcome_msg
if [ $NEXT -eq 1 ]; then
    exit 0
fi

DEV_TOOLS=`dialog_multi_choice "Selecione as ferramentas que pretende instalar." vs-code android-studio flutter docker git node composer npm nvm`
SOFTWARES=`dialog_multi_choice "Please choose the source control manager you want to install." chrome gimp postman office-writer office-calc`
VSCODE_EXTENSIONS=`dialog_multi_choice "Escolha as extensões do vs-code para instalar." pt-br html-css dart flutter docker php-intelephense php-debug vue`
THEMES=`dialog_question "Deseja instalar extensões e temas?" "Será configurado temas para o shell do gnome e a instalaçao de algumas extensões."`

#Proceed with mandatory installation procedures
update_packages
install_mandatories
install_dev_tools
install_softwares
install_vs_code_extensions
#install_themes

sudo apt-get autoremove
clean_temp_files

echo '==========================================='
echo 'INSTALAÇÃO FINALIZADA'

