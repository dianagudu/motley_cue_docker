#!/bin/bash
set -e

/usr/lib/motley-cue/bin/gunicorn motley_cue.api:api \
    -k "uvicorn.workers.UvicornWorker" \
    --bind unix:/run/motley_cue/motley-cue.sock \
    --log-level info \
    --config /usr/lib/motley-cue/etc/gunicorn/gunicorn.conf.py \
    --access-logfile "-" --error-logfile "-" &
/usr/sbin/sshd -D -e
wait -n