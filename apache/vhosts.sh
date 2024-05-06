#! /bin/bash
#
# Concatenate all Apache virtual hosts config files
# into single config file to use for Docker.

## static vars
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# get directory where the script lives
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# concatenate vhosts
cat $SCRIPT_DIR/webserver-root/**/vhost.conf > $SCRIPT_DIR/vhosts.conf

# console feedback
for directory in $SCRIPT_DIR/webserver-root/* ; do
    fname=`basename $directory`

    FILE=/etc/resolv.conf
    if [ -f "$directory/vhost.conf" ]; then
        echo -e "$fname ${GREEN}✔${NC}"
    else
        echo -e "$fname ${RED}✖${NC}"
    fi
done

echo -e "${GREEN}==> ✅ virtual hosts collected ${HOSTS}${NC}"
