# vars
SERVER_NAME=webserver
SERVER_PATH=~/Docker/webserver/

# aliases
alias sdown="docker stack rm $SERVER_NAME"
alias sup="docker stack deploy -c ${SERVER_PATH}docker-compose.yml $SERVER_NAME"
alias svh="${SERVER_PATH}apache/vhosts.sh"
alias spadd="cd $SERVER_PATH/apache && nix-shell --run ${SERVER_PATH}apache/add-project.sh"
alias scadd="${SERVER_PATH}apache/certificate-add.sh"
alias scrm="${SERVER_PATH}apache/certificate-remove.sh"
alias shadd="${SERVER_PATH}apache/hosts-add.sh"
alias shrm="${SERVER_PATH}apache/hosts-remove.sh"
alias scd="cd ${SERVER_PATH}apache/"
alias hosts='cat /etc/hosts'

# Custom command to interact with Docker webserver container
function scon() {
  containers=`docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F ${SERVER_NAME}_php`
  container_id=`echo $containers | awk '{print $1}'`

  if [ -n "$container_id" ]; then
    docker exec -it $container_id /bin/zsh
  else
    echo "webserver not found"
  fi
}

# Custom command to interact with Docker mysql container
function scondb() {
  containers=`docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F ${SERVER_NAME}_mysql`
  container_id=`echo $containers | awk '{print $1}'`

  if [ -n "$container_id" ]; then
    docker exec -it $container_id /bin/bash
  else
    echo "mysql server not found"
  fi
}

# Custom command to restart (or start) webserver
function sres() {
    spin_index=0
    spin='-\|/'
    existing_containers=`docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F $SERVER_NAME`

    if [ -z "$existing_containers" ]; then
        echo "webserver not running"
    else
        sdown
        while output=$(docker ps | awk '{print $1,$2,$NF}' | grep -m 1 -F $SERVER_NAME); [ -n "$output" ]; do
            spin_index=$(( (spin_index+1) %4 ))
            printf "\rStopping webserver … ${spin:$spin_index:1}"
            sleep .1
        done
        echo "\nwebserver stopped"
        sleep 1.5
    fi

    echo "starting webserver"
    sup
}
