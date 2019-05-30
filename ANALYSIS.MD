# Analysis

## Deliverables
### Docker images
* CI image for GitLab Jobs: [./images/ci](https://github.com/gree-gorey/wordpress/tree/master/images/ci). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/ci).
* Load-test image for testing autoscaling of wordpress: [./images/load-test](https://github.com/gree-gorey/wordpress/tree/master/images/load-test). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/load-test).
* WordPress image, contains additional `.php` files for config, health endpoint and cpu load simulation: [./images/wordpress](https://github.com/gree-gorey/wordpress/tree/master/images/wordpress). This image on [DockerHub](https://cloud.docker.com/u/greegorey/repository/docker/greegorey/wordpress).

### Kubernetes manifests / Helm charts
#### Manifests
* Under the [./manifests](https://github.com/gree-gorey/wordpress/tree/master/manifests) directory there are simple Kubernetes manifests:

  * `namespace.yaml` -- for creating namespace `wp`
  * `load-test-deployment.yaml` -- for creating Deployment which is aimed to load wordpress app with a large number of CPU-sensitive requests
  * `hpa.yaml` -- for creating Horizontal Pod Autoscaler for WordPress (details below)

#### Helm-charts
* Under the [./charts](https://github.com/gree-gorey/wordpress/tree/master/charts) directory there are more complex charts for deploying of Kubernetes applications. *NOTE*: I don't use Tiller; only use Helm for templating manifests, then `kubectl apply`'ing them. Charts are:

  * `mariadb` -- just `stable/mariadb` Chart with my custom values. Using master + slave replication for HA and redundancy
  * `metrics-server` -- `stable/metrics-server` Chart with my custom values. Used for autoscaling based on resource metrics (e.g. CPU load)
  * `nfs-server-provisioner` -- `stable/nfs-server-provisioner` Chart with my custom values. RWX storage is a requirement for using WordPress in replicated mode due to its stateful nature (discussion below). This chart provides local NFS-server
  * `wordpress` -- Chart for WordPress app. This one is created by me and contains of the following templates:

    * `configmap.yaml` -- contains Nginx config file
    * `deployment.yaml` -- Deployment with Pod consisting of two containers: 1) my `greegorey/wordpress:1.0.0` image with WordPress files and PHP-FPM and 2) `nginx:1.15-alpine` for serving the requests (implementation details below)
    * `ingress.yaml` -- optional ingress object
    * `nfs-pvc.yaml` -- claim for NFS volume for sharing files between WordPress replicas
    * `secret.yaml` -- contains password for database
    * `service.yaml` -- service object with 80 port for nginx inside the Pod
