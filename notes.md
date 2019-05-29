## Challenges

* wp is stateful -> needs Read-Write-Many PV in Kubernetes
* 2

## Scaling

Horizontal Pod Autoscaler
Metrics:
* CPU 80%
* rps?

## Local limitations

* disabled metrics for mariadb
* nfs -> managed
* mysql -> managed

https://github.com/hipages/php-fpm_exporter

wordpress_files:/var/www/html

10Mil

for($i = 0; $i < 10000000; $i++) {
     $a += $i;
}
