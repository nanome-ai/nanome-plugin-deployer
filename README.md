# Nanome Plugin Deployer

A quick script to deploy Nanome plugins

## Video tutorial

Check out our step-by-step tutorial on deploying Nanome plugins from setting up a server to running a plugin:
https://youtu.be/YrEJ1xfZ9a0

## Nanome Plugin Deployment Instructions

In order to successfully complete the deployment of Nanome plugins, you will need to verify that your license is Stack Enabled and you have the Stacks Configuration details in-hand (consists of an IP address and a port).

For Non-Enterprise Customers, please verify that your Nanome Licenses are _Stacks Enabled_ with your Nanome representative.

Nanome Plugins include:

- 2D Chemical Preview - generate 2D chemical representations
- Chemical Interactions - calculate interactions using Arpeggio
- Chemical Properties - cheminformatics calculation using RDKit
- Conformer Generator - generate conformers using RDKit
- Coordinate Align - align coordinate systems of multiple molecules
- Data Table - view multi-frame molecular data in a table on the in-VR browser
- Docking - using Smina Docking software
- ESP - calculate electrostatic potential map.
- High Quality Surfaces - generate stunning molecular surfaces with ambient occlusion
- Hydrogens - add and remove hydrogens to selected structures within the Nanome workspace
- Merge as Frames - merge multiple molecules into a single molecule with multiple frames
- Minimization - run energy minimization for molecular structures
- Real-Time Atom Scoring - using DSX software
- RMSD - pairwise structural alignment
- SMILES Loader - use RDKit for SMILES parsing and generation
- Structure Prep - re-calculate bonds and ribbons for Quest users
- Superimpose Proteins - align protein structures
- Vault - web-based file management (perfect for Quest)

Nanome Services include:

- Quick Drop - drag and drop files onto a web page to load them into Nanome

### Step 1: Provisioning the Dedicated Plugins Virtual Machine

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
HTTPS Port 443

### Step 2: SSH into the VM + Install Git & Docker

SSH into the VM using the IP address and the user

```sh
ssh ec2-user@<ip-address>

sudo yum install docker git -y
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo service docker start
```
Now Log out and back into the instance

* If you are on a CentOS machine then follow this for installing docker: https://docs.docker.com/engine/install/centos/

### Step 3: Pull the Nanome Plugin Deployer and run it

```sh
git clone https://github.com/nanome-ai/nanome-plugin-deployer
cd nanome-plugin-deployer
```

For a typical deployment, run the following command:
```sh
NTS_IP=<your Nanome Stacks Config IP>
HOST_IP=<your VM Host IP>
sudo ./deploy.sh -a $NTS_IP \
  --plugin data-table --nginx -u table.example.com \
  --plugin vault --nginx -u vault.example.com \
  --service quickdrop --nginx --url quickdrop.example.com
```

\*Make sure to configure your virtual machine to have the ports 80 and 443 to have the security group configured to allow TCP custom port traffic (from 0.0.0.0/0 default).

In order for the web pages for Data Table and Vault to work, you'll have to create DNS entries for table.example.com and vault.example.com to point to the IP address of the virtual machine, replacing "example.com" with your domain.

NOTE: to add arguments specific to a plugin, append any number of `--plugin <plugin-name> [args]` to the `./deploy.sh` command.

#### DNS for Web Plugins and Services

Since Data Table, Vault, and Quick Drop all use web servers, an nginx reverse proxy will be started to forward the requests to the appropriate web servers. The recommended way to do this is to create DNS entries for the domains you want to use for these plugins and services. For example, if you want to use `table.example.com`, `vault.example.com`, and `quickdrop.example.com` you'll have to create DNS entries for those domains to point to the IP address of the virtual machine, replacing "example.com" with your domain.

As an alternative to using custom DNS, you can use nip.io by replacing `.example.com` with `.$HOST_IP.nip.io` (e.g. `vault.example.com` becomes `vault.$HOST_IP.nip.io`). nip.io is a wildcard DNS service that will resolve to the IP address provided, while still letting nginx know which web plugin or service to forward the request to.

#### HTTPS for Web Plugins and Services

If you would like to enable HTTPS for Data Table and Vault, you can do so by adding the `--https` flag to both the `--plugin data-table` and `--plugin vault` parts of the command after each `--nginx` flag.

For Quick Drop, the same can be done by adding the `--https` flag to the `--service quickdrop` part of the command after the `--nginx` flag.

By default, self-signed certs in the nginx/certs folder are used, but if you'd like to provide your own certs, simply replace `default.crt` and `default.key` with your own certs.

#### Advanced

If you wish to enable git-ops style deployments, you can replace `./deploy.sh` with `./remote_deploy.sh` in the command above. Remote deploy will clone the plugin repositories using bare repos, which allows you to push changes to the repo. When a change is received, it uses git hooks to build and deploy your latest changes.

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
If you are unable to deploy the plugins alongside your proxy, please use the following set of commands to get things up and running:

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
