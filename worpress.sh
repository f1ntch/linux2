#!/bin/bash
# Functie:      gcloud installation and delete script to install Wordpress
#
# Arguments:    --delete,-d
# Author:       Jael Romero
# Copyright:    2020 GNU jaelromero@yapo.be
# Version:      1.0
# Requires:     Google SDK, Apache Benchmark, Curl, A valid gcloud project


#Configuratie

#VM
DB_INSTANCE=wordpresdb-test-1
DB_NAME=wordpress
DB_USER=wordpress

#SQL
INSTANCE_NAME=wordpress
REGION=europe-west1
ZONE=europe-west1-b
IMAGE="ubuntu-os-cloud"
FAMILY="ubuntu-1804-lts"
TAGS="http-server,https-server"

#ERRORS
ERROR_SQL="Installeer SQL client !"
ERROR_GC="Installeer de google cloud SDK !"

#DELETE
if [[ $1 == "-d" || $1 == "--delete" ]] &>/dev/null
then
    echo "deleting wordpress"
    sleep 4
    echo "pleas wait.."
    echo
    gcloud sql instances delete $DB_INSTANCE --async --quiet >&2 
    gcloud compute instances delete $INSTANCE_NAME --quiet >&2 
    exit 0;
fi


which gcloud >/dev/null || { echo "install package gcloud" >&2; exit 1; }
dpkg -s mysql-client &> /dev/null || { echo "install package mysql-client"; exit 1; }

which ab    
which curl  
read -s -p "Choose a strong password for the user : " rootpass
echo 
read -s -p "Choose a strong password for the Worpress admin user: " wordpresspass
echo

#Aanmaken van SQL instantie 
gcloud sql instances create $DB_INSTANCE --region=$REGION --authorized-networks=0.0.0.0/0
gcloud sql users set-password root --host=% --instance $DB_INSTANCE --password=$rootpass

dbaddress=$(gcloud sql instances list | grep $DB_INSTANCE | tr -s " " | cut -f 5 -d " ")

mysql --host $dbaddress --user=root --password=$rootpass <<! 
    # SQL statements
    CREATE DATABASE $DB_NAME; # Maak db aan met var
    CREATE USER $DB_USER IDENTIFIED BY '$wordpresspass'; #maak gebruiker aan met var
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER; # full admin rechten
    FLUSH PRIVILEGES;
!


#Aanmaken  VM instantie + startup-script
echo "creating instance.."
gcloud compute instances create $INSTANCE_NAME \
--machine-type=$TYPE \
--image-project=$IMAGE \
--image-family=$FAMILY \
--zone=$ZONE \
--tags=$TAGS \
--metadata=startup-script="
#!/bin/bash
        apt-get update
        apt-get install -y apache2 mysql-client php7.0-mysql php7.0 libapache2-mod-php7.0 php7.0-mcrypt php7.0-gd
        cd /var/www
        wget http://wordpress.org/latest.tar.gz
        rm -r /var/www/html
        tar xfz latest.tar.gz
        rm latest.tar.gz
        mv wordpress html
        cp html/wp-config-sample.php html/wp-config.php
        sed -i s/database_name_here/$DB_NAME/g html/wp-config.php
        sed -i s/username_here/$DB_USER/g html/wp-config.php
        sed -i s/password_here/$wordpresspass/g html/wp-config.php
        sed -i s/localhost/$dbaddress/g html/wp-config.php
        sudo service apache2 restart
    "


# Access SQL enkel aan host geven
ipadress=$(gcloud compute instances list | grep $INSTANCE_NAME | tr -s " " | cut -d " " -f 5
gcloud compute instances list | grep $INSTANCE_NAME | tr -s " " | cut -d " " -f 5)
gcloud sql instances patch $DB_INSTANCE --authorized-networks=$ipadress --quiet
