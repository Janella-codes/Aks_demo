
📊 Architecture Diagram
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

📦 1. Build Docker Images
---

FrontEnd

docker build -t aks-demo-frontend:v1 .
docker tag aks-demo-frontend:v1 aksdemoacr8.azurecr.io/aks-demo-frontend:v1
docker push aksdemoacr8.azurecr.io/aks-demo-frontend:v1

---
API 

docker build -t aks-demo-api:v1 .
docker tag aks-demo-api:v1 aksdemoacr8.azurecr.io/aks-demo-api:v1
docker push aksdemoacr8.azurecr.io/aks-demo-api:v1

---

🗄️ 2. Create Azure Container Registry (ACR)

az acr create \
  --resource-group order_manager \
  --name aksdemoacr8 \
  --sku Basic

---

Login:
  az acr login --name aksdemoacr8
Verify images:
az acr repository list --name aksdemoacr8 -o table

---

☸️ 3. Create AKS Cluster

az aks create \
  --resource-group order_manager \
  --name aksdemo-cluster \
  --node-count 1 \
  --generate-ssh-keys \
  --attach-acr aksdemoacr8

---

Connect
az aks get-credentials \
  --resource-group order_manager \
  --name aksdemo-cluster

---

📂 4. Create K8s/ dir and yaml files 

---

🌐 5. Install NGINX Ingress Controller

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

---

🚦 6. Ingress Routing
Your ingress routes:

/ → frontend service

/api → API service

---

🔍 7. Test the Deployment

kubectl get ingress

