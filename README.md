
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

