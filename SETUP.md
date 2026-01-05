# 🛠️ Guia de Setup - Desafios de Troubleshooting Kubernetes

Este guia contém instruções detalhadas para criar todos os cenários de falha dos desafios de troubleshooting.

---

## 📋 Pré-requisitos

### Ferramentas necessárias:
- Kubernetes cluster (Minikube, Kind, k3s, ou cluster em cloud)
- kubectl instalado e configurado
- (Opcional) k9s para interface visual
- (Opcional) Metrics server para desafios de HPA

### Verificar ambiente:
```bash
kubectl version --short
kubectl cluster-info
kubectl get nodes
```

---

## 🟢 Setup Nível 1 - Iniciante

### Desafio 1.1: ImagePullBackOff

**Objetivo:** Criar pod com imagem inexistente

```bash
# Criar namespace
kubectl create namespace desafio-1-1

# Criar deployment com imagem errada
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-nginx
  namespace: desafio-1-1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginxx:latest  # ERRO PROPOSITAL: imagem não existe
        ports:
        - containerPort: 80
EOF

# Verificar que o pod está com ImagePullBackOff
kubectl get pods -n desafio-1-1

# Para remover após resolver:
# kubectl delete namespace desafio-1-1
```

---

### Desafio 1.2: CrashLoopBackOff

**Objetivo:** Criar pod que crasha por configuração errada

```bash
# Criar namespace
kubectl create namespace desafio-1-2

# Criar ConfigMap com app Node.js simples
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-code
  namespace: desafio-1-2
data:
  server.js: |
    const http = require('http');
    const port = process.env.PORT || 3000;
    
    const server = http.createServer((req, res) => {
      res.writeHead(200);
      res.end('Hello World!');
    });
    
    server.listen(port, () => {
      console.log(\`Server running on port \${port}\`);
    });
EOF

# Criar deployment com porta errada
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-backend
  namespace: desafio-1-2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: node:16-alpine
        command: ["node", "/app/server.js"]
        env:
        - name: PORT
          value: "8080"  # ERRO PROPOSITAL: app espera porta 3000 por padrão
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: app-code
          mountPath: /app
      volumes:
      - name: app-code
        configMap:
          name: app-code
EOF

# Verificar CrashLoopBackOff
kubectl get pods -n desafio-1-2 -w

# Para remover:
# kubectl delete namespace desafio-1-2
```

---

### Desafio 1.3: Service sem endpoints

**Objetivo:** Service com selector incorreto

```bash
# Criar namespace
kubectl create namespace desafio-1-3

# Criar deployment com label correto
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: desafio-1-3
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Criar service com selector ERRADO
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: desafio-1-3
spec:
  selector:
    app: front  # ERRO PROPOSITAL: deveria ser 'frontend'
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Verificar que não há endpoints
kubectl get endpoints -n desafio-1-3

# Para remover:
# kubectl delete namespace desafio-1-3
```

---

### Desafio 1.4: ConfigMap não aplicado

**Objetivo:** Pod sem referência ao ConfigMap

```bash
# Criar namespace
kubectl create namespace desafio-1-4

# Criar ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: desafio-1-4
data:
  APP_ENV: "production"
  APP_DEBUG: "false"
  DATABASE_HOST: "db.example.com"
EOF

# Criar deployment SEM referência ao ConfigMap
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: desafio-1-4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        # ERRO PROPOSITAL: falta envFrom para carregar ConfigMap
EOF

# Verificar que variáveis não estão presentes
kubectl exec -n desafio-1-4 $(kubectl get pod -n desafio-1-4 -o jsonpath='{.items[0].metadata.name}') -- env | grep APP_

# Para remover:
# kubectl delete namespace desafio-1-4
```

---

## 🟡 Setup Nível 2 - Intermediário

### Desafio 2.1: OOMKilled

**Objetivo:** Pod com limite de memória muito baixo

