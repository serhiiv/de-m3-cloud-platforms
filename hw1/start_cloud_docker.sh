#!/bin/bash

if [[ "$GCP_PROJECT" == "" ]] || [[ "$GCP_REGION" == "" ]] ;
then
  echo "Environment variables GCP_REGION or GCP_PROJECT not set";
  exit;
else
    echo "GCP_REGION=$GCP_REGION"
    echo "GCP_PROJECT=$GCP_PROJECT"
fi


# export GCP_REPO="de-m3-cloud"
# export GCP_IMAGE="sample-web-api"

GCP_REPO="de-m3-cloud"
GCP_IMAGE="sample-web-api"


# Create a Docker repository
gcloud artifacts repositories create ${GCP_REPO} --repository-format=docker \
    --location=${GCP_REGION} --project=${GCP_PROJECT}

# name of the image 
# export IMAGE=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GCP_REPO}/${GCP_IMAGE}:latest
IMAGE=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GCP_REPO}/${GCP_IMAGE}:latest

# Build the image:
docker build -t ${IMAGE}  --platform linux/x86_64 .

# Push it to Artifact Registry:
docker push ${IMAGE}

# list the repositories
gcloud artifacts repositories list --project=${GCP_PROJECT}

# deploy the image to Cloud Run
gcloud run deploy sample-web-api --platform managed --region ${GCP_REGION} --allow-unauthenticated \
--image ${IMAGE}
