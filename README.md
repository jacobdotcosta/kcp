## Introduction

In order to use, play with [kcp]((https://github.com/kcp-dev/kcp)) it is needed to install different tools: kcp, kubectl kcp plugins and launch it.
Next, you can create workspaces and start to setup logical clusters that kcp will manage on physical clusters.

## Prerequisite

- kind is installed
- A k8s cluster is up and running (e.g `kind create cluster`)

## How to play with kcp

Different commands have been implemented in order to support to perform using the bash script `./kcp.sh`, the following actions:
```bash
Usage:
  ./kcp.sh <command> [args]

Commands:
    install     Install the kcp server locally and kcp kubectl plugins
    start       Start the kcp server
    stop        Stop the kcp server
    syncer      Generate and install the syncer component top of a k8s cluster
    clean       Clean up the temp directory and remove the kcp plugins

Arguments:
    -v          Version to be used of the kcp server. Default value `0.8.0`
    -t          Temporary folder where kcp will be installed. Default value `_tmp
```

Next, in a second terminal, you can run the `./demo.sh` script.

During the execution of the script, the following steps will take place:

- The `my-org` workspace is created and defined as `current`
- A kuard app is deployed using kcp within the `my-org` workspace
- Workspace is switched to `root` 
- We check that no deployments exist within the current workspace which should be `root`