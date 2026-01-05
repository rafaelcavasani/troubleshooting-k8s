# 🔍 Desafios de Troubleshooting Kubernetes

## 📋 Índice por Nível

- [Nível 1 - Iniciante](#nível-1---iniciante)
- [Nível 2 - Intermediário](#nível-2---intermediário)
- [Nível 3 - Avançado](#nível-3---avançado)
- [Nível 4 - Expert](#nível-4---expert)

---

## 🟢 Nível 1 - Iniciante

### Desafio 1.1: Pod que não inicia

**Cenário:**
Foi feito o deploy de uma aplicação web chamada `webapp-nginx`, mas o pod está com status `ImagePullBackOff`.

**Objetivo:**
Identificar e corrigir o problema para que o pod entre em estado `Running`.

**Comandos iniciais:**
```bash
kubectl get pods -n desafio-1-1
kubectl describe pod <pod-name> -n desafio-1-1
```

**Perguntas:**
1. Qual é o erro específico?
2. Por que o Kubernetes não consegue baixar a imagem?
3. Como corrigir o deployment?

---

### Desafio 1.2: Pod crashando constantemente

**Cenário:**
O pod `api-backend` está em loop de restart com status `CrashLoopBackOff`. A aplicação é um servidor Node.js simples.

**Objetivo:**
Descobrir por que a aplicação está crashando e corrigir o problema.

**Comandos iniciais:**
```bash
kubectl get pods -n desafio-1-2
kubectl logs <pod-name> -n desafio-1-2
kubectl describe pod <pod-name> -n desafio-1-2
```

**Perguntas:**
1. O que os logs mostram?
2. Qual é a causa do crash?
3. Qual configuração está errada?

---

### Desafio 1.3: Service não expondo o pod

**Cenário:**
Você tem um deployment `frontend` rodando perfeitamente, mas ao tentar acessar via service, recebe erro de conexão.

**Objetivo:**
Identificar por que o service não está encaminhando tráfego para os pods.

**Comandos iniciais:**
```bash
kubectl get pods,svc -n desafio-1-3
kubectl describe svc frontend-service -n desafio-1-3
kubectl get endpoints -n desafio-1-3
```

**Perguntas:**
1. O service tem endpoints?
2. Os labels do pod correspondem ao selector do service?
3. As portas estão configuradas corretamente?

---

### Desafio 1.4: ConfigMap não aplicado

**Cenário:**
Uma aplicação deveria estar lendo variáveis de ambiente de um ConfigMap, mas os valores não estão sendo aplicados.

**Objetivo:**
Corrigir a configuração para que a aplicação receba as variáveis corretas.

**Comandos iniciais:**
```bash
kubectl get configmap -n desafio-1-4
kubectl describe pod <pod-name> -n desafio-1-4
kubectl exec <pod-name> -n desafio-1-4 -- env
```

**Perguntas:**
1. O ConfigMap existe?
2. O pod está referenciando o ConfigMap corretamente?
3. Os valores estão sendo injetados?

---

## 🟡 Nível 2 - Intermediário

### Desafio 2.1: Problemas de recurso (CPU/Memory)

**Cenário:**
O pod `data-processor` está sendo constantemente terminado (OOMKilled) e reiniciado.

**Objetivo:**
Identificar o problema de recursos e ajustar os limites adequadamente.

**Comandos iniciais:**
```bash
kubectl get pods -n desafio-2-1
kubectl describe pod <pod-name> -n desafio-2-1
kubectl top pod <pod-name> -n desafio-2-1
```

**Perguntas:**
1. Qual é o limite de memória configurado?
2. Quanto de memória o pod está tentando usar?
3. Como ajustar os recursos sem desperdício?

---

### Desafio 2.2: Liveness e Readiness Probes

**Cenário:**
Uma aplicação `healthcheck-app` está sendo marcada como não-pronta constantemente, causando interrupções no serviço.

**Objetivo:**
Corrigir as health checks para refletir o estado real da aplicação.

**Comandos iniciais:**
```bash
kubectl get pods -n desafio-2-2
kubectl describe pod <pod-name> -n desafio-2-2
kubectl logs <pod-name> -n desafio-2-2
```

**Perguntas:**
1. Qual probe está falhando?
2. O endpoint de health check está correto?
3. Os timeouts e períodos estão adequados?

---

### Desafio 2.3: Problemas de persistência

**Cenário:**
Um banco de dados `postgres-db` está perdendo dados toda vez que o pod reinicia.

**Objetivo:**
Configurar persistência adequada usando PersistentVolume e PersistentVolumeClaim.

**Comandos iniciais:**
```bash
kubectl get pods,pvc,pv -n desafio-2-3
kubectl describe pod <pod-name> -n desafio-2-3
```

**Perguntas:**
1. Existe um PVC criado?
2. O PVC está bound a um PV?
3. O volume está montado corretamente no pod?

---

### Desafio 2.4: Network Policy bloqueando comunicação

**Cenário:**
O `frontend` não consegue se comunicar com o `backend`, retornando timeout.

**Objetivo:**
Identificar e corrigir as Network Policies que estão bloqueando a comunicação.

**Comandos iniciais:**
```bash
kubectl get pods,svc -n desafio-2-4
kubectl get networkpolicy -n desafio-2-4
kubectl describe networkpolicy <policy-name> -n desafio-2-4
```

**Perguntas:**
1. Existem Network Policies aplicadas?
2. Qual tráfego está sendo bloqueado?
3. Como permitir a comunicação necessária?

---

### Desafio 2.5: Secret não montado corretamente

**Cenário:**
Uma aplicação precisa de credenciais para acessar um banco de dados, mas está falhando na autenticação.

**Objetivo:**
Corrigir a montagem do Secret no pod.

**Comandos iniciais:**
```bash
kubectl get secret -n desafio-2-5
kubectl describe pod <pod-name> -n desafio-2-5
kubectl exec <pod-name> -n desafio-2-5 -- ls /etc/secrets
```

**Perguntas:**
1. O Secret existe e está codificado corretamente?
2. O volume está montado no caminho certo?
3. As permissões do arquivo estão corretas?

---

## 🟠 Nível 3 - Avançado

### Desafio 3.1: Problemas de DNS interno

**Cenário:**
Pods não conseguem resolver nomes de serviços internos (`api-service.default.svc.cluster.local` retorna NXDOMAIN).

**Objetivo:**
Diagnosticar e corrigir problemas no CoreDNS ou configuração de DNS dos pods.

**Comandos iniciais:**
```bash
kubectl get pods -n kube-system | grep coredns
kubectl logs <coredns-pod> -n kube-system
kubectl exec <app-pod> -n desafio-3-1 -- nslookup kubernetes.default
```

**Perguntas:**
1. O CoreDNS está funcionando?
2. A configuração de DNS nos pods está correta?
3. Existem problemas de conectividade com o DNS?

---

### Desafio 3.2: Ingress não roteando corretamente

**Cenário:**
Um Ingress foi configurado para rotear `app.example.com` para diferentes services baseado no path, mas sempre retorna 404.

**Objetivo:**
Corrigir a configuração do Ingress e garantir o roteamento correto.

**Comandos iniciais:**
```bash
kubectl get ingress -n desafio-3-2
kubectl describe ingress <ingress-name> -n desafio-3-2
kubectl get svc -n desafio-3-2
kubectl logs <ingress-controller-pod> -n ingress-nginx
```

**Perguntas:**
1. O Ingress Controller está funcionando?
2. As regras de roteamento estão corretas?
3. Os backends estão saudáveis?

---

### Desafio 3.3: StatefulSet com problemas de ordenação

**Cenário:**
Um cluster Kafka (3 réplicas) não está iniciando corretamente - alguns pods ficam em `Pending` ou `Init`.

**Objetivo:**
Resolver problemas de inicialização ordenada e dependências entre pods do StatefulSet.

**Comandos iniciais:**
```bash
kubectl get statefulset,pods -n desafio-3-3
kubectl describe pod kafka-0 -n desafio-3-3
kubectl get pvc -n desafio-3-3
```

**Perguntas:**
1. Todos os PVCs estão bound?
2. A ordem de inicialização está correta?
3. Existem problemas de recursos ou scheduling?

---

### Desafio 3.4: HPA não escalando

**Cenário:**
Um HorizontalPodAutoscaler foi configurado, mas não está escalando os pods mesmo com alta carga de CPU.

**Objetivo:**
Identificar por que o HPA não está funcionando e corrigir.

**Comandos iniciais:**
```bash
kubectl get hpa -n desafio-3-4
kubectl describe hpa <hpa-name> -n desafio-3-4
kubectl top pods -n desafio-3-4
kubectl get deployment <deployment-name> -n desafio-3-4 -o yaml
```

**Perguntas:**
1. O metrics-server está funcionando?
2. Os pods têm resource requests configurados?
3. Os thresholds do HPA estão corretos?

---

### Desafio 3.5: RBAC bloqueando acesso

**Cenário:**
Uma ServiceAccount não consegue listar pods, retornando erro de permissão.

**Objetivo:**
Configurar RBAC adequadamente para permitir as operações necessárias.

**Comandos iniciais:**
```bash
kubectl get serviceaccount -n desafio-3-5
kubectl get role,rolebinding -n desafio-3-5
kubectl auth can-i list pods --as=system:serviceaccount:desafio-3-5:app-sa
```

**Perguntas:**
1. A ServiceAccount existe?
2. Existe um Role/RoleBinding associado?
3. As permissões estão corretas?

---

## 🔴 Nível 4 - Expert

### Desafio 4.1: Cluster Node NotReady

**Cenário:**
Um dos nodes do cluster está com status `NotReady` e os pods estão sendo evacuados.

**Objetivo:**
Diagnosticar e recuperar o node, ou remover ele do cluster de forma segura.

**Comandos iniciais:**
```bash
kubectl get nodes
kubectl describe node <node-name>
kubectl get pods -A -o wide | grep <node-name>
```

**Perguntas:**
1. Qual é a condição que está falhando?
2. O kubelet está rodando no node?
3. Existem problemas de recursos (disco, memória)?

---

### Desafio 4.2: Problemas de certificados

**Cenário:**
A comunicação entre componentes do cluster está falhando com erros de TLS/certificado.

**Objetivo:**
Identificar certificados expirados ou mal configurados e renovar/corrigir.

**Comandos iniciais:**
```bash
kubectl get pods -n kube-system
kubectl logs <api-server-pod> -n kube-system
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

**Perguntas:**
1. Quais certificados estão expirados?
2. Como renovar os certificados?
3. Quais componentes precisam ser reiniciados?

---

### Desafio 4.3: Problemas de storage class

**Cenário:**
PVCs estão ficando em estado `Pending` indefinidamente, impedindo o início de novos pods.

**Objetivo:**
Diagnosticar problemas com StorageClass, provisioner ou backend de storage.

**Comandos iniciais:**
```bash
kubectl get storageclass
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
kubectl logs <provisioner-pod> -n kube-system
```

**Perguntas:**
1. A StorageClass existe e está configurada como default?
2. O provisioner está funcionando?
3. Há recursos disponíveis no backend de storage?

---

### Desafio 4.4: Performance e latência

**Cenário:**
Uma aplicação está com alta latência (>2s) nas requisições, mas o pod mostra CPU e memória normais.

**Objetivo:**
Identificar gargalos de rede, disco I/O, ou problemas de arquitetura.

**Comandos iniciais:**
```bash
kubectl top pods -n desafio-4-4
kubectl exec <pod-name> -n desafio-4-4 -- curl -w "@curl-format.txt" -o /dev/null -s http://backend
kubectl get pods -n desafio-4-4 -o wide
```

**Perguntas:**
1. A latência é de rede ou processamento?
2. Existem pods em nodes distantes?
3. O banco de dados está respondendo rápido?

---

### Desafio 4.5: Cluster multi-namespace com quota

**Cenário:**
Múltiplos times reclamam que não conseguem criar novos pods, mas o cluster tem recursos disponíveis.

**Objetivo:**
Investigar e ajustar ResourceQuotas e LimitRanges por namespace.

**Comandos iniciais:**
```bash
kubectl get resourcequota -A
kubectl describe resourcequota -n <namespace>
kubectl get limitrange -A
kubectl describe limitrange -n <namespace>
```

**Perguntas:**
1. Quais namespaces têm quotas configuradas?
2. As quotas estão sendo excedidas?
3. Os limites estão adequados para as necessidades?

---

### Desafio 4.6: Falha em rolling update

**Cenário:**
Um deployment está travado durante um rolling update - alguns pods na versão antiga, outros na nova, causando inconsistências.

**Objetivo:**
Finalizar ou reverter o update de forma segura.

**Comandos iniciais:**
```bash
kubectl get deployment,replicaset -n desafio-4-6
kubectl rollout status deployment/<deployment-name> -n desafio-4-6
kubectl describe deployment <deployment-name> -n desafio-4-6
```

**Perguntas:**
1. Por que o rollout travou?
2. Existe um problema com a nova versão?
3. Como fazer rollback de forma segura?

---

## 📊 Sistema de Pontuação

### Critérios de Avaliação

Para cada desafio, você pode ganhar até **10 pontos**:

- **Identificação correta do problema**: 3 pontos
- **Diagnóstico completo (comandos usados)**: 3 pontos
- **Solução aplicada corretamente**: 3 pontos
- **Documentação/explicação**: 1 ponto

### Níveis

- **Nível 1 (Iniciante)**: 4 desafios × 10 = 40 pontos
- **Nível 2 (Intermediário)**: 5 desafios × 10 = 50 pontos
- **Nível 3 (Avançado)**: 5 desafios × 10 = 50 pontos
- **Nível 4 (Expert)**: 6 desafios × 10 = 60 pontos

**Total possível**: 200 pontos

### Certificação

- 🥉 **Bronze**: 100-139 pontos (50-69%)
- 🥈 **Prata**: 140-179 pontos (70-89%)
- 🥇 **Ouro**: 180-200 pontos (90-100%)

---

## 🎯 Como usar este guia

1. **Configure o ambiente** usando o arquivo `SETUP.md`
2. **Escolha um desafio** do nível adequado ao seu conhecimento
3. **Tente resolver** usando apenas comandos kubectl
4. **Consulte a solução** em `SOLUCOES.md` apenas depois de tentar
5. **Documente** os comandos que usou e o raciocínio
6. **Avance** para desafios mais difíceis

---

## 📚 Recursos Recomendados

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)

---

**Boa sorte! 🚀**
