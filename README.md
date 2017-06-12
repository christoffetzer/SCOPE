# SCOPE

Scope is a simple visualization tool to get a view of what containers are running.


## Installation

Log into a host of your Docker Swarm and execute:

```bash
docker stack deploy -c scope.yml SCOPE
```

## Usage

Point your browser to port 4040 of the docker host.`open http://localhost:4040`. You will see a dashboard similar to this:

[![SCOPE Screenshot](scope.tiff)](SCOPE Dashboard)

In case your docker engine is on DOCKERHOST sitting behind a firewall, you might forward a tunnel to the docker host:

```bash
ssh -Nnf -L 4040:localhost:4040 DOCKERHOST
```
