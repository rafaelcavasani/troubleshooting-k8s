# 📚 Desafios de Troubleshooting Kubernetes

Bem-vindo aos desafios de troubleshooting Kubernetes! Este repositório contém cenários práticos de problemas reais que você pode encontrar ao trabalhar com Kubernetes.

## 📋 Estrutura do Projeto

```
desafio-troubleshooting/
├── README.md              # Este arquivo
├── DESAFIOS.md           # Lista completa de desafios com descrições
├── SOLUCOES.md           # Soluções detalhadas de cada desafio
├── SETUP.md              # Guia para criar os cenários de falha
├── desafio-runner.ps1    # 🚀 Script interativo (PowerShell/Windows)
└── desafio-runner.sh     # 🚀 Script interativo (Bash/Linux/Mac)
```

## 🎯 Como Usar

### 1. Configurar o Ambiente
```bash
# Certifique-se de ter um cluster Kubernetes funcionando
kubectl cluster-info

# Leia o arquivo SETUP.md para instruções de configuração
cat SETUP.md
```

### 2. Criar um Cenário de Falha
```bash
# Escolha um desafio do SETUP.md e execute os comandos
# Exemplo: Criar cenário do Desafio 1.1
kubectl create namespace desafio-1-1
kubectl apply -f <manifesto-com-erro>
```

### 3. Resolver o Desafio
```bash
# Use apenas kubectl e sua experiência
# Tente não consultar SOLUCOES.md imediatamente!
kubectl get pods -n desafio-1-1
kubectl describe pod <pod-name> -n desafio-1-1
kubectl logs <pod-name> -n desafio-1-1
```

### 4. Verificar a Solução
```bash
# Depois de resolver, compare com SOLUCOES.md
# Veja se sua abordagem foi similar ou diferente
```

### 5. Limpar
```bash
# Remover namespace do desafio
kubectl delete namespace desafio-1-1
```

## 📊 Níveis de Dificuldade

### 🟢 Nível 1 - Iniciante (4 desafios)
- Problemas básicos de pods e containers
- Configuração simples de services
- ConfigMaps básicos
- **Tempo estimado:** 1-2 horas

### 🟡 Nível 2 - Intermediário (5 desafios)
- Problemas de recursos (CPU/Memory)
- Health checks e probes
- Persistência de dados
- Network policies
- Secrets
- **Tempo estimado:** 2-4 horas

### 🟠 Nível 3 - Avançado (5 desafios)
- DNS e service discovery
- Ingress e roteamento
- StatefulSets
- Autoscaling (HPA)
- RBAC e segurança
- **Tempo estimado:** 4-8 horas

### 🔴 Nível 4 - Expert (6 desafios)
- Problemas em nodes
- Certificados e segurança
- Storage classes
- Performance e otimização
- Resource quotas
- Rolling updates complexos
- **Tempo estimado:** 8-12 horas

## 🎓 Sistema de Pontuação

Cada desafio vale **10 pontos**:
- Identificação do problema: 3 pontos
- Diagnóstico completo: 3 pontos
- Solução correta: 3 pontos
- Documentação: 1 ponto

**Total possível:** 200 pontos

### Certificação
- 🥉 **Bronze** (100-139 pontos): Conhecimento básico
- 🥈 **Prata** (140-179 pontos): Conhecimento intermediário
- 🥇 **Ouro** (180-200 pontos): Conhecimento avançado

## 🛠️ Pré-requisitos

### Obrigatórios
- Cluster Kubernetes (Minikube, Kind, k3s, ou cloud)
- kubectl instalado e configurado
- Conhecimento básico de Kubernetes

### Recomendados
- k9s (interface visual para Kubernetes)
- metrics-server (para desafios de HPA)
- Ingress controller (para desafios de Ingress)
- Experiência com terminal/shell

## 🚀 Quick Start

### Opção 1: Usando o Script Interativo (Recomendado)

```bash
# Windows (PowerShell)
.\desafio-runner.ps1

# Linux/Mac (Bash)
chmod +x desafio-runner.sh
./desafio-runner.sh
```

O script irá:
- ✅ Verificar pré-requisitos automaticamente
- ✅ Criar o ambiente do desafio
- ✅ Apresentar o problema
- ✅ Aguardar você resolver
- ✅ Validar a solução
- ✅ Mostrar pontuação final

