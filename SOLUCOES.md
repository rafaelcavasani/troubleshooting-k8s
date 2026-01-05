# 🔑 Soluções dos Desafios de Troubleshooting Kubernetes

---

## 🟢 Nível 1 - Iniciante

### Solução 1.1: Pod que não inicia (ImagePullBackOff)

**Problema:**
A imagem especificada no deployment está com nome errado ou não existe no registry.

**Diagnóstico:**
```bash
kubectl get pods -n desafio-1-1
# Output: STATUS = ImagePullBackOff

kubectl describe pod <pod-name> -n desafio-1-1
# Output: Failed to pull image "nginxx:latest": rpc error: code = Unknown desc = Error response from daemon: pull access denied for nginxx
```

**Causa:**
O nome da imagem está errado: `nginxx` ao invés de `nginx`.

**Solução:**
```bash
# Editar o deployment
kubectl edit deployment webapp-nginx -n desafio-1-1

# Ou aplicar o arquivo corrigido
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
        image: nginx:latest  # Corrigido de 'nginxx' para 'nginx'
        ports:
        - containerPort: 80
EOF

# Verificar
kubectl get pods -n desafio-1-1 -w
```

**Pontos-chave:**
- Sempre verificar o nome correto da imagem
- Usar `describe pod` para ver eventos detalhados
- Verificar se a imagem existe no registry

---

### Solução 1.2: Pod crashando constantemente (CrashLoopBackOff)

**Problema:**
A aplicação está tentando ouvir na porta 3000, mas o container está configurado para porta 8080.

**Diagnóstico:**
```bash
kubectl get pods -n desafio-1-2
# Output: STATUS = CrashLoopBackOff, RESTARTS = 5

kubectl logs <pod-name> -n desafio-1-2
# Output: Error: listen EADDRINUSE: address already in use :::8080

kubectl describe pod <pod-name> -n desafio-1-2
# Verificar a variável de ambiente PORT
```

**Causa:**
A variável de ambiente `PORT` está definida como 8080, mas a aplicação espera porta 3000.

**Solução:**
```bash
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
        command: ["node", "server.js"]
        env:
        - name: PORT
          value: "3000"  # Corrigido de 8080 para 3000
        ports:
        - containerPort: 3000
EOF

# Verificar logs
kubectl logs <pod-name> -n desafio-1-2 -f
```

**Pontos-chave:**
- Sempre verificar logs primeiro
- Variáveis de ambiente incorretas são causa comum
- Verificar se portas estão conflitando

---

### Solução 1.3: Service não expondo o pod

**Problema:**
Os labels do service não correspondem aos labels dos pods.

**Diagnóstico:**
```bash
kubectl get pods -n desafio-1-3 --show-labels
# Output: app=frontend

kubectl get svc frontend-service -n desafio-1-3 -o yaml
# Selector: app=front (ERRADO!)

kubectl get endpoints frontend-service -n desafio-1-3
# Output: <none> (Sem endpoints!)
```

**Causa:**
O selector do service é `app=front`, mas o label do pod é `app=frontend`.

**Solução:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: desafio-1-3
spec:
  selector:
    app: frontend  # Corrigido de 'front' para 'frontend'
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Verificar endpoints
kubectl get endpoints frontend-service -n desafio-1-3
# Agora deve mostrar os IPs dos pods

# Testar conectividade
kubectl run test-pod --image=busybox -n desafio-1-3 --rm -it --restart=Never -- wget -O- frontend-service:80
```

**Pontos-chave:**
- Labels devem corresponder exatamente
- Verificar endpoints para confirmar associação
- Testar conectividade de dentro do cluster

---

### Solução 1.4: ConfigMap não aplicado

**Problema:**
O nome do ConfigMap no pod está errado ou não existe referência.

**Diagnóstico:**
```bash
kubectl get configmap -n desafio-1-4
# Output: app-config

