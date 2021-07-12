FROM debian:bullseye as mc_pam_builder

##### install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

##### motley-cue: build latest release from source and install to venv
RUN python3 -m venv /usr/lib/motley-cue
RUN . /usr/lib/motley-cue/bin/activate \
    && pip3 install -U pip \
    && git clone https://github.com/dianagudu/motley_cue \
    && cd motley_cue \
    && git checkout \
    && pip install -r requirements.txt \
    && ./setup.py sdist \
    && pip install dist/motley_cue-*.tar.gz

##### TODO: run tests here

##### pam-ssh: build latest release from source
RUN apt-get update && apt-get install -y libpam0g-dev libcurl4-openssl-dev libaudit-dev
RUN mkdir pam-ssh && cd pam-ssh \
    && git clone https://git.man.poznan.pl/stash/scm/pracelab/pam.git upstream -b develop \
    && mv upstream/common upstream/pam-password-token upstream/jsmn-web-tokens . \
    && rm -rf upstream \
    && cd pam-password-token \
    && make compile_token && make install_token


FROM debian:bullseye as motley_cue_pam_ssh

##### install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    ssh \
    python3 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

##### motley-cue config
COPY --from=mc_pam_builder /usr/lib/motley-cue /usr/lib/motley-cue
RUN mkdir /etc/motley_cue /var/log/motley_cue /run/motley_cue \
    && ln -s /config_files/motley_cue.conf /etc/motley_cue/motley_cue.conf \
    && ln -s /config_files/feudal_adapter.conf /etc/motley_cue/feudal_adapter.conf
ENV FEUDAL_ADAPTER_CONFIG=/etc/motley_cue/feudal_adapter.conf

##### pam config
COPY --from=mc_pam_builder /lib/x86_64-linux-gnu/security/pam_oidc_token.so /lib/x86_64-linux-gnu/security/pam_oidc_token.so
COPY pam-ssh-oidc-config.ini /etc/pam.d/pam-ssh-oidc-config.ini
RUN echo "auth   sufficient pam_oidc_token.so config=/etc/pam.d/pam-ssh-oidc-config.ini\n$(cat /etc/pam.d/sshd)" > /etc/pam.d/sshd

##### ssh config
RUN mkdir /run/sshd
RUN echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config \
    && echo "ChallengeResponseAuthentication yes" > /etc/ssh/sshd_config.d/oidc.conf

##### expose needed ports
EXPOSE 22

##### init cmd and entrypoint
COPY ./runner.sh /srv/runner.sh
COPY ./entrypoint.sh /srv/entrypoint.sh
RUN chmod +x /srv/runner.sh /srv/entrypoint.sh

ENTRYPOINT [ "/srv/entrypoint.sh" ]
CMD ["/srv/runner.sh"]



FROM nginx:alpine as nginx
COPY --from=mc_pam_builder /usr/lib/motley-cue/etc/nginx/nginx.motley_cue /etc/nginx/conf.d/default.conf
EXPOSE 8080