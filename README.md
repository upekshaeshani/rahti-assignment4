# 3-Tier Application with Docker Compose and Rahti

## 1. Application description

This project is a three-tier web application consisting of:

* **Frontend:** Nginx serving an HTML/JavaScript application
* **Backend:** Python Flask REST API
* **Database:** MySQL 8.4

The frontend communicates with the Flask backend through `/api`. The backend communicates with MySQL using environment variables for the database connection.

The application displays the MySQL server time and a page-view counter. The **Record Page View** button writes data to MySQL.

## 2. Architecture

```text
                    Public user
                        |
                        v
              OpenShift Route
                        |
                        v
              +----------------+
              |    Frontend    |
              | Nginx :8080    |
              +----------------+
                        |
                  frontend Service
                        |
                        v
              +----------------+
              |    Backend     |
              | Flask :8000    |
              +----------------+
                        |
                   backend Service
                        |
                        v
              +----------------+
              |     MySQL      |
              |     :3306      |
              +----------------+
                        |
                        v
                 mysql-pvc
              persistent storage
```

Only the frontend has a public OpenShift Route. The backend and MySQL are accessed through internal Kubernetes/OpenShift Services.

## 3. Docker Compose deployment

The application was first developed and tested with Docker Compose.

Start the development version:

```cmd
docker compose -f docker-compose.dev.yml --env-file .env up --build -d
```

The frontend is available at:

```text
http://localhost:8080
```

The backend API can be tested with:

```cmd
curl http://127.0.0.1:8000/api
```

Record a page view:

```cmd
curl -X POST http://127.0.0.1:8000/api/view
```

The `.env` file contains local credentials and must not be committed to Git.

## 4. Docker images

The application images are published on Docker Hub:

* `upeksha94/lemp-backend`
* `upeksha94/lemp-frontend`

Frontend image versions used during development and deployment included:

```text
upeksha94/lemp-frontend:1.0.0
upeksha94/lemp-frontend:1.0.1
upeksha94/lemp-frontend:1.0.3
```

The 1.0.1 image contains the OpenShift-compatible Nginx configuration. The 1.0.3 image contains the final application documentation displayed on the webpage.

## 5. Rahti deployment

The Rahti deployment uses Kubernetes/OpenShift resources stored in the `k8s` directory.

Important resources are:

* `ConfigMap` for non-sensitive configuration
* `Secret` for database passwords
* `PersistentVolumeClaim` for MySQL data
* MySQL Deployment and Service
* Backend Deployment and Service
* Frontend Deployment and Service
* OpenShift Route for public frontend access

The real `secret.yaml` file is intentionally excluded from Git.

For a new deployment, create the secret from `secret.example.yaml` with your own passwords and apply the Kubernetes/OpenShift manifests.

Example:

```cmd
oc apply -f k8s/secret.yaml
oc apply -f k8s/configmap.yaml
oc apply -f k8s/mysql-pvc.yaml
oc apply -f k8s/mysql-init-configmap.yaml
oc apply -f k8s/mysql-deployment.yaml
oc apply -f k8s/mysql-service.yaml
oc apply -f k8s/backend-deployment.yaml
oc apply -f k8s/backend-service.yaml
oc apply -f k8s/frontend-deployment.yaml
oc apply -f k8s/frontend-service.yaml
oc apply -f k8s/route.yaml
```

## 6. End-to-end communication

The deployed application was tested through the public frontend Route.

A GET request to `/api` returned the MySQL server time and page-view counter:

```json
{
  "message": "Hello from MySQL via Flask!",
  "mysql_server_time": "...",
  "page_views": 1
}
```

A POST request to `/api/view` successfully incremented the page-view counter.

This demonstrates communication through all three tiers:

```text
Browser -> Frontend -> Backend -> MySQL
```

## 7. Database persistence experiment

Before the experiment, the application reported:

```text
page_views = 1
```

