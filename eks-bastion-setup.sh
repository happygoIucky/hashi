#!/bin/bash


#Bastion Host in AWS
# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# install aws cli v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/bin/aws

# Install aws-iam-authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/local/bin

# Configure AWS CLI & key in your access key and secrets
aws configure

# Update kubeconfig & modify your region and cluster name
aws eks update-kubeconfig --region ap-southeast-1 --name jl-eks-sg

# Install Consul via Helm 
curl -O https://raw.githubusercontent.com/hashicorp-education/learn-consul-get-started-kubernetes/main/self-managed/eks/helm/values-v1.yaml
helm install --values values-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "1.2.0"
- It will install the injection, server and webhook pods