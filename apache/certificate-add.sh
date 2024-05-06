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

## create .conf file
sudo touch $DOMAIN.conf
echo -e "Create $DOMAIN.conf ${GREEN}success${NC}"

## write to conf
sudo tee -a $DOMAIN.conf > /dev/null <<EOT

[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
EOT

## generate ssl certificate
echo -e "Generating $DOMAIN.key …"
sudo openssl genrsa -out $DOMAIN.key 2048
echo -e "Generating $DOMAIN.key ${GREEN}success${NC}"
echo ""

echo -e "Generating $DOMAIN.key.rsa …"
sudo openssl rsa -in $DOMAIN.key -out $DOMAIN.key.rsa
echo -e "Generating $DOMAIN.key.rsa ${GREEN}success${NC}"
echo ""

echo -e "Generating $DOMAIN.csr …"
sudo openssl req -new -key $DOMAIN.key.rsa -subj /CN=$DOMAIN -out $DOMAIN.csr -config $DOMAIN.conf
echo -e "Generating $DOMAIN.csr ${GREEN}success${NC}"
echo ""

echo -e "Generating $DOMAIN.crt …"
sudo openssl x509 -req -extensions v3_req -days 7305 -in $DOMAIN.csr -signkey $DOMAIN.key.rsa -out $DOMAIN.crt -extfile $DOMAIN.conf
echo -e "Generating $DOMAIN.crt valid for 20 years ${GREEN}success${NC}"
echo ""

## add the certificate to keychain
echo -e "Adding SSL certificate to Keychain Access …"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $DOMAIN.crt
echo -e "Adding SSL certificate to Keychain Access ${GREEN}success${NC}"
echo ""

echo -e "${GREEN}==> ✅ Successfully created Certificate for $DOMAIN${NC}\n"

## set correct file permissions
sudo chmod 644 $DOMAIN.key
sudo chmod 644 $DOMAIN.key.rsa

## host file check if domain exists
# -q = quite mode, so no output for grep
# --ignore-case = case insensitive
if ! grep -q "$DOMAIN" $HOSTS --ignore-case
then
    while true; do
		read -p "⚠️  ${DOMAIN} is not in ${HOSTS}. Shall I add it? [y/n]" yn
		case $yn in
			[Yy]* )
			    ~/Docker/webserver/apache/hosts-add.sh $DOMAIN
                break;;
			[Nn]* )
			    echo -e "${RED}Well then … good luck${NC}";
				break;;
			* ) echo "Please answer yes [Y] or no [N].";;
		esac
	done
else
	echo -e "${GREEN}==> ✅  ${DOMAIN} already in ${HOSTS}${NC}"
fi