The MySQL Pod was deleted while the MySQL Deployment and `mysql-pvc` PersistentVolumeClaim were kept.

Old Pod:

```text
mysql-5c44b4574c-cslgt
```

Replacement Pod:

```text
mysql-5c44b4574c-57brh
```

The replacement Pod reached `Running` status.

After the replacement, the application still reported:

```text
page_views = 1
```

This demonstrates that the database data survived the Pod replacement because MySQL data was stored on persistent storage.

## 8. Pod recovery experiment

The backend Pod was manually deleted.

Old Pod:

```text
backend-7884df4c95-jnkcs
```

OpenShift automatically created:

```text
backend-7884df4c95-dft7v
```

The replacement Pod reached `Running` and `Ready` status.

The public API continued to return the database information after the replacement.

This demonstrates automatic Pod recovery through the Deployment controller.

## 9. Scaling experiment

The backend Deployment was initially running with one replica.

It was scaled to three replicas:

```cmd
oc scale deployment backend --replicas=3
```

OpenShift created three running backend Pods.

After the experiment, it was scaled back to one replica:

```cmd
oc scale deployment backend --replicas=1
```

This demonstrates horizontal scaling of the backend Deployment.

## 10. Application update

The frontend application was initially deployed using:

```text
upeksha94/lemp-frontend:1.0.0
```

It was updated to:

```text
upeksha94/lemp-frontend:1.0.1
```

OpenShift created a new ReplicaSet for version 1.0.1. The new frontend Pod became Ready and the old 1.0.0 ReplicaSet was scaled down to zero Pods.

The final documentation version was later published as:

```text
upeksha94/lemp-frontend:1.0.3
```

and successfully rolled out using:

```cmd
oc set image deployment/frontend frontend=upeksha94/lemp-frontend:1.0.3
oc rollout status deployment/frontend
```

The final running frontend Pod uses version 1.0.3.

## 11. Problems and solutions

### OpenShift restricted container permissions

The initial frontend container failed because the default Nginx configuration attempted to create temporary files in locations that were not writable under OpenShift's restricted container permissions.

The solution was to:

* move the Nginx PID file to `/tmp`
* move Nginx temporary paths to `/tmp`
* configure Nginx to listen on port `8080`
* update the Kubernetes Service and Route to use port `8080`

After this change, the frontend Pod reached `Running` status.

### Database initialization

The MySQL data directory had already been initialized before the application database configuration was corrected. The MySQL Deployment and PVC were recreated because no required assignment data had yet been stored.

After recreation, the MySQL logs confirmed creation of the `appdb` database and `appuser` account and successful execution of the initialization script.

## 12. Docker Compose + cPouta vs Rahti

With Docker Compose on cPouta, the application was managed as a group of containers running on one virtual machine. Docker Compose handled container startup and the Compose network allowed the containers to communicate using service names.

Public access was provided by exposing the frontend port through the cPouta security group.

With Rahti, the application is managed as Kubernetes/OpenShift resources rather than as containers directly managed on a VM. Deployments manage Pod creation, replacement and scaling. Services provide stable internal networking. The PersistentVolumeClaim provides persistent database storage, and an OpenShift Route provides public access to the frontend.

The networking model therefore changed from a Docker Compose network on one VM to Services inside an OpenShift cluster. Public access also changed from a VM port exposed through a security group to an OpenShift Route.

Management changed from operating the Docker Compose application on a VM to declaring Kubernetes/OpenShift resources. OpenShift then manages Pod lifecycle and replica counts through Deployments.

## 13. Security

No passwords or access tokens should be committed to Git.

The following files are ignored:

```text
.env
k8s/secret.yaml
```

A safe template is provided as:

```text
k8s/secret.example.yaml
```

The example contains placeholders only. Each user should create their own `secret.yaml` with their own credentials.

## 14. Public application

The deployed application is available at:

```text
http://frontend-mywebapp-upeksha.2.rahtiapp.fi
```
