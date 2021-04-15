FROM debian:10 as builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y python3 python3-venv git python3-pip

RUN python3 -m venv /usr/lib/motley-cue
RUN . /usr/lib/motley-cue/bin/activate \
    && pip3 install -U pip \
    && git clone https://github.com/dianagudu/motley_cue \
    && cd motley_cue \
    && git checkout $(git tag -l --sort=committerdate | tail -n 1) -b latest \
    && pip install -r requirements.txt \
    && ./setup.py sdist \
    && pip install dist/motley_cue-*.tar.gz

FROM debian:10 as build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y ssh dumb-init nginx python3 python3-venv
# for testing
RUN apt install -y vim httpie

COPY --from=builder /usr/lib/motley-cue /usr/lib/motley-cue
RUN cp -r /usr/lib/motley-cue/etc/motley_cue /etc/motley_cue
RUN cp /usr/lib/motley-cue/etc/nginx/nginx.motley_cue /etc/nginx/sites-available \
    && ln -s ../sites-available/nginx.motley_cue /etc/nginx/sites-enabled/nginx.motley_cue

RUN mkdir /var/log/motley_cue /run/motley_cue

ADD --chown=root:root ./runner.sh /srv/runner.sh
RUN chmod +x /srv/runner.sh

RUN service ssh stop
RUN mkdir /run/sshd

RUN service nginx stop

EXPOSE 22
EXPOSE 8080
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/srv/runner.sh"]