### Opção 2: Manualmente

```bash
# 1. Clonar ou baixar este repositório
cd desafio-troubleshooting

# 2. Verificar cluster
kubectl get nodes

# 3. Começar pelo Nível 1, Desafio 1.1
# Ler DESAFIOS.md para entender o cenário
cat DESAFIOS.md | grep -A 10 "Desafio 1.1"

# 4. Criar o cenário usando SETUP.md
cat SETUP.md | grep -A 30 "Desafio 1.1"

# 5. Resolver!
kubectl get pods -n desafio-1-1
# ... troubleshooting ...

# 6. Verificar solução
cat SOLUCOES.md | grep -A 50 "Solução 1.1"

# 7. Limpar
kubectl delete namespace desafio-1-1
```

## 📖 Recursos de Aprendizado

### Documentação Oficial
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug/)

### Ferramentas Úteis
- **k9s**: Interface TUI para Kubernetes
- **kubectx/kubens**: Trocar contextos e namespaces rapidamente
- **stern**: Logs multi-pod
- **kubectl-debug**: Debug nodes e pods
- **Lens**: IDE desktop para Kubernetes

### Comandos Essenciais
```bash
# Informações gerais
kubectl get all -n <namespace>
kubectl describe <resource> <name>
kubectl logs <pod> [-c <container>]
kubectl exec -it <pod> -- /bin/sh

# Debugging
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl top nodes
kubectl top pods -n <namespace>

# Network
kubectl run test --rm -it --image=busybox -- sh
kubectl port-forward <pod> 8080:80

# RBAC
kubectl auth can-i <verb> <resource>
kubectl get role,rolebinding -n <namespace>
```

## 🤝 Contribuindo

Quer adicionar mais desafios ou melhorar os existentes?

1. Crie novos cenários de falha realistas
2. Documente claramente o problema e a solução
3. Teste em cluster real antes de submeter
4. Inclua comandos de setup no SETUP.md

## ⚠️ Avisos Importantes

- **Nunca execute em produção!**
- Alguns desafios afetam todo o cluster
- Use cluster dedicado para testes
- Faça backup de configurações importantes
- Leia SETUP.md completamente antes de começar

## 🎯 Progressão Recomendada

### Iniciantes
1. Complete todos os desafios do Nível 1
2. Pratique até resolver cada um em menos de 15 minutos
3. Documente seu processo de troubleshooting
4. Avance para Nível 2

### Intermediários
1. Revise Nível 1 rapidamente
2. Foque no Nível 2 e 3
3. Tente resolver sem consultar SOLUCOES.md
4. Crie variações dos desafios

### Avançados
1. Vá direto para Nível 3 e 4
2. Crie seus próprios desafios
3. Simule cenários de produção complexos
4. Contribua com novos desafios

## 📝 Registro de Progresso

Crie um arquivo `meu-progresso.md` para documentar:
```markdown
# Meu Progresso

## Desafio 1.1 - ImagePullBackOff
**Data:** 04/01/2026
**Tempo:** 10 minutos
**Pontuação:** 10/10
**Aprendizados:**
- Sempre verificar nome da imagem com `describe pod`
- Eventos mostram erro claramente
**Comandos usados:**
- kubectl get pods -n desafio-1-1
- kubectl describe pod <name> -n desafio-1-1
- kubectl edit deployment webapp-nginx -n desafio-1-1
```

## 🏆 Desafios Bônus

Após completar todos os níveis:
- Resolva todos os desafios em sequência em menos de 4 horas
- Crie 5 novos cenários de falha
- Ensine alguém usando estes desafios
- Contribua com melhorias para o repositório

## 💬 Comunidade

- Compartilhe suas soluções alternativas
- Discuta abordagens diferentes
- Ajude outros que estão aprendendo
- Relate problemas ou bugs nos desafios

## 📄 Licença

Este material é livre para uso educacional. Sinta-se à vontade para adaptar, compartilhar e melhorar!

---

## 🎓 Próximos Passos

1. ✅ Leia este README
2. 📖 Leia DESAFIOS.md para visão geral
3. 🛠️ Configure ambiente seguindo SETUP.md
4. 🚀 Comece pelo Nível 1, Desafio 1.1
5. 🎯 Resolva, aprenda, repita!

**Boa sorte no troubleshooting! 🔍**

---

*Última atualização: Janeiro 2026*
