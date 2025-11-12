# Terraform Execution
For terraform execution you need to have terraform installed in your local machine. The resources provisioning for each cloud is mentioned folder. I have used AWS and OCI
There are two folders AWS and OCI. Resource provisioing through terraform is handled in each of the folder.

## Step-1

You need to create two `dev.tfvars` in each (OCI and AWS) of the config folders.
`aws/config/dev.tfvars`
```yaml
region = "<region>"
vpc = {
    #name = "vpc"
    cidr                    = "13.20.0.0/16"
    public_subnet           = ["13.20.1.0/24", "13.20.2.0/24", "13.20.3.0/24" ]
    private_subnet          = ["13.20.4.0/24", "13.20.5.0/24", "13.20.6.0/24" ]
}
customer                    = "console"
environment                 = "dev"
# db-instance-size            = "db.t3.medium"
keypair                     = <keypair>
profile                     = "default"
mysql-admin-user            = "admin"
```
`oci/config/dev.tfvars`
```yaml
customer            = "manafa"
region              = "me-jeddah-1"
tenancy-ocid        = "<tenancy-id>"
user-ocid           = "<user-id>"

availability_domain = "AD-1"
ssh-public-key      = ""
instance_shape      = "VM.Standard.E2.1" # change if needed
# Optional: to override selection if you want to hardcode image OCID
compartment-ocid    = "<compartment-id>"
environment         = "dev"
```
For backend configuration you create the backend.tf file in each of the folders and paste the below code
```bash
terraform {
  backend "s3" {
    bucket = "bucket-name"
    key    = "terraform.tfstate"
    region = "region"
    profile = "default"
  }
}
```
Once you set the above files. You need to execute the terraform for AWS while going to AWS folder and same for oci

### For OCI
```bash
$ cd oci
$ terraform init
$ terraform validate
$ terraform apply --var-file=./config/dev.tfvars
```

### For AWS
```bash
$ cd aws
$ terraform init
$ terraform validate
$ terraform apply --var-file=./config/dev.tfvars
```
Please make sure to execute this one by one. Not at the same time

# Steps for Private Instance (Handled in Terraform)

## Installing oci cli
```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults
```
## Installing and Configuration kubectl and OCI (Handled in Terraform)
```bash
sudo apt update && sudo apt install -y curl apt-transport-https
snap install kubectl --classic
```
create the directory for kubectl
```bash
mkdir -p $HOME/.kube
```
> [!NOTE]
> The below oci cli steps you need to configure it manually
You need to configure the oci cli using the below command
```bash
oci setup config
Enter a location for your config [/root/.oci/config]:
Enter a user OCID: <get this from the oci console --> User Settings>
Do you want to generate a new API Signing RSA key pair? (If you decline you will be asked to supply the path to an existing key.) [Y/n]: Y
Enter a directory for your keys to be created [/root/.oci]: 
Enter a name for your key [oci_api_key]: 
Public key written to: /root/.oci/oci_api_key_public.pem
Enter a passphrase for your private key ("N/A" for no passphrase): 
Repeat for confirmation: 
Private key written to: /root/.oci/oci_api_key.pem
Fingerprint: 44:c5:08:3a:dd:6f:08:8f:32:92:25:84:fe:77:61:ea
Config written to /root/.oci/config
```

Then you need to paste the content of `~/.oci/oci_api_key_public.pem` and add it your user settings  --> Token and Keys --> Add API Key --> Paste Public key
Once you add it will provide you the config file that you can add in `~/.oci/config`

```bash
$ oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file $HOME/.kube/config --region <region> --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT
New config written to the Kubeconfig file /root/.kube/config
```
Now you will be able to access the cluster using kubectl
```bash
$ kubectl get nodes -A
NAME         STATUS   ROLES   AGE     VERSION
10.0.3.114   Ready    node    5h33m   v1.31.1
10.0.3.68    Ready    node    5h33m   v1.31.1
```
# Installing cert-manager for OCI Native Ingress Controller
Before installation you need to install cert-manager 
```bash
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```
# Installing OCI Native Ingress Controller
I am not able to find the helm chart for this thats why not able to use in terraform as well. In the private I have cloned the userdata script of oci-private instance
You need to do the below steps to install the loadbalancer controller.
```bash
$ cd /oci-native-ingress-controller/helm/oci-native-ingress-controller
$ vi value.yaml
compartment_id: <compartment_id>
subnet_id: <public-subnet-id>
cluster_id: <oke-cluster-id>
region: <region>
```

```bash
helm install oci-lb-controller oracle/oci-lb-controller \
  --namespace oci-lb-controller \
  --set serviceAccount.create=true \
  --set region="me-jeddah-1" \
  --set leaderElection.enabled=true \
  --set loadBalancer.securityListManagementMode=All
```

