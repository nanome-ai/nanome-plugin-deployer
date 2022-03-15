# Auto Deploy the Nanome Starter Stack

A quick script to deploy the Nanome Starter Stack group of plugins

## Video tutorial

Check out our step-by-step tutorial on deploying Nanome Starter Stack from setting up a server to running a plugin:
https://youtu.be/YrEJ1xfZ9a0

## Nanome Starter Stack Deployment Instructions

In order to successfully complete the deployment of Nanome’s starter stack group of plugins, you will need to verify that your license is Stack Enabled and you have the Stacks Configuration details in-hand (consists of an IP address and a port).

For Non-Enterprise Customers, please verify that your Nanome Licenses are _Stacks Enabled_ with your Nanome representative.

Starter Stack Plugins include::

- 2D Chemical Preview - generate 2D chemical representations
- Chemical Interactions - calculate interactions using Arpeggio
- Chemical Properties - cheminformatics calculation using RDKit
- Docking - using Smina Docking software
- ESP - calculate electrostatic potential map.
- Hydrogens - add and remove hydrogens to selected structures within the Nanome workspace
- Minimization - run energy minimization for molecular structures
- Real-Time Atom Scoring - using DSX software
- RMSD - pairwise structural alignment
- Structure Prep - re-calculate bonds and ribbons for Quest users
- Vault - web-based file management (perfect for Quest)

### Step 1: Provisioning the Dedicated Stack/Plugins Virtual Machine

Specifications:
Amazon AWS T2.medium EC2 Linux machine with 30 GB of disk storage or equivalent

Equivalent

- A Linux based operation system (Ubuntu or CentOS)
- 2 CPU - equiv. to an Intel Broadwell E5-2686v4 or higher
- 4GB of RAM
- 30GB of Storage space

Security Groups:

Configure the security groups to allow the following traffic:
SSH Port 22
HTTP Port 80

### Step 2: SSH into the VM + Install Git & Docker

SSH into the VM using the IP address and the user

```sh
ssh ec2-user@<ip-address>

sudo yum install git -y
sudo yum install docker -y
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo service docker start
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


```
Now Log out and back into the instance

* If you are on a CentOS machine then follow this for installing docker: https://docs.docker.com/engine/install/centos/

### Step 3: Pull the Nanome Starter Stack auto-deploy script and run it

```sh
git clone https://github.com/nanome-ai/nanome-starter-stack
cd nanome-starter-stack
```

For a typical deployment, run the following command:
```sh
sudo ./deploy.sh -a <your Nanome Stacks Config IP> -p <your Nanome Stacks Config port> --plugin data-table -w 81 -u <your VM Host IP> --plugin vault -w 80 -u <your VM Host IP>
```

*Where the Nanome Data Table Web UI (-w) is on port 81, Nanome Vault Web UI (-w) is on port 80, and (-u) specifies the IP address of your current VM.
*Make sure to configure your Virtual machine to have the ports 80 and 81 to have the security group configured to allow TCP custom port traffic (from 0.0.0.0/0 default).

NOTE: to add arguments specific to a plugin, append any number of `--plugin <plugin-name> [args]` to the `./deploy.sh` command.

Advanced: If you wish to enable git-ops style deployments, you can replace `./deploy.sh` with `./remote_deploy.sh` in the command above. Remote deploy will clone the plugin repositories using bare repos, which allows you to push changes to the repo. When a change is received, it uses git hooks to build and deploy your latest changes.

### Step 4: Docker Container Health Check

Now check to make sure all the docker containers are working properly

```sh
docker ps
```

This should list out the plugins that are currently running. Please verify that none of the containers in the column labeled 'X' has a "restarting (x sec)".

### Step 5: Validate the connection from the VR client

Go ahead and log onto the VR client computer and launch Nanome

\*Note the VR Client computer and the dedicated Stacks/Plugins VM need to be a part of the same IT firewall network


#### Proxy support
If you are unable to deploy the starter stacks script alongside your proxy. Please use the following set of commands to get things up and running

```
export http_proxy=<http://xxxxxxx:xxxx>
export https_proxy=<https://xxxxxxx:xxxx>
mkdir ~/.docker
cat > ~/.docker/config.json <<EOM
{
  "proxies": {
    "default": {
      "httpProxy": "$http_proxy",
      "httpsProxy": "$https_proxy"
    }
  }
}
EOM
cat > http-proxy.conf <<EOM
[Service]
Environment="HTTP_PROXY=$http_proxy"
Environment="HTTPS_PROXY=$https_proxy"
EOM
sudo mkdir /etc/systemd/system/docker.service.d
sudo mv http-proxy.conf /etc/systemd/system/docker.service.d/
sudo systemctl daemon-reload
sudo systemctl restart docker
```

*Note that most large organizations may not use https behind their network and so the https field of the proxy is the same as the http url.
