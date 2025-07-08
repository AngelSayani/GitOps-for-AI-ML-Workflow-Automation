#!/bin/bash

# Kubernetes environment setup

# Fix locale warnings
export LC_ALL=C
export LANG=C

# Create kubectl command
cat > /usr/local/bin/kubectl << 'EOF'
#!/bin/bash

case "$1" in
  "get")
    case "$2" in
      "nodes")
        echo "NAME                   STATUS   ROLES                  AGE   VERSION"
        echo "gitops-lab-server-0    Ready    control-plane,master   2m    v1.27.4+k3s1"
        echo "gitops-lab-agent-0     Ready    <none>                 1m    v1.27.4+k3s1"
        echo "gitops-lab-agent-1     Ready    <none>                 1m    v1.27.4+k3s1"
        ;;
      "pods")
        if [[ "$*" == *"-n argocd"* ]]; then
          echo "NAME                                                READY   STATUS    RESTARTS   AGE"
          echo "argocd-application-controller-0                     1/1     Running   0          2m"
          echo "argocd-applicationset-controller-5f6b5d7f8b-xk9sm   1/1     Running   0          2m"
          echo "argocd-dex-server-6dcf5d6b8b-nf2xb                  1/1     Running   0          2m"
          echo "argocd-notifications-controller-5b56f6f6c-7jl8k     1/1     Running   0          2m"
          echo "argocd-redis-ha-server-0                            1/1     Running   0          2m"
          echo "argocd-repo-server-6b8b5ff8b7-zq9kr                 1/1     Running   0          2m"
          echo "argocd-server-7b9d7dbf96-xpn8r                      1/1     Running   0          2m"
        elif [[ "$*" == *"-n carvedrock -w"* ]]; then
          echo "NAME                              READY   STATUS              RESTARTS   AGE"
          echo "catalog-service-6d4cf56db-xh8kp   1/1     Running             0          10s"
          sleep 2
          echo "catalog-service-6d4cf56db-p9q2m   0/1     ContainerCreating   0          2s"
          sleep 2
          echo "catalog-service-6d4cf56db-p9q2m   1/1     Running             0          5s"
          sleep 2
          echo "catalog-service-6d4cf56db-xh8kp   1/1     Terminating         0          15s"
          sleep 2
          echo "catalog-service-6d4cf56db-xh8kp   0/1     Terminating         0          17s"
        elif [[ "$*" == *"-n carvedrock"* ]]; then
          echo "NAME                              READY   STATUS    RESTARTS   AGE"
          echo "catalog-service-6d4cf56db-xh8kp   1/1     Running   0          30s"
        fi
        ;;
      "namespace")
        if [[ "$3" == "carvedrock" ]]; then
          echo "NAME         STATUS   AGE"
          echo "carvedrock   Active   1m"
        fi
        ;;
      "all")
        if [[ "$*" == *"-n carvedrock"* ]]; then
          echo "NAME                              READY   STATUS    RESTARTS   AGE"
          echo "pod/catalog-service-6d4cf56db-xh8kp   1/1     Running   0          45s"
          echo ""
          echo "NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE"
          echo "service/catalog-service   ClusterIP   10.43.10.125   <none>        80/TCP    45s"
          echo ""
          echo "NAME                          READY   UP-TO-DATE   AVAILABLE   AGE"
          echo "deployment.apps/catalog-service   1/1     1            1           45s"
          echo ""
          echo "NAME                                    DESIRED   CURRENT   READY   AGE"
          echo "replicaset.apps/catalog-service-6d4cf56db   1         1         1       45s"
        fi
        ;;
      "deployment")
        if [[ "$*" == *"-o jsonpath"* ]] && [[ "$*" == *"replicas"* ]]; then
          if [ -f /tmp/replica-state ]; then
            echo -n "2"
          else
            echo -n "1"
          fi
        fi
        ;;
      "secret")
        if [[ "$*" == *"argocd-initial-admin-secret"* ]] && [[ "$*" == *"jsonpath"* ]]; then
          echo -n "QWRtaW5QYXNzd29yZDEyMyE="
        fi
        ;;
    esac
    ;;
  "logs")
    if [[ "$*" == *"-n carvedrock"* ]]; then
      echo "/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"
      echo "/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/"
      echo "/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh"
      echo "/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh"
      echo "/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh"
      echo "/docker-entrypoint.sh: Configuration complete; ready for start up"
    fi
    ;;
  "describe")
    if [[ "$*" == *"deployment"* ]] && [[ "$*" == *"catalog-service"* ]]; then
      if [ -f /tmp/replica-state ]; then
        replicas="2"
      else
        replicas="1"
      fi
      echo "Name:                   catalog-service"
      echo "Namespace:              carvedrock"
      echo "CreationTimestamp:      Mon, 01 Jan 2024 10:00:00 +0000"
      echo "Labels:                 app=catalog-service"
      echo "Selector:               app=catalog-service"
      echo "Replicas:               $replicas desired | $replicas updated | $replicas total | $replicas available | 0 unavailable"
      echo "StrategyType:           RollingUpdate"
      echo "MinReadySeconds:        0"
    fi
    ;;
  "apply")
    echo "application.argoproj.io/catalog-service created"
    ;;
  "create")
    if [[ "$*" == *"namespace argocd"* ]]; then
      echo "namespace/argocd created"
    fi
    ;;
  "wait")
    echo "pod/argocd-server-7b9d7dbf96-xpn8r condition met"
    ;;
  "port-forward")
    if [[ "$*" == *"catalog-service"* ]]; then
      # Check if port is already in use
      if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "error: unable to listen on any of the requested ports: [{8081 80}]"
        exit 1
      else
        echo "Forwarding from 0.0.0.0:8081 -> 80"
        echo "Handling connection for 8081" &
        # Create a simple HTTP server on port 8081
        (while true; do
          if [ -f /tmp/replica-state ]; then
            response='<!DOCTYPE html>
<html>
<head>
    <title>CarvedRock Catalog - Black Friday Edition</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        h1 { color: #333; }
        .catalog { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .item { margin: 10px 0; padding: 10px; border-left: 4px solid #28a745; }
        .version { position: absolute; top: 10px; right: 10px; color: #666; font-size: 12px; }
        .promo { background: #ff6b6b; color: white; padding: 10px; border-radius: 4px; text-align: center; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="version">Version: 2.0.0</div>
    <h1>CarvedRock Outdoor Gear Catalog - Black Friday Edition</h1>
    <div class="promo">🎉 BLACK FRIDAY SALE - Up to 50% OFF! 🎉</div>
    <div class="catalog">
        <div class="item">
            <h3>Climbing Gear</h3>
            <p>Professional climbing equipment - <strong>30% OFF</strong></p>
        </div>
        <div class="item">
            <h3>Hiking Equipment</h3>
            <p>Everything for your adventure - <strong>40% OFF</strong></p>
        </div>
        <div class="item">
            <h3>Camping Supplies</h3>
            <p>Quality camping gear - <strong>50% OFF</strong></p>
        </div>
        <div class="item">
            <h3>Winter Collection</h3>
            <p>NEW! Stay warm this season - <strong>25% OFF</strong></p>
        </div>
    </div>
</body>
</html>'
          else
            response='<!DOCTYPE html>
<html>
<head>
    <title>CarvedRock Catalog</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        h1 { color: #333; }
        .catalog { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .item { margin: 10px 0; padding: 10px; border-left: 4px solid #007bff; }
        .version { position: absolute; top: 10px; right: 10px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="version">Version: 1.0.0</div>
    <h1>CarvedRock Outdoor Gear Catalog</h1>
    <div class="catalog">
        <div class="item">
            <h3>Climbing Gear</h3>
            <p>Professional climbing equipment for all skill levels</p>
        </div>
        <div class="item">
            <h3>Hiking Equipment</h3>
            <p>Everything you need for your next adventure</p>
        </div>
        <div class="item">
            <h3>Camping Supplies</h3>
            <p>Quality camping gear for the great outdoors</p>
        </div>
    </div>
</body>
</html>'
          fi
          echo -e "HTTP/1.1 200 OK\r\nContent-Length: ${#response}\r\nContent-Type: text/html\r\n\r\n$response" | nc -l -p 8081 -q 1 >/dev/null 2>&1
        done) >/dev/null 2>&1 &
        echo $! > /tmp/port-forward-8081.pid
      fi
    elif [[ "$*" == *"argocd-server"* ]]; then
      if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "error: unable to listen on any of the requested ports: [{8080 443}]"
        exit 1
      else
        echo "Forwarding from 0.0.0.0:8080 -> 8080"
        echo "Handling connection for 8080" &
        # Create a dummy process to hold the port
        (while true; do sleep 3600; done) >/dev/null 2>&1 &
        echo $! > /tmp/port-forward-8080.pid
      fi
    fi
    ;;
  "-n")
    if [[ "$*" == *"get secret"* ]] && [[ "$*" == *"jsonpath"* ]]; then
      echo -n "QWRtaW5QYXNzd29yZDEyMyE="
    fi
    ;;
  "cluster-info")
    echo "Kubernetes control plane is running at https://127.0.0.1:6550"
    echo "CoreDNS is running at https://127.0.0.1:6550/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy"
    echo "Metrics-server is running at https://127.0.0.1:6550/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy"
    ;;
esac
EOF

chmod +x /usr/local/bin/kubectl

# Create argocd command
cat > /usr/local/bin/argocd << 'EOF'
#!/bin/bash

case "$1" in
  "login")
    echo "'admin:login' logged in successfully"
    echo "Context 'localhost:8080' updated"
    ;;
  "repo")
    if [[ "$2" == "add" ]]; then
      echo "Repository 'https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git' added"
    fi
    ;;
  "app")
    case "$2" in
      "get")
        if [[ "$*" == *"--refresh"* ]]; then
          if [ -f /tmp/sync-state ]; then
            echo "Name:               catalog-service"
            echo "Project:            default"
            echo "Server:             https://kubernetes.default.svc"
            echo "Namespace:          carvedrock"
            echo "URL:                https://localhost:8080/applications/catalog-service"
            echo "Repo:               https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git"
            echo "Target:             HEAD"
            echo "Path:               manifests"
            echo "SyncWindow:         Sync Allowed"
            echo "Sync Policy:        Automated (Prune)"
            echo "Sync Status:        Syncing (Running)"
            echo "Health Status:      Progressing"
            echo ""
            echo "Operation:          Sync"
            echo "Sync Revision:      a7d8f6e2c4b1"
            echo "Phase:              Running"
            echo "Start:              2024-01-01 10:05:00 +0000 UTC"
            echo "Finished:           <nil>"
            echo "Duration:           5s"
            rm -f /tmp/sync-state
            sleep 2
          else
            echo "Name:               catalog-service"
            echo "Project:            default"
            echo "Server:             https://kubernetes.default.svc"
            echo "Namespace:          carvedrock"
            echo "URL:                https://localhost:8080/applications/catalog-service"
            echo "Repo:               https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git"
            echo "Target:             HEAD"
            echo "Path:               manifests"
            echo "SyncWindow:         Sync Allowed"
            echo "Sync Policy:        Automated (Prune)"
            echo "Sync Status:        Synced"
            echo "Health Status:      Healthy"
            echo ""
            echo "GROUP  KIND            NAMESPACE   NAME             STATUS  HEALTH   HOOK  MESSAGE"
            echo "       Namespace       carvedrock  carvedrock       Synced                  namespace/carvedrock created"
            echo "       Service         carvedrock  catalog-service  Synced  Healthy        service/catalog-service created"
            echo "apps   Deployment      carvedrock  catalog-service  Synced  Healthy        deployment.apps/catalog-service created"
            echo "       ConfigMap       carvedrock  catalog-html     Synced                  configmap/catalog-html created"
          fi
        else
          echo "Name:               catalog-service"
          echo "Project:            default"
          echo "Server:             https://kubernetes.default.svc"
          echo "Namespace:          carvedrock"
          echo "URL:                https://localhost:8080/applications/catalog-service"
          echo "Repo:               https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git"
          echo "Target:             HEAD"
          echo "Path:               manifests"
          echo "SyncWindow:         Sync Allowed"
          echo "Sync Policy:        Automated (Prune)"
          echo "Sync Status:        Synced"
          echo "Health Status:      Healthy"
          echo ""
          echo "GROUP  KIND            NAMESPACE   NAME             STATUS  HEALTH   HOOK  MESSAGE"
          echo "       Namespace       carvedrock  carvedrock       Synced                  namespace/carvedrock created"
          echo "       Service         carvedrock  catalog-service  Synced  Healthy        service/catalog-service created"
          echo "apps   Deployment      carvedrock  catalog-service  Synced  Healthy        deployment.apps/catalog-service created"
          echo "       ConfigMap       carvedrock  catalog-html     Synced                  configmap/catalog-html created"
        fi
        ;;
      "history")
        if [ -f /tmp/revert-state ]; then
          echo "ID  DATE                           REVISION"
          echo "0   2024-01-01 10:00:00 +0000 UTC  a7d8f6e2c4b1"
          echo "1   2024-01-01 10:05:00 +0000 UTC  b9e4d7c3a2f5"
          echo "2   2024-01-01 10:10:00 +0000 UTC  c3f8a9d5e7b2"
        else
          echo "ID  DATE                           REVISION"
          echo "0   2024-01-01 10:00:00 +0000 UTC  a7d8f6e2c4b1"
        fi
        ;;
    esac
    ;;
esac
EOF

chmod +x /usr/local/bin/argocd

# Create git command
cat > /usr/local/bin/git << 'EOF'
#!/bin/bash

case "$1" in
  "add")
    # Silent success
    ;;
  "commit")
    echo "[main b9e4d7c] Deploy Black Friday catalog update v2.0.0"
    echo " 1 file changed, 10 insertions(+), 5 deletions(-)"
    ;;
  "push")
    echo "Enumerating objects: 5, done."
    echo "Counting objects: 100% (5/5), done."
    echo "Delta compression using up to 2 threads"
    echo "Compressing objects: 100% (3/3), done."
    echo "Writing objects: 100% (3/3), 512 bytes | 512.00 KiB/s, done."
    echo "Total 3 (delta 2), reused 0 (delta 0)"
    echo "To https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git"
    echo "   a7d8f6e..b9e4d7c  main -> main"
    touch /tmp/sync-state
    ;;
  "revert")
    echo "[main c3f8a9d] Revert \"Deploy Black Friday catalog update v2.0.0\""
    echo " 1 file changed, 5 insertions(+), 10 deletions(-)"
    touch /tmp/revert-state
    rm -f /tmp/replica-state
    touch /tmp/sync-state
    ;;
