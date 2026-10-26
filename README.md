# Power Virtual Server lab

Work in IBM Cloud Shell, or in a terminal on your workstation. Sign in at [cloud.ibm.com](https://cloud.ibm.com), switch to the lab account, and open Cloud Shell from the top bar.

Terraform builds a PowerVS workspace and an AIX 7.3 server in two applies. The CLI creates the API key, picks the AIX image, and checks the result. Seat 7 is used below as the example. Your names will follow your own seat number.

| | |
|---|---|
| Prefix | `pvs-07`, written into Terraform as `pvs-07-tf` |
| Region | `us-south`, PowerVS zone `dal12` |
| Private network | `192.168.100.0/24` |
| Server | AIX 7.3, system type `s122`, on the private and public networks |

Leave `vpc_name` unset. The first apply creates the workspace, private network, public network, and SSH key. The second apply creates the AIX server. Cloud Shell reaches it on the public address.

## 1. Set up

```bash
ibmcloud plugin install power-iaas -f
ibmcloud target -r us-south
export SEAT=<your-number>
export P=$(printf 'pvs-%02d' "$SEAT")
mkdir -p -m 700 ~/.ssh
test -f ~/.ssh/pvs-lab || \
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N "" -C "$P"
terraform version
test -d ~/tz-lab-terraform-demo || \
  git clone https://github.com/greyhoundforty/tz-lab-terraform-demo.git \
    ~/tz-lab-terraform-demo
```

`terraform version` needs 1.5 or newer. PowerVS accepts the RSA key at `~/.ssh/pvs-lab`. Terraform reads the public half, `~/.ssh/pvs-lab.pub`.

## 2. Create the API key

```bash
ibmcloud iam api-key-create "$P-tf" -d "LAB-1952 Terraform" \
  --file ~/.pvs-tf-apikey.json
chmod 600 ~/.pvs-tf-apikey.json
export IC_API_KEY=$(jq -r '.apikey' ~/.pvs-tf-apikey.json)
cat > ~/pvs-tf.env <<EOF
export SEAT="$SEAT" P="$P"
EOF
```

The provider reads `IC_API_KEY`. The key stays out of the Terraform files. Delete it after class.

## 3. First apply: workspace, networks, and key

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
cat > terraform.tfvars <<EOF
prefix         = "$P-tf"
region         = "us-south"
pi_zone        = "dal12"
powervs_cidr   = "192.168.100.0/24"
aix_image_name = ""
EOF
terraform init
terraform plan -out default.tfplan
```

`prefix` should read like `"pvs-07-tf"`. The plan lists the workspace, private network, public network, and SSH key. Names look like `pvs-07-tf-ws`. `aix_image_name` is empty, so this plan has no AIX server.

```bash
terraform apply default.tfplan
```

Allow 10 to 20 minutes, mostly for the workspace. Then:

```bash
terraform output
```

The workspace CRN and the name prefix are set. The AIX addresses are empty until the next apply.

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

The image name looks like `7300-03-00`. The plan adds that image and the server: both networks, system type `s122`, 0.25 shared cores, 4 GB.

```bash
terraform apply default.tfplan
```

Allow 15 to 20 minutes. When it finishes:

```bash
export AIX_IP=$(terraform output -raw aix_public_ip)
echo "AIX public address: $AIX_IP"
terraform output aix_ip_address
```

`AIX_IP` is the public address Cloud Shell can reach. `aix_ip_address` is the private address on `192.168.100.0/24`.

## 5. Reach AIX

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
exit
```

`ifconfig` shows the public address and a `192.168.100.x` private address.

## If Cloud Shell drops

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
