#!/bin/bash
set -x
# --- THIS IS THE NEW LINE ---
# Redirect all stdout (>) and stderr (2>&1) from this script 
# to a log file in the root user's home directory.
exec > /root/userdata.log 2>&1

yum update -y
yum install mariadb -y