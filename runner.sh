#!/bin/bash
## if config folder doesn't exist, create it
# [ ! -d "/config_files" ] && mkdir /config_files
## copy default files if config folder is empty
if [ -z "$(ls -A /config_files)" ]; then
    cp /usr/lib/motley-cue/etc/motley_cue/* /config_files
    cp /usr/lib/motley-cue/etc/nginx/nginx.motley_cue /config_files
fi
## set env vars from motley_cue.env
set -e
export $(grep -v '^#' /etc/motley_cue/motley_cue.env | xargs)
env

/usr/lib/motley-cue/bin/gunicorn motley_cue.api:api \
    -k "uvicorn.workers.UvicornWorker" \
    --config /etc/motley_cue/gunicorn.conf.py \
    --access-logfile "-" --error-logfile "-" &
/usr/sbin/sshd -D -e
wait -n