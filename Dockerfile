FROM debian:10 as builder

##### install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 python3-venv git python3-pip libpam0g-dev libcurl4-openssl-dev libaudit-dev

##### motley-cue: build latest release from source and install to venv
RUN python3 -m venv /usr/lib/motley-cue
RUN . /usr/lib/motley-cue/bin/activate \
    && pip3 install -U pip \
    && git clone https://github.com/dianagudu/motley_cue \
    && cd motley_cue \
    && git checkout $(git tag -l --sort=committerdate | tail -n 1) -b latest \
    && pip install -r requirements.txt \
    && ./setup.py sdist \
    && pip install dist/motley_cue-*.tar.gz

##### pam-ssh: build latest release from source
RUN mkdir pam-ssh && cd pam-ssh \
    && git clone https://git.man.poznan.pl/stash/scm/pracelab/pam.git upstream -b develop \
	&& mv upstream/common upstream/pam-password-token upstream/jsmn-web-tokens . \
	&& rm -rf upstream \
	&& rm -f .patched \
    && cd pam-password-token \
    && make compile_token && make install_token


FROM debian:10 as build

##### install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ssh dumb-init nginx python3 python3-venv
RUN apt-get install -y libpam0g-dev libcurl4-openssl-dev libaudit-dev

##### motley-cue config
COPY --from=builder /usr/lib/motley-cue /usr/lib/motley-cue
RUN mkdir /etc/motley_cue /var/log/motley_cue /run/motley_cue
RUN ln -s /config_files/motley_cue.conf /etc/motley_cue/motley_cue.conf \
    && ln -s /config_files/feudal_adapter.conf /etc/motley_cue/feudal_adapter.conf \
    && ln -s /config_files/motley_cue.env /etc/motley_cue/motley_cue.env \
    && ln -s /config_files/gunicorn.conf.py /etc/motley_cue/gunicorn.conf.py
RUN ln -s /config_files/nginx.motley_cue /etc/nginx/sites-available/nginx.motley_cue \
    && ln -s ../sites-available/nginx.motley_cue /etc/nginx/sites-enabled/nginx.motley_cue

##### pam config
COPY --from=builder /lib/x86_64-linux-gnu/security/pam_oidc_token.so /lib/x86_64-linux-gnu/security/pam_oidc_token.so
# COPY --from=builder /pam-ssh/pam-password-token/config.ini /etc/pam.d/pam-ssh-config.ini
# RUN sed -i 's/^local[[:space:]]*=[[:space:]]*true/local = false/g' /etc/pam.d/pam-ssh-config.ini
RUN CONFIG="/etc/pam.d/pam-ssh-oidc-config.ini" \
    && echo "[user_verification]" > ${CONFIG} \
    && echo "local = false" >> ${CONFIG} \
    && echo "verify_endpoint = http://localhost:8080/verify_user" >> ${CONFIG}

RUN CONFIG="/etc/pam.d/sshd" \
    && HEADLINE=`head -n 1 ${CONFIG}` \
    && mv ${CONFIG} ${CONFIG}.dist \
    && echo ${HEADLINE} > ${CONFIG} \
    && echo "" >> ${CONFIG} \
    && echo "# use pam-ssh-oidc" >> ${CONFIG} \
    && echo "auth   sufficient pam_oidc_token.so config=/etc/pam.d/pam-ssh-oidc-config.ini" >> ${CONFIG} \
    && cat ${CONFIG}.dist | grep -v "${HEADLINE}" >> ${CONFIG}

##### ssh config
RUN mkdir /run/sshd
RUN sed -i 's/^ChallengeResponseAuthentication[[:space:]]\+no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config

##### dumb-init config
ADD --chown=root:root ./runner.sh /srv/runner.sh
RUN chmod +x /srv/runner.sh

##### stop services
RUN service ssh stop
RUN service nginx stop

##### expose needed ports
EXPOSE 22
EXPOSE 8080

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/srv/runner.sh"]
