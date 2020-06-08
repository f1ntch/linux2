#!/bin/bash
# Functie: 		gcloud installation and delete script for instance template.
#
# Arguments: 	--delete,-d
# Author:   	Jael Romero
# Copyright:	2020 GNU jaelromero@yapo.be
# Version:		1.1
# Requires: 	A valid gcloud project.

#Configuratie
INSTANCE_TEMP="instance-template-test"
ZONE="europe-west1-b"
TYPE="f1-micro"
IMAGE="ubuntu-1604-xenial-v20200429" 
TAGS="http-server,https-server"
IMAGEPROJECT="ubuntu-os-cloud"


if [[ $# -eq 0 ]]
then
	echo "Installing $INSTANCE_TEMP"
	sleep 4
	echo "Please wait.."
	gcloud compute instance-templates create $INSTANCE_TEMP\
	--machine-type=$TYPE \
	--image-project=$IMAGEPROJECT --image=$IMAGE\
	--tags=$TAGS --description="testing creation template" \
	--metadata startup-script="
		#!/bin/bash
        apt-get update
        apt-get install -y apache2 
	" 
	gcloud compute instance-groups managed create $INSTANCE_TEMP"-gr" --zone="europe-west1-b" --template=$INSTANCE_TEMP --size=3 --quiet >&2
	exit 0 

fi


if [[ $1 == "-d" || $1 == "--delete" ]] &>/dev/null
then
	echo "Deleting $INSTANCE_TEMP"
	sleep 4
	echo "Please wait.."
	gcloud compute instance-templates delete $INSTANCE_TEMP --quiet >&2 
	echo "Template sucessfull deleted"
	exit 0
fi


if [[ -z "$2" || -n "${2//[0-9]}" ]]
then
	echo "Geef een getal in"
	exit 1
else
	gcloud compute instance-groups managed resize $INSTANCE_TEMP"-gr" --size=$2 --quiet >&2 
	exit 0

fi