But its not installing successfully as i need the below access. As per my understanding for these accesses we need to perform this on compartment level for which i dont have access.
```bash
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage network-load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage network-security-groups in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage security-lists in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use subnets in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use vnics in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use private-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage public-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to inspect vcns in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage certificates-family in compartment ${data.oci_identity_compartment.oke_compartment.name}",
"Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage ca-bundles in compartment ${data.oci_identity_compartment.oke_compartment.name}"
```


# Steps for Connectivity between OCI Mysql and AWS RDS

This is an advanced, multi-cloud procedure that involves networking and database administration. I'll provide the complete, step-by-step process.
This guide assumes you have the following prerequisites:
•	An OCI VCN with a private subnet (e.g., 10.0.0.0/16).
•	An OCI MySQL Database Service (MDS) instance running in that private subnet.
•	An AWS VPC with a private subnet (e.g., 10.10.0.0/16).
•	An AWS RDS MySQL instance (standalone, not a replica) running in that private subnet.
The most complex part is creating the Site-to-Site VPN. We will use the AWS-first approach, as it's easier to download a configuration file from AWS to configure OCI.
________________________________________
## Phase 1: AWS VPN Setup (Part 1)
We create the AWS side first, using a placeholder for the OCI IP, which we will fix later.
1.	Create a Virtual Private Gateway (VGW):
o	In the AWS VPC console, go to Virtual Private Gateways.
o	Click Create Virtual Private Gateway.
o	Give it a name and click Create.
o	Once created, select it, click Actions, and Attach to VPC. Choose your AWS VPC.
2.	Create a Customer Gateway (CGW):
o	Go to Customer Gateways.
o	Click Create Customer Gateway.
o	Give it a name.
o	For IP Address, enter a placeholder IP, such as 1.1.1.1. We will replace this later with the real OCI VPN IP.
o	Click Create.
3.	Create the Site-to-Site VPN Connection:
o	Go to Site-to-Site VPN Connections.
o	Click Create VPN Connection.
o	Target Gateway Type: Virtual Private Gateway. Select the VGW you created.
o	Customer Gateway: Existing. Select the CGW you just created (with the 1.1.1.1 IP).
o	Routing Options: Static.
o	Static IP Prefixes: Enter your OCI VCN CIDR (e.g., 10.0.0.0/16).
o	Click Create VPN Connection.
4.	Download the Configuration:
o	Wait for the VPN state to become "Available".
o	Select the VPN, click Download Configuration.
o	Vendor: Generic
o	Platform: Generic
o	Click Download. Open this file. You will need the IPs and pre-shared keys from it.

### Till here the automation is done through terraform

# Manual Steps
________________________________________
## Phase 2: OCI VPN Setup
Now, we use the downloaded file to build the OCI side.
1.	Create a Dynamic Routing Gateway (DRG):
o	In the OCI console, go to Networking > Dynamic Routing Gateway.
o	Click Create DRG. Give it a name and create it.
o	Once created, find its Attachments tab. Click Create VCN Attachment and attach it to your OCI VCN.
2.	Create OCI Customer-Premises Equipment (CPE):
o	Your downloaded AWS config file lists two tunnels. We must create two CPE objects.
o	Go to Networking > Customer-Premises Equipment.
o	Click Create CPE.
o	Name: AWS-Tunnel-1
o	CPE IP Address: From your downloaded file, find the "Outside IP Address" for Tunnel 1. This is the AWS public IP. Paste it here.
o	Vendor: Select others
o	Click Create.
o	Repeat this step to create a second CPE named AWS-Tunnel-2, using the "Outside IP Address" for Tunnel 2.
3.	Create the IPSec Connection (The VPN):
o	Go to Networking > IPSec Connections.
o	Click Create IPSec Connection.
o	Name: OCI-to-AWS-VPN
o	CPE: Select AWS-Tunnel-1.
o	DRG: Select the DRG you created.
o	Static Route: Enter your AWS VPC CIDR (e.g., 10.10.0.0/16).
o	Configure Tunnel 1:
	IKE Version: IKEv1 or IKEv2 (match your AWS config).
	Routing Type: Static.
	Pre-shared Key: From your downloaded file, copy the "Pre-Shared Key" for Tunnel 1.
o	Click + Another Tunnel.
o	Configure Tunnel 2:
	CPE: Select AWS-Tunnel-2.
	Routing Type: Static.
	Pre-shared Key: From the file, copy the "Pre-Shared Key" for Tunnel 2.
