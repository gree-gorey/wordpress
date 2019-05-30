## Challenges

* wp is stateful -> needs Read-Write-Many PV in Kubernetes
* 2

## Scaling

Note: wordpress Deployment Pods have 200m CPU limits -- that's intentionally for
the purposes of HPA demo: firstly, larger CPU limits just wouldn't fit into
local CPU limits when scaling up; and secondly, the lesser the limit the easier
to load CPU with calculations.

Horizontal Pod Autoscaler
Metrics:
* CPU 80%
* rps?

## Local limitations

* disabled metrics for mariadb
* nfs -> managed
* mysql -> managed

https://github.com/hipages/php-fpm_exporter