```bash
# Criar namespace
kubectl create namespace desafio-2-1

# Criar deployment que consome muita memória
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-processor
  namespace: desafio-2-1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: processor
  template:
    metadata:
      labels:
        app: processor
    spec:
      containers:
      - name: processor
        image: python:3.9-slim
        command: ["python", "-c"]
        args:
        - |
          import time
          data = []
          while True:
              # Consumir memória propositalmente
              data.append(' ' * 10**6)
              print(f"Memory allocated: {len(data)} MB")
              time.sleep(1)
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"  # ERRO PROPOSITAL: muito pouco
            cpu: "200m"
EOF

# Verificar OOMKilled
kubectl get pods -n desafio-2-1 -w

# Para remover:
# kubectl delete namespace desafio-2-1
```

---

### Desafio 2.2: Health checks incorretos

**Objetivo:** Readiness probe com endpoint errado

```bash
# Criar namespace
kubectl create namespace desafio-2-2

# Criar deployment com health check endpoint errado
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthcheck-app
  namespace: desafio-2-2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: healthcheck
  template:
    metadata:
      labels:
        app: healthcheck
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:0.2.3
        args:
        - -text=OK
        - -listen=:8080
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz  # ERRO PROPOSITAL: endpoint não existe
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /healthz  # ERRO PROPOSITAL: deveria ser /
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
EOF

# Verificar probe failures
kubectl describe pod -n desafio-2-2 $(kubectl get pod -n desafio-2-2 -o jsonpath='{.items[0].metadata.name}')

# Para remover:
# kubectl delete namespace desafio-2-2
```

---

### Desafio 2.3: Sem persistência

**Objetivo:** Postgres sem volume persistente

```bash
# Criar namespace
kubectl create namespace desafio-2-3

# Criar Postgres SEM PVC (dados perdidos ao reiniciar)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
  namespace: desafio-2-3
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "secretpassword"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        # ERRO PROPOSITAL: sem volumeMounts, dados em emptyDir (temporário)
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        emptyDir: {}  # Dados perdidos ao reiniciar pod!
EOF

# Testar perda de dados
kubectl exec -n desafio-2-3 $(kubectl get pod -n desafio-2-3 -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -c "CREATE TABLE test (id INT);"
kubectl delete pod -n desafio-2-3 -l app=postgres
# Aguardar pod recriar
sleep 20
kubectl exec -n desafio-2-3 $(kubectl get pod -n desafio-2-3 -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -c "SELECT * FROM test;"
# Erro: relation "test" does not exist

# Para remover:
# kubectl delete namespace desafio-2-3
```

---

### Desafio 2.4: Network Policy bloqueando

**Objetivo:** Network policy deny-all sem allows

```bash
# Criar namespace
kubectl create namespace desafio-2-4

# Criar frontend e backend
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: desafio-2-4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: busybox
        command: ["sleep", "3600"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: desafio-2-4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: hashicorp/http-echo:0.2.3
        args: ["-text=Backend Response"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: desafio-2-4
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 5678
EOF

# Aguardar pods ficarem prontos
kubectl wait --for=condition=ready pod -l app=backend -n desafio-2-4 --timeout=60s
kubectl wait --for=condition=ready pod -l app=frontend -n desafio-2-4 --timeout=60s

# Criar Network Policy deny-all
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: desafio-2-4
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Testar conectividade (deve falhar)
kubectl exec -n desafio-2-4 $(kubectl get pod -n desafio-2-4 -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- wget -T 5 -O- backend-service:8080
# Timeout

# Para remover:
# kubectl delete namespace desafio-2-4
```

---

### Desafio 2.5: Secret mal montado

**Objetivo:** Secret montado em caminho errado

```bash
# Criar namespace
kubectl create namespace desafio-2-5

# Criar Secret
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret123 \
  -n desafio-2-5

# Criar deployment com mountPath errado
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: desafio-2-5
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: busybox
        command: ["sh", "-c"]
        args:
        - |
          echo "Trying to read credentials from /etc/secrets..."
          if [ -f /etc/secrets/username ]; then
            echo "Found username: $(cat /etc/secrets/username)"
          else
            echo "ERROR: Credentials not found in /etc/secrets"
          fi
          sleep 3600
        volumeMounts:
        - name: secrets
          mountPath: /secrets/db  # ERRO PROPOSITAL: app espera /etc/secrets
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: db-credentials
EOF

# Verificar logs mostrando erro
kubectl logs -n desafio-2-5 $(kubectl get pod -n desafio-2-5 -o jsonpath='{.items[0].metadata.name}')

# Para remover:
# kubectl delete namespace desafio-2-5
```

