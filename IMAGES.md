# Container Images (Kubernetes-Ready)

This project now supports building executable container images with environment-driven configuration.

## Images

- `meeting-scheduler-frontend:latest`
- `meeting-scheduler-backend:latest`
- `postgres:15` (database)

## Build Images

From the project root:

```bash
docker compose -f docker-compose.images.yml build
```

## Run Locally (Image Validation)

```bash
docker compose -f docker-compose.images.yml up -d
```

Frontend: `http://localhost`  
Backend: `http://localhost:8080`

## Environment Configuration

### Frontend build-time variable

- `VITE_API_BASE_URL` (default: `/api`)
- Set in `docker-compose.images.yml` build args

### Backend runtime variables

- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`
- `JWT_SECRET`

Default examples are in `backend/.env.example`.

## Push Images to Registry

Tag and push (example):

```bash
docker tag meeting-scheduler-frontend:latest <registry>/meeting-scheduler-frontend:<tag>
docker tag meeting-scheduler-backend:latest <registry>/meeting-scheduler-backend:<tag>

docker push <registry>/meeting-scheduler-frontend:<tag>
docker push <registry>/meeting-scheduler-backend:<tag>
```

After this, your Kubernetes task is only to reference these pushed image tags in Deployments/Helm charts.
