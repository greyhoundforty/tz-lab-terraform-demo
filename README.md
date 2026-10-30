# Power Virtual Server lab

Open IBM Cloud Shell from the IBM Cloud console. Both the CLI track and the Terraform + CLI track start with the same Cloud Shell setup. From step 2 onward they diverge.

Terraform builds a PowerVS workspace and an AIX 7.3 server in two applies. The CLI creates the API key, picks the AIX image, and checks the result. Seat 7 is used below as the example. Your names will follow your own seat number.

| | |
|---|---|
| Prefix | `pvs-07`, written into Terraform as `pvs-07-tf` |
| Region | `us-south`, PowerVS zone `dal12` |
| Private network | `192.168.100.0/24` |
| Server | AIX 7.3, system type `s122`, on the private and public networks |

The first apply creates the workspace, both PowerVS networks, the SSH key, a VPC, an Ubuntu server, and a transit gateway between them. The second apply creates the AIX server and a route so the Ubuntu server can reach AIX on its private address. Cloud Shell reaches AIX on the public address.

## 1. Set up Cloud Shell

Sign in at [cloud.ibm.com](https://cloud.ibm.com), switch to the lab account, and open Cloud Shell. It is already logged in as you.

```bash
ibmcloud plugin install power-iaas -f
ibmcloud plugin install vpc-infrastructure -f
ibmcloud plugin install tg-cli -f
for c in pi is tg; do
  ibmcloud $c help >/dev/null 2>&1 \
    && echo "ibmcloud $c OK" || echo "ibmcloud $c MISSING"
done
ibmcloud target -r us-south
ibmcloud resource groups
export RG_NAME="<group-name>"
ibmcloud target -g "$RG_NAME"
export RG_ID=$(ibmcloud resource group "$RG_NAME" --id)
export SEAT=<your-number>
export P=$(printf 'pvs-%02d' "$SEAT")
echo "prefix=$P  group=$RG_ID"
mkdir -p -m 700 ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N "" -C "$P"
cat >> ~/.ssh/config <<EOF
Host *
  IdentityFile ~/.ssh/pvs-lab
  StrictHostKeyChecking accept-new
EOF
chmod 600 ~/.ssh/config
curl -fsSLO \
https://raw.githubusercontent.com/emaadparacha/ibm-techxchange-2026/main/pvs-wait.py
python3 pvs-wait.py --help
cat > ~/pvs-lab.env <<EOF
export SEAT="$SEAT" P="$P" RG_NAME="$RG_NAME" RG_ID="$RG_ID"
EOF
```

You want three `OK` plugin lines, a prefix that matches your seat, and the wait-script help text. TechZone accounts are not assigned the Default group; use the listed `eid-...` name for `$RG_NAME`.

## 2. Get the Terraform code and create the API key

```bash
terraform version
test -d ~/tz-lab-terraform-demo || \
  git clone https://github.com/greyhoundforty/tz-lab-terraform-demo.git \
    ~/tz-lab-terraform-demo
ls ~/tz-lab-terraform-demo/lab/terraform
ibmcloud iam api-key-create "$P-tf" -d "LAB-1952 Terraform" \
  --file ~/.pvs-tf-apikey.json
chmod 600 ~/.pvs-tf-apikey.json
export IC_API_KEY=$(jq -r '.apikey' ~/.pvs-tf-apikey.json)
cp ~/pvs-lab.env ~/pvs-tf.env
```

The provider reads `IC_API_KEY`. The key stays out of the Terraform files. Delete it after class. Step 1 already wrote `~/pvs-lab.env` for `pvs-wait.py`. The copy gives the Terraform track its own file if you also run the CLI track.

## 3. First apply: VPC, PowerVS, and the transit gateway

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
cat > terraform.tfvars <<EOF
prefix              = "$P-tf"
region              = "us-south"
pi_zone             = "dal12"
resource_group_name = "$RG_NAME"
powervs_cidr        = "192.168.100.0/24"
aix_image_name      = ""
EOF
terraform init
```

Check the code before you plan:

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
terraform fmt -check -recursive
terraform validate
```

`terraform fmt -check` only lists unformatted files, and exits 0 when all are clean and non-zero when any are not. Run `terraform fmt` without `-check` to rewrite them. `terraform validate` needs `terraform init` first and checks syntax and the provider schema without calling IBM Cloud or needing `IC_API_KEY`.

Expect no output from `fmt -check`, and `Success! The configuration is valid.` from `validate`. If either check fails, fix what it names before you plan.

```bash
terraform plan -out default.tfplan
```

`prefix` should read like `"pvs-07-tf"`, and `resource_group_name` should match the group from step 1. This plan is the initial run. It creates the VPC resources (VPC, subnet, SSH key, security-group rule, Ubuntu server, floating IP), the PowerVS resources (workspace, private network, public network, SSH key), and the transit gateway resources (gateway, a connection to each side, and a route for `192.168.100.0/24`). Names look like `pvs-07-tf-ws`. `aix_image_name` is empty, so this plan has no AIX server.

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

## 4. Second apply: the AIX server

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

`AIX_IP` is the public address Cloud Shell can reach. `aix_ip_address` is the private address on `192.168.100.0/24`. The Ubuntu server reaches that private address across the transit gateway.

## 5. Reach AIX

Public path, from Cloud Shell:

```bash
ibmcloud pi instance list
ibmcloud pi subnet list
ping -c 3 "$AIX_IP"
ansible --version || pip3 install --user ansible-core
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

Private path, from the Ubuntu server Terraform built in the first apply. Log in as `ubuntu` with the same key. The floating IP is how Cloud Shell reaches that server. From there, AIX's private address is reached across the transit gateway.

```bash
export VSI_IP=$(terraform output -raw ubuntu_public_ip)
export VSI_PRIV=$(terraform output -raw ubuntu_private_ip)
export AIX_PRIV=$(terraform output -raw aix_ip_address)
echo "VSI public:  $VSI_IP"
echo "VSI private: $VSI_PRIV"
ssh ubuntu@"$VSI_IP" hostname
ssh ubuntu@"$VSI_IP" "ping -c 3 $AIX_PRIV"
```

`hostname` should print the `-tf-vsi` name. Three ping replies mean traffic is crossing the transit gateway in both directions.

To log in to AIX through the Ubuntu server, use it as a jump host. The `~/.ssh/config` from step 1 gives both hops your lab key. The next commands run on AIX. `who am i` should show a `10.240.x.x` address, which is the Ubuntu server, not Cloud Shell. For the ping back, use the `VSI private` address printed above. Cloud Shell variables do not exist on AIX.

```bash
ssh -J ubuntu@"$VSI_IP" root@"$AIX_PRIV"
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