o	Click Create IPSec Connection.
4.	Get the OCI Public IPs:
o	Wait for the IPSec connection to be provisioned.
o	Click on it. You will see two Oracle VPN IP addresses listed for your tunnels. Copy these.
________________________________________
## Phase 3: Finalize VPN & Routing
1.	Fix the AWS Customer Gateway (CGW):
o	Go back to the AWS Console > Customer Gateways.
o	Delete the placeholder CGW you made.
o	Create a new CGW.
o	IP Address: Paste the OCI VPN IP for Tunnel 1.
o	Create a second CGW.
o	IP Address: Paste the OCI VPN IP for Tunnel 2.
o	Note: You may need to delete and re-create your AWS VPN Connection, this time linking to the two new, correct CGWs. This is the most complex part of multi-cloud networking.
2.	Configure OCI Route Table:
o	Go to your OCI VCN > Route Tables.
o	Select the route table for your MDS private subnet.
o	Click Add Route Rules.
o	Target Type: Dynamic Routing Gateway.
o	Destination CIDR: Your AWS VPC CIDR (e.g., 10.10.0.0/16).
o	Target: Select your DRG.
3.	Configure AWS Route Table:
o	Go to your AWS VPC > Route Tables.
o	Select the route table for your RDS private subnet.
o	Click the Routes tab > Edit routes.
o	Click Add route.
o	Destination: Your OCI VCN CIDR (e.g., 10.0.0.0/16).
o	Target: Virtual Private Gateway. Select your VGW.
o	Click Save changes.
4.	Configure Firewalls (Security Groups):
o	OCI Security List (for MDS): Add an Egress rule:
	Destination: 10.10.0.0/16 (Your AWS VPC CIDR)
	Protocol: TCP
	Destination Port: 3306
o	AWS Security Group (for RDS): Add an Ingress rule:
	Source: The Private IP of your OCI MDS instance (e.g., 10.0.5.100)
	Protocol: TCP
	Port Range: 3306
At this point, the tunnels should come "UP". You can check the "Tunnel Details" tab in both consoles.
________________________________________
## Phase 4: Database Configuration (Primary)
Now we configure the OCI MySQL database.
1.	Enable Binlog & GTID:
o	In the OCI Console, go to your MDS instance.
o	Click Configuration > Edit.
o	Ensure the following variables are set (or add them):
	gtid_mode = ON
	enforce_gtid_consistency = ON
	log_bin = ON
o	Save and restart the database.
2.	Create Sample Data:
o	Connect to your OCI MDS instance using your admin user and the private IP.
o	Run the following SQL to create sample data:
```SQL
SQL
CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;

CREATE TABLE IF NOT EXISTS employees (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE,
  hire_date DATE
);

INSERT INTO employees (first_name, last_name, email, hire_date) 
VALUES ('Alice', 'Smith', 'alice.smith@example.com', CURDATE());

INSERT INTO employees (first_name, last_name, email, hire_date) 
VALUES ('Bob', 'Johnson', 'bob.johnson@example.com', CURDATE());

COMMIT;
```
3.	Create Replication User:
o	Create a dedicated user for the AWS RDS replica. It's crucial to lock this user's host to the AWS VPC.
o	Run the following SQL on your OCI MDS:
```SQL
-- Replace with your AWS VPC CIDR
CREATE USER 'replica_user'@'10.10.%.%' IDENTIFIED BY 'MyS!s-a-Site-to-SiteVPN-is-Hard!';

-- Grant only the necessary replication permission
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'10.10.%.%';
FLUSH PRIVILEGES;
```
4.	Take a Backup:
o	From a machine that can access the OCI MDS private IP (like a bastion), take a full backup using mysqldump. This will capture the data and GTID position.
```bash
mysqldump -h [OCI_MDS_PRIVATE_IP] -u [your_admin_user] -p --all-databases --master-data=1 --single-transaction --gtid > backup.sql
```
________________________________________
## Phase 5: Start Replication (Secondary)
1.	Restore Backup to AWS RDS:
o	Transfer the backup.sql file to a machine that can access your AWS RDS instance (like an EC2 bastion in the AWS VPC).
o	Restore the backup to your (empty) AWS RDS instance:
o	mysql -h [AWS_RDS_ENDPOINT] -u [rds_admin_user] -p < backup.sql
2.	Configure RDS as Replica:
o	Connect to your AWS RDS instance as the admin user.
o	Use the special AWS stored procedure mysql.rds_set_external_master_gtid to start replication.
o	Note: This procedure replaces the old CHANGE MASTER TO command.
o	Run the following SQL on your AWS RDS instance:
```SQL
CALL mysql.rds_set_external_master_gtid(
    '[OCI_MDS_PRIVATE_IP]',     -- The Primary's private IP
    3306,                       -- The Primary's port
    'replica_user',             -- The replication user
    'MyS!s-a-Site-to-SiteVPN-is-Hard!', -- The user's password
    1                           -- Use GTID auto-position
);
```
3.	Start Replication:
o	CALL mysql.rds_start_replication;
4.	Verify Replication:
o	SHOW REPLICA STATUS\G
o	Look for:
	Replica_IO_Running: Yes
	Replica_SQL_Running: Yes
	Seconds_Behind_Master: 0
o	The connection should be stable, as it's now running over your private VPN.
5.	Final Test:
o	Insert a new row on your OCI MDS primary: INSERT INTO company_db.employees (first_name, last_name, email, hire_date) VALUES ('Charlie', 'Brown', 'charlie@example.com', CURDATE());
o	Within seconds, query your AWS RDS replica: SELECT * FROM company_db.employees WHERE first_name = 'Charlie';
o	The row should appear.


