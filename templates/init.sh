#!/usr/bin/env false

debug "Balling templates"

if [ $FTT_FULL_LIST -eq 0 ]; then
	templates=($(for t in $(\ls -1 --hide='*.sh'); do if [ -f $t/.common-template ]; then echo $t; fi; done))
else
	templates=($(\ls -1 --hide='*.sh'))
fi

list_input "Which template would you like to use?" templates resp

if [ ! -d $resp ]; then
	echo "Invalid template"
	exit 1
fi

TEMPLATE_NAME=$resp
cd $resp
source init.sh
