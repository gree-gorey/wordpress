# Analysis

This document consists of thee parts:
1. [Deliverables](#1-deliverables), where I describe the layout of this repo and all the code it contains.
2. [Walkthrough](#2-walkthrough), where I walk you through the deployment of the app and all the components, as well as demo of load-testing and autoscaling.
3. [Discussion](#3-discussion), where I discuss all the work I've done; why I choose these solutions and what is need to be improved/done differently in production environment.

## 1. Deliverables
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

### GitLabCI pipeline
The pipeline is here: [./.gitlab-ci.yml](https://github.com/gree-gorey/wordpress/tree/master/.gitlab-ci.yml). It is documented inside and it's valid GitLab ci file. But I didn't use it locally and it wouldn't work all the way because of the limitations (e.g. no access to my DockerHub auth to push built image).  
In order to automate the deployment locally I created a simple bash script `deploy-local.sh` (details below).

## 2. Walkthrough

### My local env:
Kubectl version: `v1.14.0`  
Helm client version: `v2.14.0`  
Docker version: `19.03.0-beta3`  
Kubernetes: `v1.14.1` (built-in from Docker for Mac)  
Kubernetes node capacity: `cpu: 2; memory: 6100628Ki (6GiB)`

### Deploy

The deployment script assumes the following:
* you are running this script from the root of the repo
* you have `kubectl` and `helm` client installed
* you have valid `~/.kube/config` file or you have `$KUBECONFIG` env variable pointing to the right config
* you have the StorageClass object named `hostpath` (default with Docker for Mac). If not, the manifest is under the `./manifests/storage-class.yaml`

*Disclaimer*: `deploy-local.sh` script has "secret" variables with passwords -- this is for local development only. Of course, in production these variables come from safe location.

1. Run the `deploy-local.sh`. What it does:
* creates namespace `wp`
* deploys metrics-server to `kube-system` namespace
* deploys nfs-server-provisioner to `kube-system` namespace
* deploys database to `wp` namespace
* deploys wordpress tp `wp` namespace

2. Check that you have the apps running:
```console
$ kubectl get po -n kube-system -l 'app in (nfs, metrics-server)'
output
$ kubectl get po -n wp
o
```

3. Now we can use `port-forward` to see the application UI:
```console
$ kubectl port-forward -n wp svc/wordpress 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

4. Open http://127.0.0.1:8080 in the browser and you can perform initial setup for WordPress.

## 3. Discussion

* https
