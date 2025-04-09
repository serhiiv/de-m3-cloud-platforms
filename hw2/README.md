# Deploy the Docker container to Google Cloud Run.

### Presets

Install docker and gcloud


```bash
# set
export GCP_PROJECT=<project_id>
export GCP_REGION=<region_name>
```
Start project

```bash
start_cloud_docker.sh
```

Delete project

```bash
stop_cloud_docker.sh
```

### Links

- [Store Docker container images in Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/store-docker-container-images?_gl=1*1iyylbr*_ga*ODQxODUzNzk0LjE3MjUzNTQ0ODQ.*_ga_WH2QY8WWF5*MTc0MjkyNDgxNy4zMzguMS4xNzQyOTI4NzQ2LjU1LjAuMA..#gcloud) 