---

## 🟠 Setup Nível 3 - Avançado

### Desafio 3.1: DNS não funcionando

**Objetivo:** Simular problema com CoreDNS

```bash
# Criar namespace
kubectl create namespace desafio-3-1

# Criar pod de teste
kubectl run test-pod --image=busybox --command -n desafio-3-1 -- sleep 3600

# Escalar CoreDNS para 0 (simular problema)
kubectl scale deployment coredns --replicas=0 -n kube-system

# Testar DNS (deve falhar)
kubectl exec test-pod -n desafio-3-1 -- nslookup kubernetes.default

# NOTA: Para resolver, precisará escalar CoreDNS de volta:
# kubectl scale deployment coredns --replicas=2 -n kube-system

# Para remover:
# kubectl delete namespace desafio-3-1
```

**⚠️ CUIDADO:** Este desafio afeta o cluster todo. Use apenas em ambiente de teste!

---

### Desafio 3.2: Ingress mal configurado

**Objetivo:** Ingress com backend incorreto

```bash
# Verificar se Ingress Controller está instalado
kubectl get pods -n ingress-nginx

# Se não estiver, instalar
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Criar namespace
kubectl create namespace desafio-3-2

# Criar services
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: desafio-3-2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:0.2.3
        args: ["-text=API Response"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: desafio-3-2
spec:
  selector:
    app: api
  ports:
  - port: 8080
    targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: desafio-3-2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: hashicorp/http-echo:0.2.3
        args: ["-text=Frontend Response"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: desafio-3-2
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 5678
EOF

# Criar Ingress com nome de service ERRADO
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: desafio-3-2
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc  # ERRO PROPOSITAL: service se chama 'api-service'
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF

# Testar (deve dar 503 para /api)
# kubectl get ingress -n desafio-3-2
# curl -H "Host: app.example.com" http://<INGRESS-IP>/api

# Para remover:
# kubectl delete namespace desafio-3-2
```

---

### Desafio 3.3: StatefulSet sem PVs

**Objetivo:** StatefulSet com PVCs pending

```bash
# Criar namespace
kubectl create namespace desafio-3-3

# Desabilitar StorageClass default (se houver)
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Criar StatefulSet que vai ficar com PVCs pending
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
  namespace: desafio-3-3
spec:
  clusterIP: None
  selector:
    app: kafka
  ports:
  - port: 9092
    name: kafka
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: desafio-3-3
spec:
  serviceName: kafka-headless
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: busybox
        command: ["sleep", "3600"]
        volumeMounts:
        - name: kafka-data
          mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
  - metadata:
      name: kafka-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      # ERRO PROPOSITAL: sem storageClassName e sem default
      resources:
        requests:
          storage: 10Gi
EOF

# Verificar PVCs pending
kubectl get pvc -n desafio-3-3

# Para remover:
# kubectl delete namespace desafio-3-3
# Reativar default StorageClass
# kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

### Desafio 3.4: HPA sem metrics-server

**Objetivo:** HPA sem conseguir obter métricas

```bash
# Verificar se metrics-server existe e deletar (simular problema)
kubectl delete deployment metrics-server -n kube-system 2>/dev/null || true

# Criar namespace
kubectl create namespace desafio-3-4

# Criar deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: desafio-3-4
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: webapp
  namespace: desafio-3-4
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
EOF

# Criar HPA
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: desafio-3-4
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

# Verificar HPA (deve mostrar <unknown>)
kubectl get hpa -n desafio-3-4

# Para remover:
# kubectl delete namespace desafio-3-4
# Reinstalar metrics-server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

### Desafio 3.5: RBAC sem permissões

**Objetivo:** ServiceAccount sem Role/RoleBinding