kubectl describe pod <pod-name> -n desafio-1-4
# Verificar se há referência ao ConfigMap

kubectl exec <pod-name> -n desafio-1-4 -- env | grep APP_
# Variáveis não aparecem
```

**Causa:**
O pod não está configurado para carregar o ConfigMap.

**Solução:**
```bash
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
---
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
        envFrom:
        - configMapRef:
            name: app-config  # Adicionar referência ao ConfigMap
EOF

# Verificar variáveis
kubectl exec <pod-name> -n desafio-1-4 -- env | grep APP_
```

**Pontos-chave:**
- ConfigMap precisa ser referenciado no pod
- Usar `envFrom` para carregar todas as variáveis
- Pods existentes precisam ser recriados para pegar mudanças

---

## 🟡 Nível 2 - Intermediário

### Solução 2.1: Problemas de recurso (OOMKilled)

**Problema:**
O limite de memória está muito baixo para a carga de trabalho.

**Diagnóstico:**
```bash
kubectl get pods -n desafio-2-1
# Output: RESTARTS = 5+

kubectl describe pod <pod-name> -n desafio-2-1
# Output: Last State: Terminated, Reason: OOMKilled

kubectl top pod <pod-name> -n desafio-2-1
# Mostra uso próximo ou acima do limite
```

**Causa:**
Memória limitada a 128Mi, mas aplicação precisa de pelo menos 256Mi.

**Solução:**
```bash
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
        image: data-app:v1
        resources:
          requests:
            memory: "256Mi"  # Aumentado
            cpu: "100m"
          limits:
            memory: "512Mi"  # Aumentado de 128Mi
            cpu: "500m"
EOF

# Monitorar
kubectl top pod -n desafio-2-1 --watch
```

**Pontos-chave:**
- OOMKilled indica memória insuficiente
- Requests: mínimo necessário
- Limits: máximo permitido
- Monitorar uso real para ajustar

---

### Solução 2.2: Liveness e Readiness Probes

**Problema:**
O readiness probe está verificando um endpoint que não existe ou demora muito para responder.

**Diagnóstico:**
```bash
kubectl describe pod <pod-name> -n desafio-2-2
# Output: Readiness probe failed: HTTP probe failed with statuscode: 404

kubectl logs <pod-name> -n desafio-2-2
# Aplicação está rodando na porta 8080, endpoint /health
```

**Causa:**
O probe está verificando `/healthz` (que não existe), deveria ser `/health`.

**Solução:**
```bash
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
        image: health-app:v1
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /health  # Corrigido de /healthz
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health  # Corrigido de /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 3
EOF
```

**Pontos-chave:**
- Liveness: reinicia se falhar (usar com cuidado)
- Readiness: remove do service se falhar
- Ajustar timeouts para aplicação específica
- initialDelaySeconds deve cobrir tempo de startup

---

### Solução 2.3: Problemas de persistência

**Problema:**
Pod não tem PVC configurado, então dados são perdidos no restart.

**Diagnóstico:**
```bash
kubectl get pvc -n desafio-2-3
# Output: No resources found

kubectl describe pod postgres-db -n desafio-2-3
# Volumes: EmptyDir (temporário!)
```

**Causa:**
Falta criar PVC e associar ao pod.

**Solução:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: desafio-2-3
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-db
  namespace: desafio-2-3
spec:
  serviceName: postgres
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
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: "secretpassword"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
EOF

# Verificar PVC
kubectl get pvc -n desafio-2-3
# STATUS: Bound

# Testar persistência
kubectl exec postgres-db-0 -n desafio-2-3 -- psql -U postgres -c "CREATE TABLE test (id INT);"
kubectl delete pod postgres-db-0 -n desafio-2-3
# Aguardar recriação e verificar se tabela ainda existe
```

**Pontos-chave:**
- Usar StatefulSet para aplicações stateful
- PVC garante persistência entre restarts
- volumeClaimTemplates criam PVCs automaticamente
- PGDATA em subdiretório evita problemas de permissão

