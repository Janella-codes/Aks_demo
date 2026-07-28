
📊 Architecture Diagram

---

flowchart TD

    subgraph Client
        A[Browser]
    end

    A -->|HTTP| I[NGINX Ingress Controller<br/>(Single Public IP)]

    subgraph AKS["Azure Kubernetes Service (aksdemo-cluster)"]
        direction LR

        subgraph Frontend["Frontend (Angular + NGINX)"]
            FE_DEPLOY[Deployment<br/>aks-demo-frontend]
            FE_SVC[Service<br/>ClusterIP:80]
            FE_POD[Pod<br/>Image: aksdemoacr8/aks-demo-frontend]
        end

        subgraph API["Backend API (.NET)"]
            API_DEPLOY[Deployment<br/>aks-demo-api]
            API_SVC[Service<br/>ClusterIP:80]
            API_POD[Pod<br/>Image: aksdemoacr8/aks-demo-api]
        end
    end

    I -->|Path: /| FE_SVC
    I -->|Path: /api| API_SVC

    FE_DEPLOY --> FE_POD
    FE_SVC --> FE_DEPLOY

    API_DEPLOY --> API_POD
    API_SVC --> API_DEPLOY

    subgraph ACR["Azure Container Registry (aksdemoacr8)"]
        IMG_FE[aks-demo-frontend:v1]
        IMG_API[aks-demo-api:v1]
    end

    IMG_FE --> FE_DEPLOY
    IMG_API --> API_DEPLOY


---

🔄 CI/CD Flow Diagram

