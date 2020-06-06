#BEST PRACTICES

if [[ $1 == "-d" || $1 == "--delete" ]]
then
	INSTANCE_NAME="rocket-chat"

	echo "deleting Rocket-chat"
	sleep 4
	echo "Pleas wait.."

	# De quiet flag is steeds nodig, want anders vraagt gcloud om bevestiging.
	# En als je dat dan naar dev/null stuurt, zie je dat niet en zit je vast!

	# Verwijder insantie rocket-chat
	gcloud compute instances delete $INSTANCE_NAME --zone=europe-west1-b --quiet >&2 
	echo "deleting firewall-rules.. "
	sleep 4
	echo "pleas wait.." 
	# Verwijder firewall rule http3000
	gcloud compute firewall-rules delete http3000 --quiet 2>/dev/null
	echo "rocket-chat sucessfull deleted"
else

echo "installing Rocket-chat.."
sleep 4
echo "Pleas wait.." 

#Configuratie
INSTANCE_NAME="rocket-chat"
ZONE="europe-west1-b"
TYPE="n1-standard-1"
IMAGE="ubuntu-os-cloud"
FAMILY="ubuntu-1804-lts"
TAGS="chat"
ROCKETCHATURL=http://$ipadress:3000

#Aanmaken instantie + startup-script
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
gcloud compute firewall-rules create http3000 --allow=tcp:3000 --target-tags=$TAGS
ipadress=$(gcloud compute instances list  | tr -s " " | cut -d " " -f5 | tail -n +2 )


	if [[ $? -eq 0 ]]
		then
			echo "Rocket-chat sucessfull installed"
			exit 1
			firefox $ROCKETCHATURL

		else	
			echo "Rocket-chat installation failed"
			exit 0
	fi
fi