---

### Solução 2.4: Network Policy bloqueando comunicação

**Problema:**
Uma Network Policy está negando tráfego do frontend para o backend.

**Diagnóstico:**
```bash
kubectl get networkpolicy -n desafio-2-4
# Output: deny-all

kubectl describe networkpolicy deny-all -n desafio-2-4
# Bloqueia todo ingress

# Testar conectividade
kubectl exec frontend-pod -n desafio-2-4 -- curl backend-service:8080 --connect-timeout 5
# Output: Timeout
```

**Causa:**
Existe uma política "deny-all" sem políticas de allow específicas.

**Solução:**
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: desafio-2-4
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF

# Testar conectividade novamente
kubectl exec frontend-pod -n desafio-2-4 -- curl backend-service:8080
# Output: 200 OK
```

**Pontos-chave:**
- Network Policies são aditivas
- Default é allow-all (se não houver policies)
- Uma policy deny-all requer policies allow específicas
- Testar conectividade após cada mudança

---

### Solução 2.5: Secret não montado corretamente

**Problema:**
O Secret existe, mas o caminho de montagem está errado.

**Diagnóstico:**
```bash
kubectl get secret -n desafio-2-5
# Output: db-credentials

kubectl describe pod <pod-name> -n desafio-2-5
# Mounts: /secrets/db (mas app procura em /etc/secrets)

kubectl exec <pod-name> -n desafio-2-5 -- ls -la /etc/secrets
# Output: No such file or directory
```

**Causa:**
Volume montado em `/secrets/db`, mas aplicação espera `/etc/secrets`.

**Solução:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: desafio-2-5
type: Opaque
stringData:
  username: admin
  password: supersecret123
---
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
        image: myapp:v1
        volumeMounts:
        - name: secrets
          mountPath: /etc/secrets  # Corrigido o path
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: db-credentials
EOF

# Verificar
kubectl exec <pod-name> -n desafio-2-5 -- cat /etc/secrets/username
# Output: admin
```

**Pontos-chave:**
- mountPath deve corresponder ao esperado pela aplicação
- Secrets são montados como arquivos individuais
- readOnly é boa prática para secrets
- Usar stringData para criar secrets em texto plano (será codificado)

---

## 🟠 Nível 3 - Avançado

### Solução 3.1: Problemas de DNS interno

**Problema:**
CoreDNS não está funcionando ou configuração incorreta.

**Diagnóstico:**
```bash
kubectl get pods -n kube-system | grep coredns
# Output: coredns pods com problemas

kubectl logs coredns-xxx -n kube-system
# Erros de configuração

kubectl exec test-pod -n desafio-3-1 -- nslookup kubernetes.default
# Output: NXDOMAIN
```

**Causa:**
CoreDNS com ConfigMap incorreto ou pods sem recursos.

**Solução:**
```bash
# Verificar ConfigMap do CoreDNS
kubectl get configmap coredns -n kube-system -o yaml

# Se necessário, corrigir
kubectl edit configmap coredns -n kube-system

# Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Verificar recursos
kubectl top pod -n kube-system | grep coredns

# Se falta recursos, aumentar
kubectl edit deployment coredns -n kube-system
# Aumentar resources.limits e requests

# Testar DNS
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
# Output: Server e Address corretos

# Verificar configuração de DNS nos pods
kubectl run test-pod --image=busybox --rm -it --restart=Never -- cat /etc/resolv.conf
# Deve apontar para IP do ClusterIP do kube-dns service
```

**Pontos-chave:**
- CoreDNS é crítico para service discovery
- Verificar logs, recursos e configuração
- Testar resolução com nslookup/dig
- Pods herdam configuração DNS do node

---

### Solução 3.2: Ingress não roteando corretamente

**Problema:**
Backend path ou service name incorretos no Ingress.

**Diagnóstico:**
```bash
kubectl get ingress -n desafio-3-2
kubectl describe ingress app-ingress -n desafio-3-2
# Rules apontando para service errado

kubectl get svc -n desafio-3-2
# Service correto: api-service

kubectl logs -n ingress-nginx <ingress-controller-pod>
# Erros 404 ou backend não encontrado
```

**Causa:**
Ingress aponta para `api-svc` mas o service se chama `api-service`.

**Solução:**
```bash
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
            name: api-service  # Corrigido de 'api-svc'
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

# Testar
curl -H "Host: app.example.com" http://<ingress-ip>/api/health

# Verificar backends no controller
kubectl exec -n ingress-nginx <controller-pod> -- cat /etc/nginx/nginx.conf | grep -A 10 api-service
```

**Pontos-chave:**
- Nome do service deve corresponder exatamente
- Verificar porta do service
- pathType: Prefix vs Exact
- Annotations específicas do controller
- Testar com curl incluindo header Host

---

### Solução 3.3: StatefulSet com problemas de ordenação

**Problema:**
PVCs não criados ou pods dependentes iniciando fora de ordem.

**Diagnóstico:**
```bash
kubectl get statefulset,pods -n desafio-3-3
# kafka-0: Running, kafka-1: Pending, kafka-2: Pending

kubectl describe pod kafka-1 -n desafio-3-3
# Events: FailedScheduling: pod has unbound immediate PersistentVolumeClaims

kubectl get pvc -n desafio-3-3
# kafka-data-kafka-1: Pending (sem PV disponível)
```

**Causa:**
StorageClass não provisiona volumes automaticamente ou falta PVs.

**Solução:**
```bash
# Verificar StorageClass
kubectl get storageclass
# Se não houver default, criar ou usar uma existente

# Aplicar StatefulSet corrigido
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
        image: confluentinc/cp-kafka:7.0.0
        ports:
        - containerPort: 9092
        env:
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: "zookeeper:2181"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: "PLAINTEXT://$(POD_NAME).kafka-headless:9092"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: kafka-data
          mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
  - metadata:
      name: kafka-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard  # Especificar StorageClass válida
      resources:
        requests:
          storage: 10Gi
EOF

# Aguardar criação ordenada
kubectl get pods -n desafio-3-3 -w
# kafka-0 -> Running, depois kafka-1 -> Running, depois kafka-2 -> Running

# Verificar PVCs
kubectl get pvc -n desafio-3-3
# Todos Bound
```

**Pontos-chave:**
- StatefulSet cria pods em ordem (0, 1, 2...)
- Cada pod precisa de seu PVC antes de iniciar
- volumeClaimTemplates cria PVCs automaticamente
- Headless service necessário para DNS estável
- PodManagementPolicy: OrderedReady (default) vs Parallel

---

### Solução 3.4: HPA não escalando

**Problema:**
Metrics server não instalado ou pods sem resource requests.

**Diagnóstico:**
```bash
kubectl get hpa -n desafio-3-4
# Output: <unknown>/50% (targets não disponíveis)

kubectl top pods -n desafio-3-4
# Error: Metrics API not available

kubectl get deployment metrics-server -n kube-system
# Output: No resources found (metrics-server não instalado!)
```

**Causa:**
Metrics server não instalado e deployment sem resource requests.

**Solução:**
```bash
# Instalar metrics-server (se necessário)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Para clusters de desenvolvimento, pode precisar de flag adicional
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Aguardar metrics-server ficar pronto
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s

# Corrigir deployment com resource requests
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
        image: php-apache
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m  # ESSENCIAL para HPA funcionar!
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
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

# Verificar HPA
kubectl get hpa -n desafio-3-4 -w
# Agora deve mostrar TARGETS: 0%/50%

# Gerar carga para testar
kubectl run load-generator --image=busybox --rm -it --restart=Never -n desafio-3-4 -- \
  /bin/sh -c "while true; do wget -q -O- http://webapp; done"

# Observar escalonamento
kubectl get hpa -n desafio-3-4 -w
# TARGETS aumenta -> REPLICAS aumenta
```

**Pontos-chave:**
- HPA requer metrics-server funcionando
- Pods DEVEM ter resource requests definidos
- HPA calcula com base em % de requests (não limits)
- Escalonamento leva 15-30s para reagir
- Use autoscaling/v2 para múltiplas métricas

---

### Solução 3.5: RBAC bloqueando acesso

**Problema:**
ServiceAccount sem permissões adequadas (sem Role/RoleBinding).

**Diagnóstico:**
```bash
kubectl get serviceaccount app-sa -n desafio-3-5
# Output: app-sa existe

kubectl get role,rolebinding -n desafio-3-5
# Output: No resources found (falta Role!)

kubectl auth can-i list pods --as=system:serviceaccount:desafio-3-5:app-sa -n desafio-3-5
# Output: no
```

**Causa:**
ServiceAccount criada, mas sem Role e RoleBinding associados.

**Solução:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: desafio-3-5
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: desafio-3-5
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-sa-pod-reader
  namespace: desafio-3-5
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: desafio-3-5
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# Verificar permissões
kubectl auth can-i list pods --as=system:serviceaccount:desafio-3-5:app-sa -n desafio-3-5
# Output: yes

# Testar com pod usando a ServiceAccount
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
    command: ["sleep", "3600"]
EOF

kubectl exec test-rbac -n desafio-3-5 -- kubectl get pods -n desafio-3-5
# Output: Lista de pods (sucesso!)
```

**Pontos-chave:**
- ServiceAccount: identidade do pod
- Role: define permissões (namespace-scoped)
- ClusterRole: permissões cluster-wide
- RoleBinding: associa SA ao Role
- Usar `kubectl auth can-i` para testar permissões
- Princípio do menor privilégio

---

## 🔴 Nível 4 - Expert

### Solução 4.1: Cluster Node NotReady

**Problema:**
Kubelet parado, disco cheio, ou problemas de rede.

**Diagnóstico:**
```bash
kubectl get nodes
# Output: node-2 NotReady

kubectl describe node node-2
# Conditions:
#   DiskPressure: True (disk full!)
#   MemoryPressure: False
#   Ready: False

# Se tiver acesso SSH ao node
ssh node-2
df -h
# Output: /var 100% usado

du -sh /var/lib/* | sort -h
# Identificar o que está consumindo espaço
```

**Causa:**
Disco cheio por logs ou imagens antigas.

**Solução:**
```bash
# No node (via SSH)
# Limpar logs antigos
sudo journalctl --vacuum-time=2d
sudo truncate -s 0 /var/log/syslog

# Limpar imagens Docker/containerd não utilizadas
sudo crictl rmi --prune
# ou se usar Docker
sudo docker system prune -a --volumes -f

# Verificar espaço
df -h /var

# Reiniciar kubelet se necessário
sudo systemctl restart kubelet

# Verificar status do kubelet
sudo systemctl status kubelet

# Do control plane, aguardar node voltar
kubectl get nodes -w
# node-2 volta para Ready

# Se node não puder ser recuperado, drenar e remover
kubectl cordon node-2  # Marca como unschedulable
kubectl drain node-2 --ignore-daemonsets --delete-emptydir-data
kubectl delete node node-2
```

**Pontos-chave:**
- Monitorar uso de disco nos nodes
- Configurar log rotation
- Política de retenção de imagens
- Drenar antes de remover node
- Ter alertas para node NotReady

---

### Solução 4.2: Problemas de certificados

**Problema:**
Certificados expirados ou mal configurados.

**Diagnóstico:**
```bash
# Verificar certificados
sudo kubeadm certs check-expiration

# Verificar logs do API server
kubectl logs kube-apiserver-xxx -n kube-system
# Erros de TLS handshake

# Checar certificado específico
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 Validity
```

**Causa:**
Certificados expirados (padrão: 1 ano).

**Solução:**
```bash
# Renovar todos os certificados
sudo kubeadm certs renew all

# Verificar nova data de expiração
sudo kubeadm certs check-expiration

# Reiniciar componentes do control plane
sudo systemctl restart kubelet

# Se componentes estáticos, mover manifestos temporariamente
sudo mv /etc/kubernetes/manifests /etc/kubernetes/manifests.bak
# Aguardar pods pararem
sudo mv /etc/kubernetes/manifests.bak /etc/kubernetes/manifests
# Pods serão recriados com novos certificados

# Atualizar kubeconfig do admin
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# Testar acesso
kubectl get nodes
```

**Pontos-chave:**
- Certificados expiram (monitorar!)
- kubeadm facilita renovação
- Componentes precisam ser reiniciados
- Automatizar renovação (cronjob)
- Certificados de CA duram 10 anos

---

### Solução 4.3: Problemas de storage class

**Problema:**
StorageClass sem provisioner ou provisioner com erro.

**Diagnóstico:**
```bash
kubectl get storageclass
# Output: Nenhuma com (default)

kubectl get pvc -A
# Múltiplos PVCs Pending

kubectl describe pvc my-pvc -n app
# Events: waiting for a volume to be created

kubectl get pods -n kube-system | grep provisioner
# Provisioner crashando ou ausente
```

**Causa:**
StorageClass não configurada como default ou provisioner com problemas.

**Solução:**
```bash
# Opção 1: Marcar StorageClass como default
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Opção 2: Criar nova StorageClass (exemplo local-path)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Verificar/instalar provisioner (exemplo: local-path-provisioner)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Verificar provisioner funcionando
kubectl get pods -n local-path-storage

# Para PVCs existentes, deletar e recriar
kubectl delete pvc my-pvc -n app
kubectl apply -f my-pvc.yaml

# Verificar PVC bound
kubectl get pvc -n app -w
```

**Pontos-chave:**
- Sempre ter uma StorageClass default
- Provisioner deve estar rodando
- volumeBindingMode: Immediate vs WaitForFirstConsumer
- PVCs existentes não atualizam automaticamente
- Cada provider tem seu provisioner (AWS EBS, GCE PD, etc.)

---

### Solução 4.4: Performance e latência

**Problema:**
Latência de rede, pods em nodes distantes, ou banco de dados lento.

**Diagnóstico:**
```bash
# Verificar latência da aplicação
kubectl exec app-pod -n desafio-4-4 -- curl -w "@curl-format.txt" -o /dev/null -s http://backend

# Verificar localização dos pods
kubectl get pods -n desafio-4-4 -o wide
# app-pod: node-1 (us-east-1a)
# db-pod: node-3 (us-east-1c) <- Zonas diferentes!

# Testar latência de rede entre nodes
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- ping <pod-ip>

# Verificar métricas do banco
kubectl exec db-pod -n desafio-4-4 -- psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

**Causa:**
Pods em zonas de disponibilidade diferentes, causando latência de rede.

**Solução:**
```bash
# Opção 1: Usar Pod Affinity para colocar pods próximos
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: desafio-4-4
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: database
              topologyKey: topology.kubernetes.io/zone
      containers:
      - name: app
        image: myapp:v1
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
EOF

# Opção 2: Usar TopologySpreadConstraints
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: desafio-4-4
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: myapp
      containers:
      - name: app
        image: myapp:v1
EOF

# Opção 3: Otimizar queries do banco
# Adicionar índices, connection pooling, caching

# Verificar melhoria
kubectl exec app-pod -n desafio-4-4 -- curl -w "time_total: %{time_total}s\n" -o /dev/null -s http://backend
```

**Pontos-chave:**
- Latência de rede entre zonas (1-5ms)
- Usar affinity para colocar pods relacionados próximos
- TopologySpreadConstraints para distribuição inteligente
- Considerar caching (Redis) para dados frequentes
- Connection pooling reduz overhead
- Monitorar com ferramentas APM (Prometheus, Jaeger)

---

### Solução 4.5: Cluster multi-namespace com quota

**Problema:**
ResourceQuota atingida, impedindo criação de novos pods.

**Diagnóstico:**
```bash
kubectl get resourcequota -A
kubectl describe resourcequota -n team-a
# Used: cpu 4000m/4000m, memory 8Gi/8Gi (LIMITES ATINGIDOS!)

kubectl describe limitrange -n team-a
# Limits per pod muito altos

# Tentar criar pod
kubectl run test --image=nginx -n team-a
# Error: exceeded quota
```

**Causa:**
Quota muito restritiva ou recursos mal distribuídos.

**Solução:**
```bash
# Analisar uso real
kubectl top pods -n team-a
# Pods usando apenas 50% do requested

# Opção 1: Aumentar quota (se cluster tiver capacidade)
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "8"      # Aumentado de 4
    requests.memory: 16Gi  # Aumentado de 8Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
    services: "20"
EOF

# Opção 2: Ajustar LimitRange para valores mais realistas
kubectl apply -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: team-a
spec:
  limits:
  - max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: 50m
      memory: 64Mi
    default:
      cpu: 500m    # Reduzido
      memory: 512Mi  # Reduzido
    defaultRequest:
      cpu: 100m    # Reduzido
      memory: 128Mi  # Reduzido
    type: Container
EOF

# Opção 3: Deletar pods não essenciais
kubectl get pods -n team-a --sort-by=.status.startTime
kubectl delete pod old-pod-xxx -n team-a

# Opção 4: Ajustar resources dos deployments existentes
kubectl set resources deployment app -n team-a \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi

# Verificar espaço liberado
kubectl describe resourcequota -n team-a
```

**Pontos-chave:**
- ResourceQuota limita recursos por namespace
- LimitRange define defaults e limites por pod
- Pods sem requests herdam do LimitRange
- Monitorar uso real vs requested
- Educar times sobre right-sizing
- Usar VPA (Vertical Pod Autoscaler) para recomendações

---

### Solução 4.6: Falha em rolling update

**Problema:**
Nova versão do pod falhando readiness probe, travando rollout.

**Diagnóstico:**
```bash
kubectl rollout status deployment/app -n desafio-4-6
# Output: Waiting for rollout to finish: 2 out of 5 new replicas have been updated...

kubectl get replicaset -n desafio-4-6
# app-5d4f6c8b7d (new): 2/5 ready
# app-7b8c9d6e5f (old): 3/5 ready

kubectl describe pod app-5d4f6c8b7d-xxx -n desafio-4-6
# Readiness probe failed: HTTP probe failed with statuscode: 500

kubectl logs app-5d4f6c8b7d-xxx -n desafio-4-6
# Error: Database migration failed
```

**Causa:**
Nova versão tem bug (migration do banco falhando), impedindo que fique ready.

**Solução:**
```bash
# Opção 1: Rollback para versão anterior
kubectl rollout undo deployment/app -n desafio-4-6

# Verificar rollback
kubectl rollout status deployment/app -n desafio-4-6
# Rollout succeeded

# Opção 2: Rollback para versão específica
kubectl rollout history deployment/app -n desafio-4-6
kubectl rollout undo deployment/app --to-revision=3 -n desafio-4-6

# Opção 3: Pausar rollout, corrigir, e retomar
kubectl rollout pause deployment/app -n desafio-4-6

# Corrigir o problema (ex: fix migration)
kubectl set image deployment/app app=myapp:v2.1-fixed -n desafio-4-6

kubectl rollout resume deployment/app -n desafio-4-6

# Opção 4: Ajustar estratégia de rollout para ser mais conservador
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
      maxSurge: 1        # Apenas 1 pod extra
      maxUnavailable: 0  # Zero downtime
  minReadySeconds: 30    # Aguardar 30s antes de considerar pronto
  progressDeadlineSeconds: 600  # Timeout de 10min
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
        image: myapp:v2
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3  # Falhar 3x antes de marcar como not ready
EOF

# Monitorar rollout detalhadamente
kubectl rollout status deployment/app -n desafio-4-6 -w
```

**Pontos-chave:**
- RollingUpdate atualiza gradualmente
- maxUnavailable: quantos pods podem estar indisponíveis
- maxSurge: quantos pods extras podem ser criados
- Readiness probe crucial para evitar servir tráfego para pods ruins
- progressDeadlineSeconds: timeout para rollout
- Sempre testar rollback em staging
- Usar canary deployments para releases críticas

---

## 🏆 Checklist de Troubleshooting

### 📋 Metodologia Geral

1. **Identificar o problema**
   - [ ] Qual é o sintoma? (pod not ready, erro 500, timeout, etc.)
   - [ ] Quando começou?
   - [ ] O que mudou recentemente?

2. **Coletar informações**
   - [ ] `kubectl get pods -n <namespace>`
   - [ ] `kubectl describe pod <pod> -n <namespace>`
   - [ ] `kubectl logs <pod> -n <namespace>`
   - [ ] `kubectl get events -n <namespace> --sort-by=.lastTimestamp`

3. **Diagnosticar**
   - [ ] Analisar eventos e logs
   - [ ] Verificar recursos (CPU, memória, disco)
   - [ ] Testar conectividade
   - [ ] Verificar configurações (env vars, volumes, etc.)

4. **Resolver**
   - [ ] Aplicar correção
   - [ ] Verificar que o problema foi resolvido
   - [ ] Documentar solução

5. **Prevenir recorrência**
   - [ ] Adicionar monitoramento
   - [ ] Criar alerta
   - [ ] Documentar procedimento
   - [ ] Automação (se aplicável)

---

## 📚 Comandos Essenciais

```bash
# Informações gerais
kubectl get all -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl describe <resource> <name> -n <namespace>

# Logs
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous  # Logs do container anterior (se crashou)
kubectl logs <pod> -c <container> -n <namespace>  # Container específico
kubectl logs -f <pod> -n <namespace>  # Follow (tail -f)

# Debugging interativo
kubectl exec -it <pod> -n <namespace> -- /bin/bash
kubectl exec <pod> -n <namespace> -- <command>

# Recursos e métricas
kubectl top nodes
kubectl top pods -n <namespace>
kubectl describe node <node-name>

# Networking
kubectl get svc,endpoints -n <namespace>
kubectl run test-pod --rm -it --image=busybox -- wget -O- http://service:port

# Configuração
kubectl get configmap,secret -n <namespace>
kubectl describe configmap <name> -n <namespace>

# RBAC
kubectl auth can-i <verb> <resource> --as=<user/sa>
kubectl get role,rolebinding -n <namespace>

# Troubleshooting avançado
kubectl get pods -A -o wide  # Ver node de cada pod
kubectl get pods --field-selector=status.phase=Failed
kubectl api-resources  # Listar todos os recursos
kubectl explain <resource>  # Documentação inline
```

---

## 🎓 Conclusão

Parabéns por completar os desafios! As habilidades de troubleshooting são desenvolvidas com prática. Continue experimentando, quebrando coisas (em ambientes de teste!), e aprendendo com cada problema.

**Próximos passos:**
1. Criar seus próprios cenários de falha
2. Praticar em clusters reais
3. Contribuir com melhorias para este guia
4. Ensinar outros sobre o que aprendeu

**Recursos adicionais:**
- Kubernetes Slack: kubernetes.slack.com
- StackOverflow tag: kubernetes
- GitHub Issues dos projetos relacionados

Boa sorte! 🚀
