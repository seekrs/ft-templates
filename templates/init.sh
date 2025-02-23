#!/usr/bin/env false

if [ $FTT_SHOW_ALL -eq 0 ]; then
	templates=($(for t in $(\ls -1 --hide='*.sh'); do if [ -f $t/.common-template ]; then echo $t; fi; done))
else
	templates=($(\ls -1 --hide='*.sh'))
fi

list_input "Which template would you like to use?" templates resp

if [ ! -d $resp ]; then
	echo "Invalid template"
	leave 1
fi

TEMPLATE_NAME=$resp
debug "TEMPLATE_NAME=$TEMPLATE_NAME"
cd $TEMPLATE_NAME
source ./init.sh
