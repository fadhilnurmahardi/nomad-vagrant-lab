# HashiCorp Nomad - Local Lab Using Vagrant
## What is this?

A simple 3-node or 6-node lab running Ubuntu servers on VirtualBox and each node runs Consul and Nomad servers which can be configured as a cluster. And able to run vault to one node (currently cannot be clustered because use file storage).

## Why use this method?

This is a great way to get your feet wet with Nomad in a simplified environment and you also have a chance to mess around with the configurations and commands without risking a cloud (read: money) installation or a production (read: danger!) environment.

## Requirements

There are a few things you need to get this going:

* Vagrant

* VirtualBox

## How to use the Nomad lab configuration

### For 3-node clusters you must rename `Vagrantfile.3node` to `Vagrantfile`
### For 6-node (two region) clusters you must rename `Vagrantfile.6node` to `Vagrantfile`

* Change directory and run a `vagrant status` to check the dependencies are met

* Run a `vagrant up` command and watch the magic happen!

* Each node will able to run Consul, Nomad and Vault (with file storage)

To start your Nomad cluster just do this: 

* `vagrant ssh <node_name> -c "sudo /vagrant/launch-services.sh"` where `<nodename>` is the instance name (e.g. nomad-a-1, nomad-b-1).

* To run vault & init on nomad-a-1 node `vagrant ssh nomad-a-1 -c "sudo /vagrant/launch-services.sh --run-vault --init-vault"`

* The initial vault secret will be on your `/vagrant/playgroud/vault` (inside vagrant instance) or `./playgroud/vault` (outside vagrant instance)

Now you're running!

## Interacting with the cluster

Logging into the systems locally can be done 

* You can use some simple commands to get started 
```
nomad node status
```
* To open the Nomad UI use this command on your local machine
```
open http://172.16.1.101:4646
```
* To open the Consul UI use this command on your local machine
```
open http://172.16.1.101:8500
```
* To open the Vault UI use this command on your local machine
```
open http://172.16.1.101:8200
```

## My Setup step

* `vagrant up` for start vagrant

* `vagrant ssh nomad-a-1 -c "sudo /vagrant/launch-services.sh --run-vault --init-vault" && vagrant ssh nomad-a-2 -c "sudo /vagrant/launch-services.sh" && vagrant ssh nomad-a-3 -c "sudo /vagrant/launch-services.sh"` for start all services (vault root_token can be found in `playgroud/vault`)

* go to `vault-nomad-integration` and run `terraform apply` -> create policy and app role for nomad server

* `vagrant ssh nomad-a-1 -c "AWS_KEY=xxx AWS_SECRET=xxx /vagrant/helpers/docker-ecr-integration.sh" && vagrant ssh nomad-a-2 -c "AWS_KEY=xxx AWS_SECRET=xxx /vagrant/helpers/docker-ecr-integration.sh" && vagrant ssh nomad-a-3 -c "AWS_KEY=xxx AWS_SECRET=xxx /vagrant/helpers/docker-ecr-integration.sh"` for setup integration to AWS ECR

* `vagrant ssh nomad-a-1 -c "VAULT_TOKEN=root_token /vagrant/helpers/nomad-vault-integration.sh" && vagrant ssh nomad-a-2 -c "VAULT_TOKEN=root_token /vagrant/helpers/nomad-vault-integration.sh" && vagrant ssh nomad-a-3 -c "VAULT_TOKEN=root_token /vagrant/helpers/nomad-vault-integration.sh"` for setup integration between nomad and vault

* `vagrant ssh nomad-a-1 -c "sudo /vagrant/helpers/install-cni-plugin.sh" && vagrant ssh nomad-a-2 -c "sudo /vagrant/helpers/install-cni-plugin.sh" && vagrant ssh nomad-a-3 -c "sudo /vagrant/helpers/install-cni-plugin.sh"` for install depedency (optional) if you use sidecar proxy you need to do it

* `vagrant ssh nomad-a-1 -c "sudo /vagrant/helpers/nomad-bootsrap-token.sh"` to generate bootsrap token nomad -> result can be found in `nomad_bootsrap_token`

After these step you'll have `Vault, Consul Cluster, Nomad Cluster (with integration to vault, aws ecr and ready to use sidecar proxy)`

