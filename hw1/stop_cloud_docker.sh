#!/bin/bash

# Stop the cloud docker container
gcloud run services delete sample-web-api

# To delete the repository
GCP_REPO="de-m3-cloud"
gcloud artifacts repositories delete ${GCP_REPO} --location=${GCP_REGION}