esac
EOF

chmod +x /usr/local/bin/git

# Create the setup.sh script
cat > /home/cloud_user/setup.sh << 'EOF'
#!/bin/bash
echo "Starting k3d cluster setup..."
# Just show the expected output
echo "INFO[0000] Prep: Network"
echo "INFO[0000] Created network 'k3d-gitops-lab'"
echo "INFO[0000] Created image volume k3d-gitops-lab-images"
echo "INFO[0001] Starting new tools node..."
echo "INFO[0002] Creating node 'k3d-gitops-lab-server-0'"
echo "INFO[0005] Creating node 'k3d-gitops-lab-agent-0'"
echo "INFO[0005] Creating node 'k3d-gitops-lab-agent-1'"
echo "INFO[0006] Creating LoadBalancer 'k3d-gitops-lab-serverlb'"
echo "INFO[0010] Starting cluster 'gitops-lab'"
echo "INFO[0010] Starting servers..."
echo "INFO[0010] Starting Node 'k3d-gitops-lab-server-0'"
echo "INFO[0020] Starting agents..."
echo "INFO[0020] Starting Node 'k3d-gitops-lab-agent-0'"
echo "INFO[0020] Starting Node 'k3d-gitops-lab-agent-1'"
echo "INFO[0025] Starting helpers..."
echo "INFO[0025] Starting Node 'k3d-gitops-lab-serverlb'"
echo "INFO[0030] Cluster 'gitops-lab' created successfully!"
echo "Kubernetes control plane is running at https://127.0.0.1:6550"
echo "CoreDNS is running at https://127.0.0.1:6550/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy"
echo "Metrics-server is running at https://127.0.0.1:6550/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy"
echo "Cluster setup complete!"
EOF

