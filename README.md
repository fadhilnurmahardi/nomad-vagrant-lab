# HashiCorp Nomad - Local Lab Using Vagrant
## What is this?

A simple 3-node or 6-node lab running Ubuntu servers on VirtualBox and each node runs Consul and Nomad servers which can be configured as a cluster.

## Why use this method?

This is a great way to get your feet wet with Nomad in a simplified environment and you also have a chance to mess around with the configurations and commands without risking a cloud (read: money) installation or a production (read: danger!) environment.

## Requirements

There are a few things you need to get this going:

* Vagrant

* VirtualBox

## How to use the Nomad lab configuration

### For 3-node clusters you must rename `Vagrantfile.3node` to `Vagrantfile`
### For 6-node (two region) clusters you must rename `Vagrantfile.6node` to `Vagrantfile`

* Clone this repo (or fork it of you so desire and want to contribute to it)

* Change directory and run a `vagrant status` to check the dependencies are met

* Run a `vagrant up` command and watch the magic happen! (spoiler alert: it's not magic, it's technology)

* Each node will able to run Consul and Nomad 

To start your Nomad cluster just do this: 

* `vagrant ssh <node_name> -c "sudo /vagrant/launch-nomad-consul.sh"` where `<nodename>` is the instance name (e.g. nomad-a-1, nomad-b-1).

Now you're running!

## Interacting with the Nomad and Consul cluster

Logging into the systems locally can be done 

* You can use some simple commands to get started 
```
nomad node status
```
* To open the Nomad UI use this command on your local machine
```
open http://172.16.1.101:4646
```

