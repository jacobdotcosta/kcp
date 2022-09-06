## How to play with kcp

In order to use, play with kcp it is needed to install different tools: kcp, kubectl kcp plugins and launch it.
Next, you can create workspaces and start to setup logical clusters that kcp will manage on physical clusters.

Launch the kcp control plane using the bash script `./kcp.sh`.

**Note**: If kcp is not installed like the kubectl kcp plugins, then they will be installed

Next, in a second terminal, you can demo it using the 2nd script `./demo.sh`.

During the execution of the script, the following steps will take place:

- The `my-org` workspace is created and defined as `current`
- The `sync` tool is installed on the kind cluster 
- Resources are sync between kcp and the physical cluster
- A kuard app is deployed using kcp within the `my-org` workspace
- Workspace is switched to `root` 
- We check that no deployments exist within the `root` workspace