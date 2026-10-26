# Power Virtual Server lab

On the lab machine, open the Fedora terminal in Windows Subsystem for Linux. Package installs use `sudo`.

Terraform builds a PowerVS workspace and an AIX 7.3 server in two applies. The CLI creates the API key, picks the AIX image, and checks the result. Seat 7 is used below as the example. Your names will follow your own seat number.

| | |
|---|---|
| Prefix | `pvs-07`, written into Terraform as `pvs-07-tf` |
| Region | `us-south`, PowerVS zone `dal12` |
| Private network | `192.168.100.0/24` |
| Server | AIX 7.3, system type `s122`, on the private and public networks |

The first apply creates the workspace, both PowerVS networks, the SSH key, a VPC, an Ubuntu server, and a transit gateway between them. The second apply creates the AIX server and a route so the Ubuntu server can reach AIX on its private address. The Fedora terminal reaches AIX on the public address.

## 1. Install the tools

```bash
curl -fsSL https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
sudo dnf install -y terraform ansible-core git jq curl
curl -fsSL https://clis.cloud.ibm.com/install/linux | sudo sh
ibmcloud plugin install power-iaas -f
ibmcloud plugin install vpc-infrastructure -f
```

`sudo dnf` installs Terraform from HashiCorp's Fedora repository, and Ansible from Fedora's own repository. The `ansible-core` package provides the `ansible` command. `git`, `jq`, and `curl` are the other commands this guide uses. If `dnf` asks to import the HashiCorp GPG key, answer yes.

Fedora does not ship the IBM Cloud CLI. IBM's installer copies it to `/usr/local/bin` and runs as root through `sudo`.

The plugins are installed as you, without `sudo`. `power-iaas` adds `ibmcloud pi`. `vpc-infrastructure` adds `ibmcloud is`. They are stored in your home directory. A `sudo` plugin install would store them for root, and your later commands would not see them.

```bash
terraform version
ansible --version
ibmcloud plugin list
ibmcloud login --sso -r us-south
```

`terraform version` needs 1.5 or newer. `ibmcloud login --sso` prints a link and a one-time code. Open the link in the Windows browser, enter the code, and choose the lab account.

## 2. Set up your prefix and key

```bash
ibmcloud target -r us-south
export SEAT=<your-number>
export P=$(printf 'pvs-%02d' "$SEAT")
mkdir -p -m 700 ~/.ssh
test -f ~/.ssh/pvs-lab || \
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N "" -C "$P"
test -d ~/tz-lab-terraform-demo || \
  git clone https://github.com/greyhoundforty/tz-lab-terraform-demo.git \
    ~/tz-lab-terraform-demo
```

PowerVS accepts the RSA key at `~/.ssh/pvs-lab`. Terraform reads the public half, `~/.ssh/pvs-lab.pub`.

## 3. Create the API key

```bash
ibmcloud iam api-key-create "$P-tf" -d "LAB-1952 Terraform" \
  --file ~/.pvs-tf-apikey.json
chmod 600 ~/.pvs-tf-apikey.json
export IC_API_KEY=$(jq -r '.apikey' ~/.pvs-tf-apikey.json)
cat > ~/pvs-tf.env <<EOF
export SEAT="$SEAT" P="$P"
EOF
cp ~/pvs-tf.env ~/pvs-lab.env
```

The provider reads `IC_API_KEY`. The key stays out of the Terraform files. Delete it after class. `pvs-wait.py` only reads `~/pvs-lab.env`, so the copy above is what the wait games use.

## 4. First apply: VPC, PowerVS, and the transit gateway

