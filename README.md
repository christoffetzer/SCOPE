# SCOPE

Scope is a simple visualization tool to get a view of what containers are running.

Since there are still some issues regarding the SCOPEs finding each other, 
we export for each swarm node a scope.

We provide a script to setup the tunnels to the scopes. Identify the manager host of 
your swarm and execute

```bash
./scope-sshtunnels.sh -v -p -m SWARM-MANAGER-HOST
```

## Installation

Log into a manager node of your Docker Swarm. Tag all nodes as described 
in the MONITORING repository.

Then execute:

```bash
./start-scope.sh
```

If the nodes are not properly tagged, the scopes will not run. Right now, nodes are not yet automatically tagged when the join after a reboot.

## Stopping service

```bash
docker stack rm SCOPE
```

## Usage

After setting up the ssh tunnels, point your browser to port 4040- on your local machine: `open http://localhost:4040`

You will see a dashboard similar to this:

![SCOPE Dashboard](Scope.jpg)


## ToDos


- run plugins like https://github.com/weaveworks-plugins/scope-http-statistics

- run https://github.com/weaveworks-plugins/scope-iowait

- https://github.com/weaveworks-plugins/scope-volume-count

- ** Write a plugin that shows the EPC usage**

- integrate with memcached