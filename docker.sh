#!/bin/bash
# Functie: 		gcloud installation and delete script to install rocket-chat server.
#
# Arguments: 	--help,--delete,-d
# Author:   	Jael Romero
# Copyright:	2020 GNU jaelromero@yapo.be
# Version:		1.0
# Requires:     Google SDK, Apache Benchmark, A valid gcloud project

#Configuratie
REGION=europe-west1
ZONE=europe-west1-b
DB_INSTANCE=wordpress-db-container
DB_NAME=wordpress
DB_USER=wordpress
INSTANCE_NAME=wordpress
IMAGE_PROJECT=ubuntu-os-cloud
IMAGE_FAMILY=ubuntu-1804-lts

if [[ $1 == "--help" ]]
then
	echo "To install the $INSTANCE_NAME server run the script without arguments"
	echo "To delete the $INSTANCE_NAME server use -d or --delete"
	exit 0
fi

# Verijderen 
if [[ $1 == "-d" || $1 == "--delete" ]] &>/dev/null
then
	# Check of er een instantie draait
	INSTANCE=$( gcloud compute instances list | cut -d ' ' -f1 | grep $INSTANCE_NAME ) &>/dev/null
	if [[ $INSTANCE != $INSTANCE_NAME ]] &>/dev/null
		then  echo "No existing $INSTANCE_NAME instances found.."
		exit 1 &>/dev/null
	fi

	echo "Deleting $INSTANCE_NAME"
	sleep 4
	echo "Pleas wait.."
	
	# De quiet flag is steeds nodig, want anders vraagt gcloud om bevestiging.
	# En als je dat dan naar dev/null stuurt, zie je dat niet en zit je vast!

	# Verwijder VM em SQL instanties
	echo "Removing SQL instance.. "
	gcloud sql instances delete $DB_INSTANCE --async --quiet >&2 
	echo "Removing VM instance.."
    gcloud compute instances delete $INSTANCE_NAME --quiet >&2 
    exit 0;
	
	
else

# Check of er reeds een VM of SQL instanties draait
	VM_INSTANCE=$( gcloud compute instances list | cut -d ' ' -f1 | grep $INSTANCE_NAME ) &>/dev/null
	if [[ $VM_INSTANCE == $INSTANCE_NAME ]]
		then  
		URL=$( gcloud compute instances list | rev |cut -d ' ' -f3 | rev )
		echo "VM instance $INSTANCE_NAME already exists.."
		echo "Its running on.."
		echo "$URL"
		exit 2
	fi

	INSTANCE_SQL=$( gcloud compute instances list | cut -d ' ' -f1 | grep $DB_INSTANCE ) &>/dev/null
    if [[ $INSTANCE_SQL == $DB_INSTANCE  ]]
	    then
		echo "SQL instance $DB_INSTANCE already exists.."
		exit 3
    fi


which gcloud >/dev/null || { echo "install package gcloud" >&2; exit 1; }
dpkg -s mysql-client &> /dev/null || { echo "install package mysql-client"; exit 1; }

read -s -p "DB root password: " rootpass
echo
read -s -p "Wordpress password: " wordpass
echo

#Aanmaken van SQL instantie 
gcloud sql instances create $DB_INSTANCE --region=$REGION --authorized-networks=0.0.0.0/0 # Dit geeft iedereen toegang
gcloud sql users set-password root --host=% --instance=$DB_INSTANCE --password=$rootpass

dbaddress=$(gcloud sql instances list | grep $DB_INSTANCE | tr -s " " | cut -f 5 -d " ")

mysql --host=$dbaddress --user=root --password=$rootpass <<!
# SQL statements
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER IDENTIFIED BY '$wordpass';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER;
FLUSH PRIVILEGES;
!

#Aanmaken  VM instantie + startup-script

gcloud compute instances create-with-container $INSTANCE_NAME --container-image=docker.io/wordpress:latest \
--zone=$ZONE --tags=http-server,https-server \
--container-env WORDPRESS_DB_NAME=$DD_NAME,WORSPRESS_DB_USER=$DB_USER,WORDPRESS_DB_PASSWORD=$wordpass,WORDPRESS_DB_HOST=$dbaddress

# Access SQL enkel aan host geven
ipaddress=$(gcloud compute instances list | grep $INSTANCE_NAME | tr -s " " | cut -d " " -f 5)
gcloud sql instances patch $DB_INSTANCE --authorized-networks=$ipaddress/32 --quiet
fi
