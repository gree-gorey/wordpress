# Analysis

## Deliverables
### Docker images
* CI image for GitLab Jobs: [./images/ci](https://github.com/gree-gorey/wordpress/tree/master/images/ci/Dockerfile). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/ci).
* Load-test image for testing autoscaling of wordpress: [./images/load-test](https://github.com/gree-gorey/wordpress/tree/master/images/load-test/Dockerfile). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/load-test).
* WordPress image, contains additional `.php` files for config, health endpoint and cpu load simulation: [./images/wordpress](https://github.com/gree-gorey/wordpress/tree/master/images/ci/Dockerfile). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/wordpress).

### Kubernetes manifests / Helm charts