Lab seats are not assigned the account Default group. List the groups, copy the **Name** (it looks like `eid-6ade1956dd7720b7023795b2`; `Default Group` is `false`), and save it.

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
ibmcloud resource groups
export RG_NAME="<group-name>"
echo "group: $RG_NAME"
echo "export RG_NAME=\"$RG_NAME\"" >> ~/pvs-tf.env
cp ~/pvs-tf.env ~/pvs-lab.env
cat > terraform.tfvars <<EOF
prefix              = "$P-tf"
region              = "us-south"
pi_zone             = "dal12"
resource_group_name = "$RG_NAME"
powervs_cidr        = "192.168.100.0/24"
aix_image_name      = ""
EOF
terraform init
terraform plan -out default.tfplan
```

`prefix` should read like `"pvs-07-tf"`, and `resource_group_name` should be your `eid-...` group. This plan is the initial run. It creates the VPC resources (VPC, subnet, SSH key, security-group rule, Ubuntu server, floating IP), the PowerVS resources (workspace, private network, public network, SSH key), and the transit gateway resources (gateway, a connection to each side, and a route for `192.168.100.0/24`). Names look like `pvs-07-tf-ws`. `aix_image_name` is empty, so this plan has no AIX server.

```bash
terraform apply default.tfplan
```

Allow 10 to 20 minutes. The workspace takes most of that. The VPC, Ubuntu server, and transit gateway build in the same run. Then:

```bash
terraform output
```

The workspace CRN, the Ubuntu addresses, and the name prefix are set. The AIX addresses are empty until the next apply.

```bash
terraform output -raw ubuntu_public_ip
```

## 5. Second apply: the AIX server

```bash
ibmcloud pi workspace target "$(terraform output -raw workspace_crn)"
export AIX_IMAGE=$(ibmcloud pi image list-catalog --json \
  | jq -r '[.images[] | select(.name | startswith("7300-"))]
           | sort_by(.name) | last | .name')
sed -i "s/^aix_image_name.*/aix_image_name = \"$AIX_IMAGE\"/" terraform.tfvars
grep aix_image_name terraform.tfvars
terraform plan -out default.tfplan
```

The image name looks like `7300-03-00`. The plan adds that image, the server on both networks (system type `s122`, 0.25 shared cores, 4 GB), and a route on AIX for each VPC prefix through `192.168.100.1`.

```bash
terraform apply default.tfplan
```

Allow 15 to 20 minutes. When it finishes:

```bash
export AIX_IP=$(terraform output -raw aix_public_ip)
echo "AIX public address: $AIX_IP"
terraform output aix_ip_address
```

`AIX_IP` is the public address the Fedora terminal can reach. `aix_ip_address` is the private address on `192.168.100.0/24`. The Ubuntu server reaches that private address across the transit gateway.

## 6. Reach AIX

Public path, from the Fedora terminal:

```bash
ibmcloud pi instance list
ibmcloud pi subnet list
ping -c 3 "$AIX_IP"
ansible --version
ANSIBLE_HOST_KEY_CHECKING=False ansible all -i "$AIX_IP," \
  -u root --private-key ~/.ssh/pvs-lab -m raw -a "oslevel -s"
ssh -i ~/.ssh/pvs-lab root@"$AIX_IP"
```

Ansible should print `CHANGED` and a level starting with `7300`. On the server:

```bash
oslevel -s
ifconfig -a | grep inet
netstat -rn | grep 10.240
exit
```

`ifconfig` shows the public address and a `192.168.100.x` private address. `netstat` shows the VPC prefixes routed through `192.168.100.1`.

Private path, from the Ubuntu server Terraform built in the first apply. Log in as `ubuntu` with the same key. The floating IP is how the lab machine reaches that server. From there, AIX's private address is reached across the transit gateway.

```bash
export VSI_IP=$(terraform output -raw ubuntu_public_ip)
export VSI_PRIV=$(terraform output -raw ubuntu_private_ip)
export AIX_PRIV=$(terraform output -raw aix_ip_address)
echo "VSI public:  $VSI_IP"
echo "VSI private: $VSI_PRIV"
ssh -i ~/.ssh/pvs-lab ubuntu@"$VSI_IP" hostname
ssh -i ~/.ssh/pvs-lab ubuntu@"$VSI_IP" "ping -c 3 $AIX_PRIV"
```

`hostname` should print the `-tf-vsi` name. Three ping replies mean traffic is crossing the transit gateway in both directions.

To log in to AIX through the Ubuntu server, use it as a jump host. `-i` on a `-J` command is applied only to AIX, so the Ubuntu server never receives the key and refuses the connection. `ProxyCommand` passes the key to both hops. The next commands run on AIX. `who am i` should show a `10.240.x.x` address, which is the Ubuntu server, not the lab machine. For the ping back, use the `VSI private` address printed above. Lab-machine variables do not exist on AIX.

```bash
ssh -i ~/.ssh/pvs-lab \
  -o ProxyCommand="ssh -i ~/.ssh/pvs-lab -W %h:%p ubuntu@$VSI_IP" \
  root@"$AIX_PRIV"
who am i
ping -c 3 <vsi-private-address>
exit
```

## If you open a new terminal

```bash
source ~/pvs-tf.env
export IC_API_KEY=$(jq -r '.apikey' ~/.pvs-tf-apikey.json)
ibmcloud target -r us-south
cd ~/tz-lab-terraform-demo/lab/terraform
```

State is on disk in that folder. Re-run the plan and apply for the step you were on.

## After class

```bash
source ~/pvs-tf.env
export IC_API_KEY=$(jq -r '.apikey' ~/.pvs-tf-apikey.json)
cd ~/tz-lab-terraform-demo/lab/terraform
terraform destroy
ibmcloud iam api-key-delete "$P-tf" -f
rm -f ~/.pvs-tf-apikey.json
```

`terraform destroy` asks you to type `yes`. PowerVS deletes are slow. Allow 20 minutes or more.
