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
#gcloud services enable serviceusage.googleapis.com
#gcloud services enable container.googleapis.com
#gcloud services enable compute.googleapis.com

# this will delete the firewall rules
gcloud compute firewall-rules list --project=ljawn-se-lab
gcloud compute firewall-rules delete allow-ssh-from-external --project=ljawn-se-lab -quiet
gcloud compute firewall-rules delete allow-internal-communication --project=ljawn-se-lab -quiet

# this will delete the whole nat routre including the nat config
gcloud compute routers delete nat-router \
    --region=asia-southeast1 --quiet

# this will delete the jumphost
gcloud compute instances delete jumphost \
    --project=ljawn-se-lab \
    --zone=asia-southeast1-a --quiet

# this will delete the GKE cluster
gcloud container clusters delete jl-gke-sg \
    --zone=asia-southeast1-a --quiet

# this will delete the VPC including the subnets
gcloud compute networks subnets delete my-subnet-asia-southeast1-a \
    --region=asia-southeast1 --quiet
gcloud compute networks subnets delete my-subnet-asia-southeast1-b \
    --region=asia-southeast1 --quiet
gcloud compute networks delete jl-gke-vpc --quiet