#!/bin/bash
set -e
export $(grep -v '^#' /etc/motley_cue/motley_cue.env | xargs)
env

service nginx start &
/usr/lib/motley-cue/bin/gunicorn motley_cue.api:api -k "uvicorn.workers.UvicornWorker" --config /etc/motley_cue/gunicorn.conf.py &
/usr/sbin/sshd -D -e
wait -n