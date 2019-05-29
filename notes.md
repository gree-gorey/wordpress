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


server {
  listen 80 default_server;
  listen [::]:80 default_server;

  root /var/www/html;
  server_name _;

  location / {
    try_files $uri $uri/ =404;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param REQUEST_METHOD $request_method;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass 127.0.0.1:9000;
  }
}
