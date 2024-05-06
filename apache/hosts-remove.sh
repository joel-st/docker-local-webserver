#! /bin/bash

# Create a ssl certificate based on domain name
# Add it to the keychain

## configurable vars
USER=`whoami`
HOSTS=/etc/hosts

## static vars
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

## get DOMAIN if not set
DOMAIN=${1:-} # if argument 1 is set use it as domain domain

if [ -z $DOMAIN ];
then
    echo -n -e "${GREEN}Domain: ${NC}"
    read DOMAIN

    while [ -z $DOMAIN ] ; do
    	echo -n -e "${RED}Domain cannot be empty! Try again…\n${NC}"
    	echo -n -e "${GREEN}Domain: ${NC}"
    	read DOMAIN
    done
fi

## host file check if domain exists
# -q = quite mode, so no output for grep
# --ignore-case = case insensitive
if ! grep -q "$DOMAIN" $HOSTS --ignore-case
then
    echo -e "${GREEN}==> ✅  ${DOMAIN} is not in ${HOSTS}${NC}"
else
	sudo sed -i '' -e "/$DOMAIN/d" $HOSTS
	# remove last line if line is empty
	sudo sed -i '' -e '$ d' $HOSTS
	echo -n -e "${GREEN}==> ✅ Removed ${DOMAIN} from ${HOSTS}${NC}\n"
fi
