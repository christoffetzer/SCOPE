#!/bin/bash
#
# set up tunnels to scopes of a docker swarm
#
# (C) Christof Fetzer, 2017

set -e


#
# Arguments
#

export DEFAULT_SCOPE=4040
export LOCALSCOPEPORT=$DEFAULT_SCOPE

export verbose_on=false
export dryrun=false
export printports=false

function verbose
{
    if [[ $verbose_on == true  ]] ; then
        echo $@
    fi
}


function usage {
    echo "Usage: `basename ${BASH_SOURCE[0]}` [OPTIONS]"
    echo "Utility establishes ssh tunnels to SCOPE instances."
    echo "Note: options are execute in the order given on the command line."
    echo "-R PORT    fist port exported by SCOPE in a swarm (default: $DEFAULT_SCOPE)"
    echo "-L PORT    local port to use for SCOPEs to use, incremented across nodes/clusters (next: $LOCALSCOPEPORT)"
    echo "-m MANAGER swarm manager to connect to"
    echo "-d         dry run - do not setup ssh tunnels but print ports via -p"
    echo "-h         print this help message."
    echo "-v         print some progress messages."
    echo "-p         print port mapping."
    echo "-x         debug mode - prints all executed commands."
    echo "-s         stop existing ssh tunnels - use with care!"
    echo "Example:   `basename ${BASH_SOURCE[0]}` -v -p -m swarm.manager.node"
    if [[ $1 != 0 ]] ; then
        exit $1
    fi
}

function setup_tunnels
{
    M=$1

    verbose "Setting up tunnels to swarm manager $M"

    SCOPEPORT=$DEFAULT_SCOPE
    NONODES=`ssh $M docker node  ls -q | wc -l`
    SSHCMD="ssh -nNf "

    verbose "  tunnels for SCOPE: ports $SCOPEPORT...$((SCOPEPORT+NONODES-1))"

    for PORT in `seq $SCOPEPORT $((SCOPEPORT+NONODES-1))`; do
        SSHCMD="$SSHCMD -L $LOCALSCOPEPORT:$M:$PORT"
        if [[ $printports == true ]] ; then
            echo " mapping SCOPE $M:$PORT to localhost:$LOCALSCOPEPORT"
        fi
        ((LOCALSCOPEPORT++))
    done

    SSHCMD="$SSHCMD $M"
    verbose "setting up tunnels:  $SSHCMD"
    if [[ $dryrun == false ]] ; then
        eval $SSHCMD
    fi
}


function stop_tunnels
{
    verbose "Stopping all existing tunnels"
    PIDs=`ps laxx | grep "ssh -nNf -L" | grep -v grep | awk '{{ print $2; }}'`
    NT=`echo -n $PIDs | wc -c`
    if [[ NT -gt 0 ]]  ; then
        verbose "Terminating tunnels with pids: $PIDs"
        if [[ $dryrun == false ]] ; then
            kill -9 $PIDs
        fi
    else
        verbose "No existing tunnels"
    fi
}


while getopts "hL:R:xvm:dps" opt; do
    case ${opt} in
        h)
            usage 0
            ;;
        \?)
            echo "Error: invalid option"
            usage -1
            ;;
        R )
            DEFAULT_SCOPE="${OPTARG}"
            ;;
        L )
            LOCALSCOPEPORT="${OPTARG}"
            ;;
        x )
            set -x
            ;;
        v )
            if [[ $verbose_on == true ]] ; then
                verbose_on=false
            else
                verbose_on=true
            fi
            verbose "Verbose messages switched on."
            ;;
        m )
            setup_tunnels "${OPTARG}"
            ;;
        d )
            dryrun=true
            verbose "Dryrun is switched on."
            ;;
        p )
            printports=true
            verbose "Printing port mappings."
            ;;
        s )
            stop_tunnels
            ;;
    esac
done


