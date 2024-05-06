#! /bin/bash

## configurable vars
USER=`whoami`
SERVER_NAME=webserver
SERVER_PATH=~/Docker/webserver/
SERVER_ROOT=~/Docker/webserver/apache/webserver-root/
HOSTS=/etc/hosts
DB_HOST=mysql
DB_USER=dbuser
DB_PASS=dbpass
ADMIN_USR=robot
ADMIN_MAIL=mr.robot@localhost.local
ADMIN_PASS=login

## static vars
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# store all directories in $SERVER_ROOT
# pass output from ls to sed and delete path to webroot from strings, then put it on one line with tr
# ls outputs an error if the directory is empty => ignore it
EXISTING_PROJECTS=`ls -d $SERVER_ROOT* | sed "s|^\$SERVER_ROOT||g" | tr "/" " "`

## get PROJECT_NAME
echo -n -e "${GREEN}Project Name: ${NC}"
read PROJECT_NAME

while [ -z $PROJECT_NAME ] ; do
	echo -n -e "${RED}Project Name cannot be empty! Try again…\n\n${NC}"
	echo -n -e "${GREEN}Project Name: ${NC}"
	read PROJECT_NAME
done

# check if directory already exist
while [ -d "${SERVER_ROOT}/${PROJECT_NAME}" ] ; do
	echo -n -e "${RED}A project with this name already exist!\n\n${NC}"
	echo -n -e "Existing projects are:\n"
	echo -n -e "${YELLOW}""$EXISTING_PROJECTS""${NC}\n\n"

	echo -n -e "${GREEN}Choose another project name: ${NC}"
	read PROJECT_NAME
done

PROJECT_DIR="${SERVER_ROOT}/${PROJECT_NAME}"

## get DOMAIN_EXTENSION
echo -n -e "${GREEN}Domain Extension (without dot): ${NC}"
read DOMAIN_EXTENSION

while [ -z $DOMAIN_EXTENSION ] ; do
	echo -n -e "${RED}Domain Extension cannot be empty! Try again…\n\n${NC}"
	echo -n -e "${GREEN}Domain Extension: ${NC}"
	read DOMAIN_EXTENSION
done

PROJECT_URL="${PROJECT_NAME}.${DOMAIN_EXTENSION}"

# create project folder in server root
mkdir $PROJECT_DIR
echo -e "Create project directory $PROJECT_NAME ${GREEN}success${NC}"
mkdir $PROJECT_DIR/dev
echo -e "Create /dev directory ${GREEN}success${NC}"
mkdir $PROJECT_DIR/ssl
echo -e "Create /ssl directory ${GREEN}success${NC}"
mkdir $PROJECT_DIR/log
echo -e "Create /log directory ${GREEN}success${NC}"

touch $PROJECT_DIR/vhost.conf
tee -a $PROJECT_DIR/vhost.conf > /dev/null <<EOT
<VirtualHost *:80>
    DocumentRoot "/var/www/$PROJECT_NAME/dev"
    ServerName $PROJECT_URL
    CustomLog /var/www/$PROJECT_NAME/log/apache-access.log common
    ErrorLog /var/www/$PROJECT_NAME/log/apache-error.log
    <Directory "/var/www/$PROJECT_NAME/dev">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
<VirtualHost *:443>
    ServerName $PROJECT_URL
    DocumentRoot "/var/www/$PROJECT_NAME/dev"
    SSLEngine on
    SSLCertificateFile /var/www/$PROJECT_NAME/ssl/$PROJECT_URL.crt
    SSLCertificateKeyFile /var/www/$PROJECT_NAME/ssl/$PROJECT_URL.key
</VirtualHost>
EOT
echo -e "Create vhost.conf ${GREEN}success${NC}"

touch $PROJECT_DIR/shell.nix
tee -a $PROJECT_DIR/shell.nix > /dev/null <<EOT
{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    nodejs
    php
    wp-cli
  ];
}
EOT
echo -e "Create shell.nix ${GREEN}success${NC}"

touch $PROJECT_DIR/log/apache-access.log
touch $PROJECT_DIR/log/apache-error.log
echo -e "Create access.log and error.log ${GREEN}success${NC}"

# create certificate
cd $PROJECT_DIR/ssl
${SERVER_PATH}apache/certificate-add.sh $PROJECT_URL
cd $PROJECT_DIR
# add url to /etc/hosts done by certificate-add.sh
# concatenate vhosts
${SERVER_PATH}apache/vhosts.sh