chmod +x /home/cloud_user/setup.sh

# Create the install-argocd.sh script
cat > /home/cloud_user/install-argocd.sh << 'EOF'
#!/bin/bash
kubectl create namespace argocd
echo "namespace/argocd created"
echo "Applying ArgoCD manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created"
echo "customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created"
echo "customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io created"
echo "serviceaccount/argocd-application-controller created"
echo "serviceaccount/argocd-applicationset-controller created"
echo "serviceaccount/argocd-dex-server created"
echo "serviceaccount/argocd-notifications-controller created"
echo "serviceaccount/argocd-redis created"
echo "serviceaccount/argocd-repo-server created"
echo "serviceaccount/argocd-server created"
echo "role.rbac.authorization.k8s.io/argocd-application-controller created"
echo "role.rbac.authorization.k8s.io/argocd-applicationset-controller created"
echo "role.rbac.authorization.k8s.io/argocd-dex-server created"
echo "role.rbac.authorization.k8s.io/argocd-notifications-controller created"
echo "role.rbac.authorization.k8s.io/argocd-server created"
echo "clusterrole.rbac.authorization.k8s.io/argocd-application-controller created"
echo "clusterrole.rbac.authorization.k8s.io/argocd-server created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-application-controller created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-dex-server created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-redis created"
echo "rolebinding.rbac.authorization.k8s.io/argocd-server created"
echo "clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller created"
echo "clusterrolebinding.rbac.authorization.k8s.io/argocd-server created"
echo "configmap/argocd-cm created"
echo "configmap/argocd-cmd-params-cm created"
echo "configmap/argocd-gpg-keys-cm created"
echo "configmap/argocd-notifications-cm created"
echo "configmap/argocd-rbac-cm created"
echo "configmap/argocd-ssh-known-hosts-cm created"
echo "configmap/argocd-tls-certs-cm created"
echo "secret/argocd-notifications-secret created"
echo "secret/argocd-secret created"
echo "service/argocd-applicationset-controller created"
echo "service/argocd-dex-server created"
echo "service/argocd-metrics created"
echo "service/argocd-notifications-controller-metrics created"
echo "service/argocd-redis created"
echo "service/argocd-repo-server created"
echo "service/argocd-server created"
echo "service/argocd-server-grpc created"
echo "deployment.apps/argocd-applicationset-controller created"
echo "deployment.apps/argocd-dex-server created"
echo "deployment.apps/argocd-notifications-controller created"
echo "deployment.apps/argocd-redis created"
echo "deployment.apps/argocd-repo-server created"
echo "deployment.apps/argocd-server created"
echo "statefulset.apps/argocd-application-controller created"
echo "networkpolicy.networking.k8s.io/argocd-application-controller-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-dex-server-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-notifications-controller-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-redis-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-repo-server-network-policy created"
echo "networkpolicy.networking.k8s.io/argocd-server-network-policy created"
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
echo "ArgoCD installation complete!"
EOF

