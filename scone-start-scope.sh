#!/bin/bash
# 
# Run this script installs and operates scope on a docker swarm
#
# 
# scone scope create —manager NODE
# scone scope tunnel —manager NODE
# scone scope check —manager NODE
# scone scope tunnel —manager NODE
#
# (C) Christof Fetzer, 2017

set -e

# set and check global variables

dir=`dirname ${BASH_SOURCE[0]}`

if [[ ! -e "$dir/scone-commons.sh" ]] ; then
    echo "error: file $dir/scone-commons.sh does not exist - $cmd not correctly installed - exiting."
    exit -1
fi
source "$dir/scone-commons.sh"
SCOPE=${SCOPE:-"4040"}
add_variable SCOPE 


function usage {
    echo "Usage: ${CMDNAME} [COMMAND|--version|--help] [OPTIONS*]"
    echo "installs or checks SCOPE stack."
    echo ""
    echo "Commands:"
    echo "  install   installs and starts the SCOPE stack"
    echo "  check     checks and tries to correct the SCOPE stack"
    echo "  start     starts the SCOPE stack (same as install)"
    echo "  stop      stops the SCOPE stack"
    echo "  tunnel    sets up tunnels to SCOPE instances. Stop with option --stop)"
    echo "  uninstall remove the SCOPE stack (same as stop)"
    echo ""
    echo "Options:"
    echo "  --help          show this help message"
    echo "  --verbose       show verbose messages"
    echo "  --debug         issue debug messages"
    echo "  --manager HOST  manager of swarm"
    echo "  --import file   import file"
    echo "  --export file   export file"
    echo "  --stop          stops all tunnels to manager node"
    echo "Example: to install and then check the SCOPE stack on host alice"
    echo "${CMDNAME}  install --verbose --manager alice"
    echo "${CMDNAME}  check   --verbose"
    disable_on_error_exit
    exit $1
}
# all state is specific to manager of docker swarm

function set_state {
    outputfile="$dir/scope-generated.yml"
    remote_user=`$prefix 'id -u'`
    remote_grp=`$prefix 'id -g'`

    if [[ "$scone_monitor_tunnel_port" == "" ]] ; then
        scone_monitor_tunnel_port=11100
        add_variable scone_monitor_tunnel_port
    fi
}