# wordpress?
while true; do
	read -p "Do you wish to install wordpress? [y/n]" yn
	echo ""

	case $yn in
		[Yy]* )   # starting webserver if not running
            existing_containers=`docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F $SERVER_NAME`

            if [ -z "$existing_containers" ]; then
                echo "webserver not running. starting …"
                docker stack deploy -c ${SERVER_PATH}docker-compose.yml $SERVER_NAME
            fi

		    echo -e "The Site Title is set as: ${Green}${PROJECT_NAME}${NC}"
			echo -e "The Site URL is set as: ${Green}${PROJECT_URL}${NC}"
			while true; do
				read -p "Is 'mysql' ok for database host?[y/n]" yn
				case $yn in
					[Yy]* )   DB_HOST="mysql"
				break;;
					[Nn]* ) read -p "Your database host: " DB_HOST; break;;
					* ) echo "Please answer yes [Y] or no [N].";;
				esac
			done

			echo ""
			read -p "The database name: " DB
			read -p "The database prefix (underscore will be appended): " PREFIX
			echo ""

			while true; do
				read -p "Do you want to use your default db user credentials?[y/n]" yn
				case $yn in
					[Yy]* ) break;;
					[Nn]* ) read -p "The database user: " DB_USER
					read -p "The database root password: " DB_PASS; break;;
					* ) echo "Please answer yes [Y] or no [N].";;
				esac
			done

			echo ""

			while true; do
				read -p "Do you want to use your default admin user credentials?[y/n]" yn
				case $yn in
					[Yy]* ) break;;
					[Nn]* ) read -p "The Wordpress admin username: " ADMIN_USR
					read -p "The Wordpress admin mail: " ADMIN_MAIL
					read -p "The Wordpress admin password: " ADMIN_PASS; break;;
					* ) echo "Please answer yes [Y] or no [N].";;
				esac
			done

			cd $PROJECT_DIR/dev

			WP_PROJECT_URL="https://$PROJECT_URL";

			# Download WP and Config
			echo ""
			wp core download --locale=de_DE --skip-content
			wp core config --dbname=$DB --dbuser=$DB_USER --dbpass=$DB_PASS --dbprefix="${PREFIX}_" --dbhost=$DB_HOST
			wp db create

			# Run WP Install
			echo ""
			wp core install --url=$WP_PROJECT_URL --title=$PROJECT_NAME --admin_user=$ADMIN_USR --admin_password=$ADMIN_PASS --admin_email=$ADMIN_MAIL --skip-email

			# Delete installed posts and create homepage
			echo ""
			wp option update blogname $PROJECT_NAME

			# Set Your Timezone - Most of you will want to change this
			echo ""
			wp option update timezone_string Switzerland/Bern
			wp option update blogdescription ""

			# Options checkboxes the way we like them
			echo ""
			wp option update default_pingback_flag 0
			wp option update default_ping_status 0
			wp option update default_comment_status 0
			wp option update comment_registration 1
			wp option update blog_public 0
			wp comment delete 1

			# Delete «Hello World» defualt post
			echo "Delete «Hello World» defualt post"
			wp post delete 1 --force

			echo ""
			echo "Rewrite Structure and Flush Rules"
			wp rewrite structure '/%postname%/'

			# Set the WP_DEBUG constant to true.
			wp config set WP_DEBUG true --raw

			# Spit out username and password details
			echo ""
			echo "WORDPRESS"
			echo "---"
			echo "User: $ADMIN_USR"
			echo "Pass: $ADMIN_PASS"
			echo ""
			break;;
		[Nn]* ) echo ""; echo -e "${GREEN}Continuing without WordPress …${NC}"
			echo ""
			echo "<?php phpinfo();" > $PROJECT_DIR/dev/index.php
			break;;
		* ) echo "Please answer yes [Y] or no [N].";;
	esac
done

# restart webserver

spin_index=0
spin='-\|/'
existing_containers=`docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F $SERVER_NAME`

if [ -z "$existing_containers" ]; then
    echo "webserver not running"
else
    docker stack rm $SERVER_NAME
    while output=$(docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F $SERVER_NAME); [ -n "$output" ]; do
        spin_index=$(( (spin_index+1) %4 ))
        printf "\rStopping webserver … ${spin:$spin_index:1}"
        sleep .1
    done
    echo "\nwebserver stopped"
    sleep 1.5
fi

echo "starting webserver"
docker stack deploy -c ${SERVER_PATH}docker-compose.yml $SERVER_NAME

# finish
echo -e "Project setup for ${GREEN}${PROJECT_NAME} done${NC} ✨ HAPPY CODING!"

open "https://$PROJECT_URL"
cd $PROJECT_DIR
