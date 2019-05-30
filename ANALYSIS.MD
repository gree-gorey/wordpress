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
  * `wordpress` -- Chart for WordPress app. This one is created by me and contains the following templates:

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
* you are running this script from the root of this repo
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
metrics-server-7f6b4744c-tlp6s   1/1     Running   0          47s
nfs-0                            1/1     Running   0          45s
$ kubectl get po -n wp
NAME                        READY   STATUS    RESTARTS   AGE
mariadb-master-0            1/1     Running   0          3m34s
mariadb-slave-0             1/1     Running   0          3m34s
mariadb-slave-1             1/1     Running   0          2m24s
wordpress-f8dcf7d8d-96n8p   2/2     Running   0          3m33s
```

3. Now we can use `port-forward` to see the application UI:
```console
$ kubectl port-forward -n wp svc/wordpress 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

4. Open http://127.0.0.1:8080 in the browser and you can perform initial setup for WordPress.

### Autoscaling demo

1. Let's lower cpu requests and limits of wordpress deployment down to 100m:
```console
$ kubectl patch -n wp deploy wordpress --patch "$(cat manifests/patch-cpu-limits.yaml)"
deployment.extensions/wordpress patched
```

2. Deploy Horizontal Pod Autoscaler:
```console
$ kubectl apply -n wp -f manifests/hpa.yaml
horizontalpodautoscaler.autoscaling/wordpress-hpa created
```

3. After some time you can see the (low) resource consumption:
```console
$ kubectl get -n wp hpa wordpress-hpa
NAME            REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
wordpress-hpa   Deployment/wordpress   1%/70%    1         5         1          1m57s
```

4. Now deploy the load-test Deployment. It contains a client that requests `/simulate-cpu-load.php` of our wordpress app making it consume cpu:
```console
$ kubectl apply -n wp -f manifests/load-test-deployment.yaml
deployment.apps/load-test created
```

5. After some small time you can see that CPU consumption of wordpress pod increases:
```console
$ kubectl top po -n wp -l app=wordpress --containers
POD                          NAME        CPU(cores)   MEMORY(bytes)   
wordpress-7b79f7f484-c74x5   wordpress   100m         10Mi            
wordpress-7b79f7f484-c74x5   nginx       1m           1Mi

$ kubectl get hpa -n wp wordpress-hpa
NAME            REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
wordpress-hpa   Deployment/wordpress   91%/70%   1         5         2          18m
```
And HPA increases the replicas of wordpress:
```console
$ kubectl get po -n wp -l app=wordpress
NAME                         READY   STATUS    RESTARTS   AGE
wordpress-7b79f7f484-6wz8r   2/2     Running   0          84s
wordpress-7b79f7f484-c74x5   2/2     Running   0          3m3s

$ kubectl top po -n wp -l app=wordpress --containers
POD                          NAME        CPU(cores)   MEMORY(bytes)   
wordpress-7b79f7f484-6wz8r   wordpress   69m          10Mi            
wordpress-7b79f7f484-6wz8r   nginx       1m           1Mi             
wordpress-7b79f7f484-c74x5   wordpress   42m          10Mi            
wordpress-7b79f7f484-c74x5   nginx       1m           1Mi

$ kubectl get hpa -n wp wordpress-hpa
NAME            REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
wordpress-hpa   Deployment/wordpress   51%/70%   1         5         2          20m
```
6. Scale down the load-test Deployment to 0 and watch that HPA scale-down the wordpress:
```console
$ kubectl scale deployment -n wp load-test --replicas=0
deployment.extensions/load-test scaled

$ kubectl top po -n wp -l app=wordpress --containers
POD                          NAME        CPU(cores)   MEMORY(bytes)   
wordpress-7b79f7f484-6wz8r   wordpress   1m           10Mi            
wordpress-7b79f7f484-6wz8r   nginx       1m           1Mi             

$ kubectl get hpa -n wp wordpress-hpa
NAME            REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
wordpress-hpa   Deployment/wordpress   1%/70%    1         5         1          32m

$ kubectl get po -n wp -l app=wordpress
NAME                         READY   STATUS    RESTARTS   AGE
wordpress-7b79f7f484-c74x5   2/2     Running   0          9m54s
```

## 3. Discussion

First of all, WordPress is quite a complicated application to run in Kubernetes. It's stateful, meaning that you should share the files that user can upload there through UI between the replicas -- that making the replication difficult. One of the solutions is to use Write-Read-Many volumes for those files, e.g. it can be done with NFS. For the simplicity of local development and demo purposes I didn't mount nfs volumes into `/var/www/html` -- it would slow down the whole process. I just used emptyDir to share these files between nginx container and wordpress container.  
Ideally, all the static files should go to CDN, or at least to s3 and just served by nginx or other reverse-proxy. All the code (static php-files) should be build into container image on build stage. All the dynamic content (user uploads, dynamic modules) should go to RWX volumes shared between all the replicas.

### What to change on production
* if we had to use NFS, I would go for managed solution, like AWS EFS
* I would use managed SQL instead of mariadb in k8s cluster. It is scalable and HA right now, but it's better to use managed db if possible
* add https. At least with LetsEncrypt certificates. (not possible locally because you need at least DNS for that)
* I disabled metrics for mariadb because of short resources. They should be enabled in production and can be used for scaling of the database
* of course, HPA without cluster autoscaler is of little use. E.g. on GKE it's built-in, on other clouds I would deploy this chart: https://github.com/helm/charts/tree/master/stable/cluster-autoscaler

#### Horizontal Pod Autoscaler
Right now it's using only CPU utilisation of pods; but we could use some more http specific metrics, e.g. rps or latency.  
I would expand HPA with custom metrics like this:
```yaml
spec:
  metrics:
  - type: Pods
    pods:
      metricName: wordpress_latency_ms
      targetAverageValue: 100
```
For this to work we need additionaly 3 things:
* exporter to export these kind of metrics from our app, e.g. https://github.com/hipages/php-fpm_exporter
* Prometheus server to collect them: https://github.com/helm/charts/tree/master/stable/prometheus
* and adapter allowing to use HPA with custom metrics: https://github.com/helm/charts/tree/master/stable/prometheus-adapter
