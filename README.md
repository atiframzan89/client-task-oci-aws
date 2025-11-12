# Installing oci cli
```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults
```
# Installing and Configuration kubectl and OCI
```bash
sudo apt update && sudo apt install -y curl apt-transport-https
snap install kubectl --classic
```
create the directory for kubectl
```bash
mkdir -p $HOME/.kube
```
you need to configure the oci cli using the below command
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
$ oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.me-jeddah-1.aaaaaaaamwpwzqob3tyct3mjssmjqploylofcjkb5rke3ofudc3cm5kglgsa --file $HOME/.kube/config --region me-jeddah-1 --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT
New config written to the Kubeconfig file /root/.kube/config
```
Now you will be able to access the cluster using kubectl
```bash
$ kubectl get nodes -A
NAME         STATUS   ROLES   AGE     VERSION
10.0.3.114   Ready    node    5h33m   v1.31.1
10.0.3.68    Ready    node    5h33m   v1.31.1
```
# Installing OCI Native Ingress Controller
Before installation you need to install cert-manager
```bash
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```
# Installing OCI Native Ingress Controller
helm install oci-lb-controller oracle/oci-lb-controller \
  --namespace oci-lb-controller \
  --set serviceAccount.create=true \
  --set region="me-jeddah-1" \
  --set leaderElection.enabled=true \
  --set loadBalancer.securityListManagementMode=All

