# motley_cue_docker

Docker image for running the [motley_cue](https://github.com/dianagudu/motley_cue) service, which is based on FastAPI, with Uvicorn managed by Gunicorn.

## Usage

### Prerequisites
- docker
- docker-compose

### Run
```
docker-compose up
```

This will run the service at [https://localhost:8080](https://localhost:8080). The API can also be accessed at [https://localhost:8080/docs](https://localhost:8080/docs).

### API calls

Requirements:
- oidc-agent
- http / curl

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