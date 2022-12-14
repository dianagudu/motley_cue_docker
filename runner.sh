#!/bin/bash
set -e

/usr/sbin/motley-cue &
/usr/sbin/sshd -D -e
wait -n