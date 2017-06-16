#!/bin/bash

set -e 

verbose_on=${VERBOSE:-false}
outputfile=${OUTPUTFILE:-"scope-generated.yml"}

function verbose
{
    if [[ $verbose_on = true ]] ; then
        echo $@
    fi
}


function no_nodes
{
    nodes=`docker node ls --format "{{.Hostname}}" | sort`
    verbose "determine number of nodes in swarm: $nodes."
}

# create stack file:

function create_yml
{
    no=$(no_nodes)
    export NODENO=1
    export PORT=4040
    cp scope-stack.yml $outputfile
    for node in `seq 1 $no` ; do
        verbose  "Adding config for node $no "
        envsubst < scope-template.yml >> $outputfile
        ((PORT++))
    done
    
}

create_yml
echo docker stack deploy -c $outputfile SCOPE

echo "OK: SCOPE deployed."

