#!/bin/bash
set -x
# Redirect all output to a log file for debugging
exec > /var/log/jenkins-user-data.log 2>&1

echo "--- Starting Jenkins User Data Script ---"


echo "Updating packages..."
apt-get update -y

echo "Installing Java (OpenJDK 17)..."
apt-get install -y openjdk-17-jdk


echo "Adding Jenkins GPG key..."
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo "Adding Jenkins repository..."
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null


echo "Updating packages again..."
apt-get update -y

echo "Installing Jenkins..."
apt-get install -y jenkins


echo "Enabling and starting Jenkins..."
systemctl enable jenkins
systemctl start jenkins



echo "--- Jenkins installation complete ---"