flowchart LR

    subgraph Dev["Developer Workflow"]
        A[Write Code<br/>(Frontend + API)]
        B[Commit & Push to GitHub]
    end

    subgraph CI["Continuous Integration"]
        C[GitHub Actions / Pipeline<br/>Build Frontend & API]
        D[Run Tests]
        E[Build Docker Images]
        F[Tag Images]
        G[Push Images to ACR<br/>aksdemoacr8.azurecr.io]
    end

    subgraph CD["Continuous Deployment"]
        H[AKS Deployment Manifests<br/>(k8s/*.yaml)]
        I[kubectl apply<br/>Deploy to AKS Cluster]
        J[AKS Schedules Pods]
        K[Pods Pull Images from ACR]
    end

    subgraph Runtime["AKS Runtime Environment"]
        L[Frontend Pod<br/>Angular + NGINX]
        M[API Pod<br/>.NET API]
        N[ClusterIP Services]
        O[NGINX Ingress Controller<br/>Single Public IP]
    end

    P[End User<br/>Browser]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    K --> M
    L --> N
    M --> N
    N --> O
    O --> P

---

# 📘 AKS Demo – Full Cloud Deployment (Frontend + API + ACR + AKS + Ingress)

A complete end‑to‑end Kubernetes deployment on Azure, including:

- Dockerized Angular frontend  
- Dockerized .NET API  
- Azure Container Registry (ACR)  
- Azure Kubernetes Service (AKS)  
- NGINX Ingress Controller  
- Single public IP routing (`/` → frontend, `/api` → backend)

This project demonstrates real‑world cloud deployment patterns used in production AKS environments.

---

## 🚀 Architecture Overview

**Flow:**

1. Build Docker images locally  
2. Push images to Azure Container Registry  
3. Deploy API + frontend to AKS  
4. Expose both through a single ingress  
5. Access the app via one public IP

**Components:**

- **Frontend:** Angular app served via NGINX  
- **Backend:** .NET API listening on port 80  
- **ACR:** `aksdemoacr8.azurecr.io`  
- **AKS Cluster:** `aksdemo-cluster`  
- **Ingress Controller:** NGINX  
- **Ingress IP:** `http://<INGRESS-IP>`  

---

## 📦 1. Build Docker Images

### Frontend

```bash
docker build -t aks-demo-frontend:v1 .
docker tag aks-demo-frontend:v1 aksdemoacr8.azurecr.io/aks-demo-frontend:v1
docker push aksdemoacr8.azurecr.io/aks-demo-frontend:v1
```

### API

```bash
docker build -t aks-demo-api:v1 .
docker tag aks-demo-api:v1 aksdemoacr8.azurecr.io/aks-demo-api:v1
docker push aksdemoacr8.azurecr.io/aks-demo-api:v1
```

---

## 🗄️ 2. Create Azure Container Registry (ACR)

```bash
az acr create \
  --resource-group order_manager \
  --name aksdemoacr8 \
  --sku Basic
```

Login:

```bash
az acr login --name aksdemoacr8
```

Verify images:

```bash
az acr repository list --name aksdemoacr8 -o table
```

---

## ☸️ 3. Create AKS Cluster

```bash
az aks create \
  --resource-group order_manager \
  --name aksdemo-cluster \
  --node-count 1 \
  --generate-ssh-keys \
  --attach-acr aksdemoacr8
```

Connect:

```bash
az aks get-credentials \
  --resource-group order_manager \
  --name aksdemo-cluster
```

Check nodes:

```bash
kubectl get nodes
```

---

## 📁 4. Kubernetes Manifests (`k8s/` directory)

### API Deployment (`api-deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-demo-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-demo-api
  template:
    metadata:
      labels:
        app: aks-demo-api
    spec:
      containers:
      - name: aks-demo-api
        image: aksdemoacr8.azurecr.io/aks-demo-api:v1
        ports:
        - containerPort: 80
```

### API Service (`api-service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: aks-demo-api
spec:
  selector:
    app: aks-demo-api
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### Frontend Deployment (`frontend-deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-demo-frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-demo-frontend
  template:
    metadata:
      labels:
        app: aks-demo-frontend
    spec:
      containers:
      - name: aks-demo-frontend
        image: aksdemoacr8.azurecr.io/aks-demo-frontend:v1
        ports:
        - containerPort: 80
```

### Frontend Service (`frontend-service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: aks-demo-frontend
spec:
  selector:
    app: aks-demo-frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

---

## 🌐 5. Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

Wait, then check:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 🚦 6. Ingress Routing (`ingress.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aks-demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: aks-demo-frontend
            port:
              number: 80

      - path: /api
        pathType: Prefix
        backend:
          service:
            name: aks-demo-api
            port:
              number: 80
```

Apply:

```bash
kubectl apply -f k8s/
```

---

## 🔍 7. Test the Deployment

Get ingress IP:

```bash
kubectl get ingress
```

### Frontend

```
http://<INGRESS-IP>/
```

### API

```
http://<INGRESS-IP>/api
```

---

## 📸 8. Recommended Screenshots for Portfolio

Include screenshots of:

- ACR repositories  
- AKS nodes  
- Running pods  
- Ingress IP  
- Frontend working  
- API responding  
- Folder structure  
- YAML manifests  

This makes your repo look polished and professional.

---

## 🧭 9. Folder Structure

```
aks-demo-janelle/
│
├── api/
├── frontend/
├── k8s/
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
│
├── Dockerfile-api
├── Dockerfile-frontend
└── README.md
```
---

## 📘 10. Architecture Diagram
This project uses a production‑grade AKS architecture with:

ACR storing container images

AKS running frontend + API workloads

ClusterIP services for internal routing

NGINX ingress providing a single public entry point

Clean path‑based routing (/ → frontend, /api → backend)

                          ┌──────────────────────────────┐
                          │        Client Browser         │
                          │  (User accesses single IP)    │
                          └──────────────┬───────────────┘
                                         │
                                         ▼
                          ┌──────────────────────────────┐
                          │      NGINX Ingress Controller │
                          │  (Single public LoadBalancer) │
                          └──────────────┬───────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    │                                         │
                    ▼                                         ▼
     ┌──────────────────────────┐               ┌──────────────────────────┐
     │  Frontend Service        │               │  API Service             │
     │  (ClusterIP, port 80)    │               │  (ClusterIP, port 80)    │
     └──────────────┬──────────┘               └──────────────┬──────────┘
                    │                                         │
                    ▼                                         ▼
     ┌──────────────────────────┐               ┌──────────────────────────┐
     │ Frontend Deployment      │               │ API Deployment           │
     │ Angular + NGINX          │               │ .NET API (port 80)       │
     └──────────────┬──────────┘               └──────────────┬──────────┘
                    │                                         │
                    ▼                                         ▼
     ┌──────────────────────────┐               ┌──────────────────────────┐
     │ Frontend Pod             │               │ API Pod                  │
     │ Image: aksdemoacr8/...   │               │ Image: aksdemoacr8/...   │
     └──────────────────────────┘               └──────────────────────────┘

                          ┌──────────────────────────────┐
                          │ Azure Container Registry      │
                          │  aksdemoacr8.azurecr.io       │
                          │ Stores both images            │
                          └──────────────────────────────┘

                          ┌──────────────────────────────┐
                          │ Azure Kubernetes Service      │
                          │  aksdemo-cluster              │
                          │ Nodepool: 1 node              │
                          └──────────────────────────────┘


---

🧭 9. Folder Structure

aks-demo-janelle/
│
├── api/
├── frontend/
├── k8s/
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
│
├── docker/
│   ├── api.Dockerfile
│   └── frontend.Dockerfile
│
└── README.md

---

🧹 10. Cleanup (to avoid Azure charges)

az aks delete --resource-group order_manager --name aksdemo-cluster --yes
az acr delete --resource-group order_manager --name aksdemoacr8 --yes
# OR delete everything:
az group delete --name order_manager --yes

---

## 🎉 Final Notes

This project demonstrates:

- Real AKS deployment  
- Proper ingress routing  
- Multi‑container architecture  
- Azure cloud integration  
- Kubernetes best practices  