```bash
# Criar namespace
kubectl create namespace desafio-3-5

# Criar ServiceAccount SEM permissões
kubectl create serviceaccount app-sa -n desafio-3-5

# Criar pod que tenta listar pods (vai falhar)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-rbac
  namespace: desafio-3-5
spec:
  serviceAccountName: app-sa
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sh", "-c"]
    args:
    - |
      echo "Attempting to list pods..."
      kubectl get pods -n desafio-3-5 || echo "FAILED: No permissions"
      sleep 3600
EOF

# Verificar logs (deve mostrar erro de permissão)
kubectl logs test-rbac -n desafio-3-5

# Para remover:
# kubectl delete namespace desafio-3-5
```

---

## 🔴 Setup Nível 4 - Expert

### Desafio 4.1: Node NotReady

**Objetivo:** Simular node com problemas

```bash
# ⚠️ CUIDADO: Isso afeta um node real do cluster!
# Use apenas em ambiente de teste com múltiplos nodes

# Escolher um node worker (não master)
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.name!="minikube")].metadata.name}' | awk '{print $1}')

# Se estiver usando Minikube com apenas 1 node, pular este desafio
# ou adicionar nodes: minikube node add

# Simular disco cheio no node (via SSH ou kubectl debug)
kubectl debug node/$NODE_NAME -it --image=ubuntu -- chroot /host bash -c "dd if=/dev/zero of=/var/test.img bs=1G count=100"

# Verificar status do node
kubectl get nodes

# NOTA: Para limpar, conectar ao node e deletar o arquivo
# kubectl debug node/$NODE_NAME -it --image=ubuntu -- chroot /host bash -c "rm /var/test.img"
```

**⚠️ Use com extrema cautela!** Pode tornar o cluster instável.

---

### Desafio 4.2: Certificados expirados

**Objetivo:** Simular certificados próximos de expirar

```bash
# Verificar certificados atuais
sudo kubeadm certs check-expiration

# Este desafio é mais educacional
# Para criar cenário real, seria necessário alterar data do sistema
# ou esperar certificados expirarem naturalmente (não recomendado)

# Mostrar como verificar
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 Validity
```

**NOTA:** Este desafio é melhor feito como exercício teórico ou em cluster dedicado para testes.

---

### Desafio 4.3: StorageClass sem provisioner

**Objetivo:** PVCs pending por falta de provisioner

```bash
# Criar namespace
kubectl create namespace desafio-4-3

# Remover annotation default de todas StorageClasses
for sc in $(kubectl get sc -o name); do
  kubectl annotate $sc storageclass.kubernetes.io/is-default-class-
done

# Criar PVC sem StorageClass específica
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: desafio-4-3
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

# Verificar PVC pending
kubectl get pvc -n desafio-4-3

# Para remover:
# kubectl delete namespace desafio-4-3
# Restaurar default StorageClass
# kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

### Desafio 4.4: Performance e latência

**Objetivo:** Pods em zonas diferentes causando latência

```bash
# Este desafio requer cluster multi-AZ (AWS, GCP, Azure)
# Para simular em cluster local, podemos usar labels

# Criar namespace
kubectl create namespace desafio-4-4

# Adicionar labels simulando zonas diferentes
kubectl label node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') topology.kubernetes.io/zone=zone-a
kubectl label node $(kubectl get nodes -o jsonpath='{.items[1].metadata.name}') topology.kubernetes.io/zone=zone-b 2>/dev/null || true

# Criar banco de dados em uma zona
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: desafio-4-4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      nodeSelector:
        topology.kubernetes.io/zone: zone-b
      containers:
      - name: postgres
        image: postgres:14-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: password
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: desafio-4-4
spec:
  selector:
    app: database
  ports:
  - port: 5432
EOF

# Criar app em zona diferente
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: desafio-4-4
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      nodeSelector:
        topology.kubernetes.io/zone: zone-a
      containers:
      - name: app
        image: busybox
        command: ["sh", "-c", "while true; do time nc -zv database 5432; sleep 5; done"]
EOF

# Verificar latência nos logs
kubectl logs -n desafio-4-4 -l app=myapp

# Para remover:
# kubectl delete namespace desafio-4-4
```

---

### Desafio 4.5: ResourceQuota excedida

**Objetivo:** Namespace com quota esgotada

```bash
# Criar namespace
kubectl create namespace desafio-4-5

# Criar ResourceQuota restritiva
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: desafio-4-5
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "10"
EOF

# Criar LimitRange com defaults altos
kubectl apply -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: desafio-4-5
spec:
  limits:
  - max:
      cpu: "2"
      memory: 2Gi
    default:
      cpu: "500m"  # Alto
      memory: 512Mi  # Alto
    defaultRequest:
      cpu: "250m"  # Alto
      memory: 256Mi  # Alto
    type: Container
EOF

# Criar deployment que consome toda a quota
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: desafio-4-5
spec:
  replicas: 4  # 4 pods × 250m = 1000m (toda a quota de CPU)
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app
        image: nginx:alpine
EOF

# Tentar criar outro deployment (vai falhar por quota)
kubectl run test --image=nginx -n desafio-4-5
# Error: exceeded quota

# Verificar quota
kubectl describe resourcequota -n desafio-4-5

# Para remover:
# kubectl delete namespace desafio-4-5
```

---

### Desafio 4.6: Rolling update travado

**Objetivo:** Rollout travado por nova versão com erro

```bash
# Criar namespace
kubectl create namespace desafio-4-6

# Criar versão inicial (funcional)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: desafio-4-6
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:0.2.3
        args: ["-text=Version 1 - OK"]
        ports:
        - containerPort: 5678
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# Aguardar deployment estar pronto
kubectl rollout status deployment/app -n desafio-4-6

# Fazer update para versão com erro
kubectl set image deployment/app app=hashicorp/http-echo:0.2.3 -n desafio-4-6
kubectl patch deployment app -n desafio-4-6 --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["-text=Version 2 - Broken"]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/path", "value": "/health"},
  {"op": "replace", "path": "/spec/template/metadata/labels/version", "value": "v2"}
]'

# Rollout vai travar pois novo pod não passa no readiness
kubectl rollout status deployment/app -n desafio-4-6 --watch
# Vai ficar esperando indefinidamente

# Verificar estado
kubectl get replicaset -n desafio-4-6
kubectl get pods -n desafio-4-6

# Para remover:
# kubectl delete namespace desafio-4-6
```

---

## 🧹 Limpeza Completa

Para remover todos os namespaces de desafios:

```bash
# Listar todos os namespaces de desafio
kubectl get ns | grep desafio

# Deletar todos de uma vez
for ns in $(kubectl get ns -o name | grep desafio); do
  kubectl delete $ns
done

# Restaurar configurações do cluster
kubectl scale deployment coredns --replicas=2 -n kube-system

# Restaurar StorageClass default
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Reinstalar metrics-server se necessário
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## 📝 Notas Importantes

### ⚠️ Avisos de Segurança

1. **Nunca execute estes cenários em produção**
2. **Use cluster dedicado para testes**
3. **Alguns cenários afetam o cluster inteiro** (ex: escalar CoreDNS para 0)
4. **Faça backup das configurações antes de modificar**
5. **Documente o que alterou para poder reverter**

### 💡 Dicas

- Use `kubectl config view` para verificar contexto atual
- Crie um cluster separado (Minikube, Kind) para cada sessão de prática
- Use aliases para comandos frequentes:
  ```bash
  alias k=kubectl
  alias kgp='kubectl get pods'
  alias kdp='kubectl describe pod'
  ```

### 🔄 Reset Rápido

Se precisar resetar o cluster de teste:

```bash
# Minikube
minikube delete
minikube start

# Kind
kind delete cluster --name desafio
kind create cluster --name desafio

# K3s
sudo systemctl stop k3s
sudo rm -rf /var/lib/rancher/k3s
sudo systemctl start k3s
```

---

## 🎯 Próximos Passos

1. Escolha um nível de dificuldade adequado
2. Execute os comandos de setup
3. Tente resolver usando apenas `kubectl` e o arquivo `DESAFIOS.md`
4. Consulte `SOLUCOES.md` apenas quando travar
5. Documente seu processo de troubleshooting
6. Crie seus próprios cenários de falha!

---

**Bom troubleshooting! 🚀**