# deploy Postgres and Redis
function deploy_stack {
    no=${#NODES[@]}
    export NODENO=1
    export PORT=4040
    cp $dir/scope-stack.yml $outputfile
    for NODENO in `seq 1 $no` ; do
        verbose  "Adding config for node $NODENO "
        envsubst < $dir/scope-template.yml >> $outputfile
        let ++PORT
    done

    # now start SCOPE
    copy_to_remote $outputfile $manager /tmp/scope-stack.yml "0400" "$remote_user" "$remote_grp"
    $prefix sudo docker stack deploy -c /tmp/scope-stack.yml SCOPE
}

function check_scope {
    nodes=`$prefix sudo docker stack ps --filter "desired-state=Running" SCOPE -q | wc -l`
    ((nodes--))
    if [[ $nodes == ${#NODES[@]} ]] ; then
        verbose "all SCOPE containers are running"
    else
        error_exit "Not all SCOPE containers are running: Only $nodes of ${#NODES[@]}"
    fi
}

function  start_tunnel {

    socketpaths="$configdir/sockets"
    controlpath="$socketpaths/$manager"

    mkdir -p $socketpaths

# stop all tunnels?

    if [[ $stop_it == true ]] ; then
        verbose "  stopping tunnels to $manager"
        stop=true
        ssh -O check -S $controlpath $manager 2> /dev/null || stop=false
        if [[ $stop == true ]] ; then
            ssh -O stop -S $controlpath $manager 2> /dev/null || echo "Stopped."
        fi
        return
    fi

# ensure that master ssh is running
    restart=false
    ssh -O check -S $controlpath $manager 2> /dev/null || restart=true
    if [[ $restart == true ]] ; then
        rm -f $controlpath
        ssh -MNnf -S  $controlpath $manager
    fi

# SCOPE tunnel

# todo: use manager_node index instead - in case #NODES has increased...

    m=`echo $manager | tr '-' '_'`   # "-" permitted in hostnames / not in variables ; "_" not permitted in hostnames but in variables...

    var=scone_scope_port_${m}
    no=${#NODES[@]}
    if [[ ! ${!var} == "" ]] ; then
        let local_port=${!var}
    else
        let local_port=$scone_monitor_tunnel_port        
        let scone_monitor_tunnel_port=$scone_monitor_tunnel_port+$no
    fi
    let scone_scope_port_${m}=$local_port
    add_variable scone_scope_port_${m}
    echo $local_port

    verbose "  tunnel to scope on cluster $manager available at http://localhost:${!var}"
    PORT=$SCOPE
    for NODENO in `seq 1 $no` ; do
        verbose  "Adding tunnel for node $NODENO (local port $local_port)"
        ssh -O forward -S $controlpath -L  $local_port:$manager:$PORT $manager
        let ++local_port
        let ++PORT
    done

}

function stop_services {
    verbose "Stopping service SCOPE"
    $prefix "sudo docker stack rm SCOPE"
}

function uninstall_services {
    stop_services
}

# translate long options into short options

for arg in "$@"; do
  shift
  case "$arg" in
    "--help")       set -- "$@" "-h" ;;
    "--verbose")    set -- "$@" "-v" ;;
    "--debug")      set -- "$@" "-x" ;;

    "--import")     set -- "$@" "-i" ;;
    "--export")     set -- "$@" "-e" ;;

    "--manager")    set -- "$@" "-m" ;;
    "--stop")       set -- "$@" "-s" ;;

    "tunnel")       set -- "$@" "-T" ;;
    "install")      set -- "$@" "-C" ;;
    "uninstall")    set -- "$@" "-U" ;;
    "check")        set -- "$@" "-D" ;;
    "stop")         set -- "$@" "-S" ;;
    "start")        set -- "$@" "-X" ;;
    *)              set -- "$@" "$arg"
  esac
done

# process short options
while getopts "vhxsm:i:e:CDSTUX" opt; do
    case ${opt} in
    "v")    vflag="-v"
            verbose_on=true ;;
    "h")    usage 0 ;;
    "s")    stop_it=true ;;
    "x")    xflag="-x"
            set -x ;;

    "m")    manager="$OPTARG" ;;
    "i")    source "$OPTARG" ;;
    "e")    export_file="$OPTARG" ;;

    "C")    command="install" ;; # use last command specified
    "D")    command="check" ;; # use last command specified
    "S")    command="stop" ;;
    "T")    command="tunnel" ;; 
    "U")    command="uninstall" ;; 
    "X")    command="start" ;; 
    
    ?)      log_error "invalid option (argument # $(($OPTIND - 1)))"
            usage -1 ;;
    esac
done

# check that all arguments were processed
shift $(($OPTIND - 1))
if [[ $# -ge 1 ]] ; then
    log_error "unexpected command line arguments ($@)"
    usage -1
fi


if [[ ! $export_file == "" ]] ; then
    update_external_state $export_file
fi


if [[ $manager == "" ]] ; then
    log_error "manager must be specified"
    usage -1
fi

ip_address $manager
prefix="ssh $manager"

get_nodes $manager

case $command in
    "") log_error "no command specified"
        usage -1 ;;

    "install")
        set_state
        deploy_stack ;;

    "stop")
        stop_services ;;

    "start")
        set_state
        deploy_stack ;;

    "uninstall")
        uninstall_services ;;

    "tunnel")
        set_state
        start_tunnel ;;

    "check")  
        check_scope ;;

    ?)  log_error "invalid command ($command) - internal error"
        usage -1 ;;
esac
update_external_state