chmod +x /home/cloud_user/install-argocd.sh

# Create the argocd-port-forward.sh script
cat > /home/cloud_user/argocd-port-forward.sh << 'EOF'
#!/bin/bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0 &
echo "ArgoCD UI is being forwarded to port 8080"
echo "Process ID: $!"
EOF

chmod +x /home/cloud_user/argocd-port-forward.sh

# Create the get-argocd-password.sh script
cat > /home/cloud_user/get-argocd-password.sh << 'EOF'
#!/bin/bash
echo "ArgoCD admin password:"
echo "AdminPassword123!"
echo ""
EOF

chmod +x /home/cloud_user/get-argocd-password.sh

# Create lab file structure
mkdir -p /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/manifests
mkdir -p /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/.git

# Create namespace.yaml
cat > /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/manifests/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: carvedrock
EOF

# Create catalog-deployment.yaml (v1)
cat > /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/manifests/catalog-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-service
  namespace: carvedrock
  labels:
    app: catalog-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog-service
  template:
    metadata:
      labels:
        app: catalog-service
    spec:
      containers:
      - name: catalog
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "1.0.0"
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: catalog-html
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-service
  namespace: carvedrock
spec:
  selector:
    app: catalog-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-html
  namespace: carvedrock
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>CarvedRock Catalog</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
            h1 { color: #333; }
            .catalog { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .item { margin: 10px 0; padding: 10px; border-left: 4px solid #007bff; }
            .version { position: absolute; top: 10px; right: 10px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="version">Version: 1.0.0</div>
        <h1>CarvedRock Outdoor Gear Catalog</h1>
        <div class="catalog">
            <div class="item">
                <h3>Climbing Gear</h3>
                <p>Professional climbing equipment for all skill levels</p>
            </div>
            <div class="item">
                <h3>Hiking Equipment</h3>
                <p>Everything you need for your next adventure</p>
            </div>
            <div class="item">
                <h3>Camping Supplies</h3>
                <p>Quality camping gear for the great outdoors</p>
            </div>
        </div>
    </body>
    </html>
EOF

# Create v2 deployment file
cat > /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/catalog-deployment-v2.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-service
  namespace: carvedrock
  labels:
    app: catalog-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: catalog-service
  template:
    metadata:
      labels:
        app: catalog-service
    spec:
      containers:
      - name: catalog
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "2.0.0"
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: catalog-html
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-service
  namespace: carvedrock
spec:
  selector:
    app: catalog-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-html
  namespace: carvedrock
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>CarvedRock Catalog - Black Friday Edition</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
            h1 { color: #333; }
            .catalog { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .item { margin: 10px 0; padding: 10px; border-left: 4px solid #28a745; }
            .version { position: absolute; top: 10px; right: 10px; color: #666; font-size: 12px; }
            .promo { background: #ff6b6b; color: white; padding: 10px; border-radius: 4px; text-align: center; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="version">Version: 2.0.0</div>
        <h1>CarvedRock Outdoor Gear Catalog - Black Friday Edition</h1>
        <div class="promo">🎉 BLACK FRIDAY SALE - Up to 50% OFF! 🎉</div>
        <div class="catalog">
            <div class="item">
                <h3>Climbing Gear</h3>
                <p>Professional climbing equipment - <strong>30% OFF</strong></p>
            </div>
            <div class="item">
                <h3>Hiking Equipment</h3>
                <p>Everything for your adventure - <strong>40% OFF</strong></p>
            </div>
            <div class="item">
                <h3>Camping Supplies</h3>
                <p>Quality camping gear - <strong>50% OFF</strong></p>
            </div>
            <div class="item">
                <h3>Winter Collection</h3>
                <p>NEW! Stay warm this season - <strong>25% OFF</strong></p>
            </div>
        </div>
    </body>
    </html>
EOF

# Create ArgoCD application file
cat > /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/argocd-application.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: catalog-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/AngelSayani/GitOps-for-Progressive-Delivery.git
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: carvedrock
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Create ls command wrapper
cat > /usr/local/bin/ls-wrapper << 'EOF'
#!/bin/bash
if [[ "$*" == *"~/lab-files/GitOps-for-Progressive-Delivery/"* ]] || [[ "$*" == *"/home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/"* ]]; then
  echo "argocd-application.yaml"
  echo "catalog-deployment-v2.yaml"
  echo "manifests"
  echo "README.md"
else
  /bin/ls "$@"
fi
EOF

# Create alias for ls
echo "alias ls='/usr/local/bin/ls-wrapper'" >> /home/cloud_user/.bashrc

# Create cat command wrapper
cat > /usr/local/bin/cat-wrapper << 'EOF'
#!/bin/bash
case "$1" in
  *"namespace.yaml"*)
    cat /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/manifests/namespace.yaml
    ;;
  *"catalog-deployment.yaml"*)
    cat /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/manifests/catalog-deployment.yaml
    ;;
  *"argocd-application.yaml"*)
    cat /home/cloud_user/lab-files/GitOps-for-Progressive-Delivery/argocd-application.yaml
    ;;
  *)
    /bin/cat "$@"
    ;;
esac
EOF

chmod +x /usr/local/bin/cat-wrapper
echo "alias cat='/usr/local/bin/cat-wrapper'" >> /home/cloud_user/.bashrc

# Create cp command wrapper for the v2 copy operation
cat > /usr/local/bin/cp-wrapper << 'EOF'
#!/bin/bash
if [[ "$1" == *"catalog-deployment-v2.yaml"* ]] && [[ "$2" == *"catalog-deployment.yaml"* ]]; then
  touch /tmp/replica-state
else
  /bin/cp "$@"
fi
EOF

chmod +x /usr/local/bin/cp-wrapper
echo "alias cp='/usr/local/bin/cp-wrapper'" >> /home/cloud_user/.bashrc

# Create kill wrapper for background jobs
cat > /usr/local/bin/kill-wrapper << 'EOF'
#!/bin/bash
if [[ "$1" == "%1" ]]; then
  echo "[1]+  Terminated              kubectl port-forward -n carvedrock svc/catalog-service 8081:80 --address=0.0.0.0"
else
  /bin/kill "$@"
fi
EOF

chmod +x /usr/local/bin/kill-wrapper
echo "alias kill='/usr/local/bin/kill-wrapper'" >> /home/cloud_user/.bashrc

# Make aliases available immediately
echo "source ~/.bashrc" >> /home/cloud_user/.bash_profile

# Set ownership
chown -R cloud_user:cloud_user /home/cloud_user/

# Clean up any temp files
rm -f /tmp/replica-state /tmp/sync-state /tmp/revert-state

# Kill any existing processes on ports 8080 and 8081
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:8081 | xargs kill -9 2>/dev/null || true
rm -f /tmp/port-forward-*.pid
EOF
