#!/bin/bash
set -x
# Redirect all stdout (>) and stderr (2>&1) from this script 
# to a log file in the root user's home directory.
exec > /root/userdata.log 2>&1
echo "installing oci cli ..."
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults
echo "Sourcing .bashrc to update PATH for oci cli"
source /root/.bashrc
# Installing and Configuration kubectl and OCI
echo "installing kubectl ..."
apt update && sudo apt install -y curl apt-transport-https
snap install kubectl --classic
# echo "configuring kubectl ..."
# mkdir -p $HOME/.kube
# mv kubectl /usr/local/bin

echo "installing helm"
curl -O https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz
tar -xvf helm-v3.16.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin

echo "configuring oci-ingress-controller"
git clone https://github.com/oracle/oci-native-ingress-controller

oci ce cluster create-kubeconfig --cluster-id ${cluster-id} --file $HOME/.kube/config --region ${region} --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT


