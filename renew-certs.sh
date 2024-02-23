#!/bin/bash

cd /home/webssh-oidc/motley_cue_docker && \
    docker-compose run --rm certbot renew --webroot --webroot-path /var/www/certbot && \
    docker-compose exec nginx nginx -s reload
