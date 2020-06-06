#!/bin/bash
# Functie: 		gcloud installation and delete script to install rocket-chat server.
#
# Arguments: 	--help,--delete,-d
# Author:   	Jael Romero
# Copyright:	2020 GNU jaelromero@yapo.be
# Version:		1.1
# Requires: 	A valid gcloud project.


if [[ $1 == "--help" ]]
then
	echo "to install the rocket-chat server run the script without arguments"
	echo "to delete the rocket-chat server use -d or --delete"
	exit 0
fi


if [[ $1 == "-d" || $1 == "--delete" ]] &>/dev/null
then
	# Check of er een instantie draait
	INSTANCE=$( gcloud compute instances list | cut -d ' ' -f1 | grep rocket-chat ) &>/dev/null
	if [[ $INSTANCE != 'rocket-chat' ]] &>/dev/null
		then  echo "no existing rocket-chat instances found.."
		exit 1 &>/dev/null
	fi

	INSTANCE_NAME="rocket-chat"
	echo "deleting rocket-chat"
	sleep 4
	echo "pleas wait.."
	
	# De quiet flag is steeds nodig, want anders vraagt gcloud om bevestiging.
	# En als je dat dan naar dev/null stuurt, zie je dat niet en zit je vast!

	# Verwijder insantie rocket-chat
	echo "removing instance.. "
	gcloud compute instances delete $INSTANCE_NAME --zone=europe-west1-b --quiet >&2 
	echo "removing firewallrule"
	# Verwijder firewallrule http3000
	gcloud compute firewall-rules delete http3000 --quiet 2>/dev/null
	echo "rocket-chat sucessfull deleted"
else

# Check of er reeds een instantie draait
INSTANCE=$( gcloud compute instances list | cut -d ' ' -f1 | grep rocket-chat )
	if [[ $INSTANCE == 'rocket-chat' ]]
		then  
		URL=$( gcloud compute instances list | rev |cut -d ' ' -f3 | rev )
		echo "rocket-chat already exists.."
		echo "running on.."
		echo "$URL/3000"
		exit 2
	fi

echo "installing rocket-chat.."
sleep 4
echo "pleas wait.." 

#Configuratie
INSTANCE_NAME="rocket-chat"
ZONE="europe-west1-b"
TYPE="n1-standard-1"
IMAGE="ubuntu-os-cloud"
FAMILY="ubuntu-1804-lts"
TAGS="chat"



#Aanmaken instantie + startup-script
echo "creating instance.."
gcloud compute instances create $INSTANCE_NAME \
--machine-type=$TYPE \
--image-project=$IMAGE \
--image-family=$FAMILY \
--zone=$ZONE \
--tags=$TAGS \
--metadata=startup-script="
#!bin/bash
snap install rocketchat-server
" 

#Aanmaken firewall rule http3000
echo "creating firewallrule.."
gcloud compute firewall-rules create http3000 --allow=tcp:3000 --target-tags=$TAGS
ipadress=$(gcloud compute instances list  | tr -s " " | cut -d " " -f5 | tail -n +2 )


	if [[ $? -eq 0 ]]
		then
			echo "rocket-chat sucessfull installed"
			echo "running on"
			URL=$( gcloud compute instances list | rev |cut -d ' ' -f3 | rev )
			echo "$URL/3000"
			exit 0
			

		else	
			echo "Rocket-chat installation failed"
			exit 3
	fi
fi
