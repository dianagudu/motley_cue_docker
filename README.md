# motley_cue_docker

Docker image for running [SSH with OIDC token based authentication](https://github.com/EOSC-synergy/ssh-oidc).

The image contains:
- ssh service with PAM-based authentication & ChallengeResponseAuthentication enabled
- [motley_cue](https://github.com/dianagudu/motley_cue) service for user provisioning, authorisation and name resolution
- [PAM](https://git.man.poznan.pl/stash/scm/pracelab/pam.git) module for token based authentication

## Usage

### Prerequisites
- docker
- docker-compose

### Run
First, create a folder where you would like to have your config files located and export the path to `CONFIG_FOLDER` env variable:
```
export CONFIG_FOLDER=<your preferred location>
mkdir $CONFIG_FOLDER
```

Then run:
```
docker-compose up
```

<!-- ```
docker build -t mc_build .
docker run -d --name mc_build_run -p 8080:8080 -p 22:22 mc_build
``` -->

This will expose the motley_cue service on [http://localhost:8080](http://localhost:8080) and the SSH service on port 1022. It will also copy default config files in `$CONFIG_FOLDER`.
<!-- You can change the ports in the `docker run` command above as needed, e.g.:
```
docker run -d --name mc_build_run -p 8888:8080 -p 1022:22 mc_build
``` -->

You can configure the authorisation in `$CONFIG_FOLDER/motley_cue.conf` and restart the containers.

### Usage

Requirements:
- [oidc-agent](https://github.com/indigo-dc/oidc-agent)
- [mc_ssh](https://github.com/dianagudu/mc_ssh)

[Install](https://indigo-dc.gitbook.io/oidc-agent/installation/install) `oidc-agent` and [configure](https://indigo-dc.gitbook.io/oidc-agent/user/oidc-gen) an account for your preferred OP. The image currently supports [Helmholtz AAI dev](https://login-dev.helmholtz.de/oauth2) and [EGI](https://aai.egi.eu/oidc) OPs.

Install `mc_ssh` simply by:
```
pip install mc_ssh
```

To automatically create a user and ssh into your container using a configured oidc-agent account:
```
export OIDC_AGENT_ACCOUNT=<configured oidc-agent account shortname>
mccli ssh localhost -p 1022
```

<!-- Or if you defined non-standard ports:
```
mccli ssh --mc-endpoint http://localhost:8888 -p 1022 localhost
``` -->

<!-- 
motley_cue API calls (covered in motley_cue docs!)
Information about the API:
```
http --verify no https://localhost:8080
```

Information about the service whose users are managed by the API: 
```
http --verify no https://localhost:8080/info "Authorization: Bearer `oidc-token deep`"
```

Deploy a new user by passing an OIDC access token:
```
http --verify no https://localhost:8080/user/deploy  "Authorization: Bearer `oidc-token deep`"
```

Verify if a given username matches the local username of an authorised user:
```
http --verify no "https://localhost:8080/verify_user?username=dianagudu" "Authorization: Bearer `oidc-token deep`"
```
-->