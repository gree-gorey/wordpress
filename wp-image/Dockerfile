FROM alpine/git:1.0.7 AS clone
RUN mkdir -p /repo
RUN git clone --progress --branch='5.2.1' \
    --single-branch --depth=1 \
    https://github.com/WordPress/WordPress.git /repo

FROM php:7.2-fpm-alpine3.8
RUN mkdir -p /wp-files
COPY --from=clone /repo /wp-files
ADD ./wp-config.php /wp-files/
RUN docker-php-ext-install mysqli
EXPOSE 9000
CMD ["php-fpm"]

# bitnami/wordpress-nginx
