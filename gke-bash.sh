#!/bin/bash

set -e

# Variables
PROJECT_ID="ljawn-se-lab"
ZONE="asia-southeast1-a"

# Decode and save the service account keyz
#echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" | base64 --decode > ${HOME}/gcloud-service-key.json

# Authenticate to GCP
#gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE


# Check if the network exists
if ! gcloud compute networks describe jl-gke-vpc &>/dev/null; then
  gcloud compute networks create jl-gke-vpc --subnet-mode=custom
else
  echo "Network jl-gke-vpc already exists."
fi

# Check if the subnet exists
if ! gcloud compute networks subnets describe my-subnet-asia-southeast1-a --region=asia-southeast1 &>/dev/null; then
  gcloud compute networks subnets create my-subnet-asia-southeast1-a \
      --network=jl-gke-vpc \
      --region=asia-southeast1 \
      --range=10.0.0.0/24
else
  echo "Subnet my-subnet-asia-southeast1-a already exists."
fi

if ! gcloud compute networks subnets describe my-subnet-asia-southeast1-b --region=asia-southeast1 &>/dev/null; then
  gcloud compute networks subnets create my-subnet-asia-southeast1-b \
      --network=jl-gke-vpc \
      --region=asia-southeast1 \
      --range=10.0.1.0/24
else
  echo "Subnet my-subnet-asia-southeast1-b already exists."
fi

# Check if the instance exists
if ! gcloud compute instances describe jawn-jumphost --zone=asia-southeast1-a &>/dev/null; then
  gcloud compute instances create jawn-jumphost \
      --project=ljawn-se-lab \
      --zone=asia-southeast1-a \
      --machine-type=e2-medium \
      --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=my-subnet-asia-southeast1-a \
      --tags=jawn-jumphost \
      --scopes=https://www.googleapis.com/auth/cloud-platform \
      --service-account=jl-gks-sa@ljawn-se-lab.iam.gserviceaccount.com
else
  echo "Instance jawn-jumphost already exists."
fi

# Get the public IP of the jumphost
JUMPHOST_IP=$(gcloud compute instances describe jawn-jumphost \
    --zone=asia-southeast1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Check if the GKE cluster existsz
if ! gcloud container clusters describe jl-gke-sg --zone=asia-southeast1-a &>/dev/null; then
  gcloud container clusters create jl-gke-sg \
      --enable-ip-alias \
      --network=jl-gke-vpc \
      --subnetwork=my-subnet-asia-southeast1-a \
      --enable-private-nodes \
      --master-ipv4-cidr=172.16.0.0/28 \
      --zone=asia-southeast1-a \
      --node-locations=asia-southeast1-a,asia-southeast1-b \
      --num-nodes=1 \
      --enable-master-authorized-networks \
      --master-authorized-networks=${JUMPHOST_IP}/32
else
  echo "GKE cluster jl-gke-sg already exists."
fi

# Check if the router exists
if ! gcloud compute routers describe nat-router --region=asia-southeast1 &>/dev/null; then
  gcloud compute routers create nat-router \
      --network=jl-gke-vpc \
      --region=asia-southeast1
else
  echo "Router nat-router already exists."
fi

# Check if the NAT configuration exists
if ! gcloud compute routers nats describe nat-config --router=nat-router --region=asia-southeast1 &>/dev/null; then
  gcloud compute routers nats create nat-config \
      --router=nat-router \
      --auto-allocate-nat-external-ips \
      --nat-all-subnet-ip-ranges \
      --region=asia-southeast1
else
  echo "NAT configuration nat-config already exists."
fi

# Check if the firewall rule exists, update 443
if ! gcloud compute firewall-rules describe allow-ssh-from-external &>/dev/null; then
  gcloud compute firewall-rules create allow-ssh-from-external \
      --network=jl-gke-vpc \
      --allow=tcp:22,tcp:443 \
      --source-ranges=0.0.0.0/0 \
      --target-tags=jawn-jumphost
else
  echo "Firewall rule allow-ssh-from-external already exists."
fi

if ! gcloud compute firewall-rules describe allow-internal-communication &>/dev/null; then
  gcloud compute firewall-rules create allow-internal-communication \
      --network=jl-gke-vpc \
      --allow=all \
      --source-ranges=10.0.0.0/16
else
  echo "Firewall rule allow-internal-communication already exists."
fi