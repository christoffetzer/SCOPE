#!/bin/bash
#
# setup scone-cli as a git subtree
#
# (C) Christof Fetzer, 2017

set -x -e 

# ci
   sudo SCONE_HOSTINSTALLER/install_patched_docker.sh
# change user has not taken effect - run with sudo
   sudo docker swarm init
   sudo docker node update --label-add nodeno="1" $(sudo docker node ls -q)
   sudo ./start-scope.sh
   sleep 5
   IP=`hostname -I | awk '{print $1;}'`
   sudo docker service ls
   sudo docker service ps SCOPE
   sudo docker ps -a
   wget --retry-connrefused --waitretry=1 --read-timeout=30 --timeout=15 -t 25 http://$IP:4040
   sudo ./stop-scope.sh
