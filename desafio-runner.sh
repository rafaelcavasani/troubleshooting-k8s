#!/bin/bash

#
# Script interativo para executar desafios de troubleshooting Kubernetes
# Versão Bash para Linux/Mac
#

# Cores
COLOR_SUCCESS="\033[0;32m"
COLOR_ERROR="\033[0;31m"
COLOR_WARNING="\033[0;33m"
COLOR_INFO="\033[0;36m"
COLOR_PROMPT="\033[0;35m"
COLOR_RESET="\033[0m"

# Variáveis globais
LEVEL=""
CHALLENGE=""
RESULTS=()

# Função: Verificar pré-requisitos
check_prerequisites() {
    echo -e "\n${COLOR_INFO}🔍 Verificando pré-requisitos...${COLOR_RESET}"
    
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${COLOR_ERROR}❌ kubectl não encontrado! Instale kubectl primeiro.${COLOR_RESET}"
        exit 1
    fi
    
    # Verificar cluster
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${COLOR_ERROR}❌ Não foi possível conectar ao cluster Kubernetes!${COLOR_RESET}"
        echo -e "${COLOR_WARNING}   Execute 'kubectl cluster-info' para diagnóstico.${COLOR_RESET}"
        exit 1
    fi
    
    echo -e "${COLOR_SUCCESS}✅ Cluster Kubernetes detectado${COLOR_RESET}\n"
}

# Função: Banner
show_banner() {
    clear
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_INFO}    🔍 DESAFIOS DE TROUBLESHOOTING KUBERNETES 🔍      ${COLOR_RESET}"
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}"
    echo ""
}

# Função: Aguardar tecla
wait_any_key() {
    local message="${1:-Pressione ENTER para continuar...}"
    echo -e "\n${COLOR_PROMPT}$message${COLOR_RESET}"
    read -r
}

# Função: Pergunta sim/não
get_yes_no() {
    local question="$1"
    while true; do
        read -p "$(echo -e ${COLOR_PROMPT}$question '(s/n): '${COLOR_RESET})" response
        case "$response" in
            [sS]*) return 0 ;;
            [nN]*) return 1 ;;
            *) echo -e "${COLOR_WARNING}Por favor, responda 's' ou 'n'${COLOR_RESET}" ;;
        esac
    done
}

# Função: Limpar namespace
remove_challenge_namespace() {
    local namespace="$1"
    echo -e "\n${COLOR_INFO}🧹 Limpando ambiente...${COLOR_RESET}"
    kubectl delete namespace "$namespace" --ignore-not-found=true --wait=false &> /dev/null
    sleep 2
    echo -e "${COLOR_SUCCESS}✅ Ambiente limpo${COLOR_RESET}"
}

# Função: Menu de seleção de nível
get_level_selection() {
    echo -e "\n${COLOR_INFO}📊 Selecione o nível de dificuldade:${COLOR_RESET}\n"
    echo -e "  1. ${COLOR_SUCCESS}🟢 Nível 1 - Iniciante      (4 desafios)${COLOR_RESET}"
    echo -e "  2. ${COLOR_WARNING}🟡 Nível 2 - Intermediário  (5 desafios)${COLOR_RESET}"
    echo -e "  3. 🟠 Nível 3 - Avançado       (5 desafios)"
    echo -e "  4. ${COLOR_ERROR}🔴 Nível 4 - Expert         (6 desafios)${COLOR_RESET}"
    echo -e "  0. ❌ Sair\n"
    
    while true; do
        read -p "$(echo -e ${COLOR_PROMPT}'Digite o número do nível: '${COLOR_RESET})" level
        if [[ "$level" =~ ^[0-4]$ ]]; then
            echo "$level"
            return
        fi
        echo -e "${COLOR_WARNING}Opção inválida! Digite 0-4${COLOR_RESET}"
    done
}

# Função: Menu de seleção de desafio
get_challenge_selection() {
    local level="$1"
    local max_challenges="$2"
    
    echo -e "\n${COLOR_INFO}🎯 Selecione o desafio:${COLOR_RESET}\n"
    for ((i=1; i<=max_challenges; i++)); do
        echo "  $i. Desafio $level.$i"
    done
    echo -e "  0. ${COLOR_INFO}Todos os desafios do nível${COLOR_RESET}\n"
    
    while true; do
        read -p "$(echo -e ${COLOR_PROMPT}'Digite o número do desafio (0 para todos): '${COLOR_RESET})" challenge
        if [[ "$challenge" =~ ^[0-$max_challenges]$ ]]; then
            echo "$challenge"
            return
        fi
        echo -e "${COLOR_WARNING}Opção inválida! Digite 0-$max_challenges${COLOR_RESET}"
    done
}

# Função: Apresentar desafio
show_challenge() {
    local level="$1"
    local challenge_num="$2"
    local title="$3"
    local scenario="$4"
    local objective="$5"
    local namespace="$6"
    shift 6
    local commands=("$@")
    
    clear
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_INFO} 📋 DESAFIO $level.$challenge_num - $title${COLOR_RESET}"
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}\n"
    echo -e "${COLOR_WARNING}📖 CENÁRIO:${COLOR_RESET}"
    echo -e "   $scenario\n"
    echo -e "${COLOR_SUCCESS}🎯 OBJETIVO:${COLOR_RESET}"
    echo -e "   $objective\n"
    echo -e "${COLOR_INFO}🔧 COMANDOS INICIAIS SUGERIDOS:${COLOR_RESET}"
    for cmd in "${commands[@]}"; do
        echo -e "   $cmd"
    done
    echo -e "\n───────────────────────────────────────────────────────\n"
    echo -e "${COLOR_SUCCESS}⏱️  Ambiente criado! O desafio está pronto.${COLOR_RESET}"
    echo -e "${COLOR_WARNING}💡 Dica: Use outro terminal para resolver o desafio${COLOR_RESET}\n"
}

# Função: Verificar solução
test_solution() {
    local namespace="$1"
    local validation_cmd="$2"
    
    echo -e "\n${COLOR_INFO}🔍 Verificando solução...${COLOR_RESET}"
    sleep 2
    
    if eval "$validation_cmd"; then
        return 0
    else
        return 1
    fi
}

# Função: Mostrar pontuação
show_score() {
    clear
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_INFO}              📊 RESULTADO FINAL 📊                    ${COLOR_RESET}"
    echo -e "${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}\n"
    
    local total=0
    local correct=0
    
    for result in "${RESULTS[@]}"; do
        ((total++))
        IFS=':' read -r challenge status <<< "$result"
        if [ "$status" = "true" ]; then
            ((correct++))
            echo -e "  ${COLOR_SUCCESS}✅ $challenge - Resolvido${COLOR_RESET}"
        else
            echo -e "  ${COLOR_ERROR}❌ $challenge - Não resolvido${COLOR_RESET}"
        fi
    done
    
    echo -e "\n───────────────────────────────────────────────────────\n"
    
    local percentage=$((correct * 100 / total))
    local points=$((correct * 10))
    
    echo -e "  Desafios completados: $correct de $total"
    echo -e "  ${COLOR_INFO}Pontuação: $points pontos${COLOR_RESET}"
    echo -e "  ${COLOR_INFO}Percentual: $percentage%${COLOR_RESET}\n"
    
    # Certificação
    if [ $points -ge 180 ]; then
        echo -e "  ${COLOR_WARNING}🥇 CERTIFICAÇÃO: OURO - Conhecimento Avançado!${COLOR_RESET}"
    elif [ $points -ge 140 ]; then
        echo -e "  🥈 CERTIFICAÇÃO: PRATA - Conhecimento Intermediário"
    elif [ $points -ge 100 ]; then
        echo -e "  🥉 CERTIFICAÇÃO: BRONZE - Conhecimento Básico"
    else
        echo -e "  📚 Continue praticando! Você está no caminho certo."
    fi
    
    echo -e "\n${COLOR_INFO}═══════════════════════════════════════════════════════${COLOR_RESET}\n"
}

# ============================================================================
# DESAFIO 1.1 - ImagePullBackOff
# ============================================================================
start_challenge_1_1() {
    local namespace="desafio-1-1"
    local title="Pod que não inicia"
    
    remove_challenge_namespace "$namespace"
    kubectl create namespace "$namespace" &> /dev/null
    
    kubectl apply -f - <<EOF &> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-nginx
  namespace: $namespace
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
        image: nginxx:latest
        ports:
        - containerPort: 80
EOF
    
    sleep 5
    
    show_challenge 1 1 "$title" \
        "Foi feito o deploy de uma aplicação web chamada 'webapp-nginx', mas o pod está com status ImagePullBackOff." \
        "Identificar e corrigir o problema para que o pod entre em estado Running." \
        "$namespace" \
        "kubectl get pods -n $namespace" \
        "kubectl describe pod <pod-name> -n $namespace"
    
    local resolved=false
    while [ "$resolved" = false ]; do
        wait_any_key "Pressione ENTER quando resolver o desafio..."
        
        if kubectl get pods -n "$namespace" -o json | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
            echo -e "${COLOR_SUCCESS}✅ Parabéns! Desafio resolvido corretamente!${COLOR_RESET}"
            resolved=true
        else
            echo -e "${COLOR_ERROR}❌ O pod ainda não está rodando. Continue tentando!${COLOR_RESET}"
            if get_yes_no "Deseja ver uma dica?"; then
                echo -e "\n${COLOR_WARNING}💡 Dica: Verifique o nome da imagem no describe do pod.${COLOR_RESET}"
            fi
        fi
    done
    
    wait_any_key
    remove_challenge_namespace "$namespace"
    return 0
}

# ============================================================================
# DESAFIO 1.2 - CrashLoopBackOff
# ============================================================================
start_challenge_1_2() {
    local namespace="desafio-1-2"
    local title="Pod crashando constantemente"
    
    remove_challenge_namespace "$namespace"
    kubectl create namespace "$namespace" &> /dev/null
    
    kubectl apply -f - <<EOF &> /dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-code
  namespace: $namespace
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-backend
  namespace: $namespace
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
          value: "8080"
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
    
    sleep 10
    
    show_challenge 1 2 "$title" \
        "O pod 'api-backend' está em loop de restart com status CrashLoopBackOff. A aplicação é um servidor Node.js simples." \
        "Descobrir por que a aplicação está crashando e corrigir o problema." \
        "$namespace" \
        "kubectl get pods -n $namespace" \
        "kubectl logs <pod-name> -n $namespace" \
        "kubectl describe pod <pod-name> -n $namespace"
    
    local resolved=false
    while [ "$resolved" = false ]; do
        wait_any_key "Pressione ENTER quando resolver o desafio..."
        
        sleep 5
        if kubectl get pods -n "$namespace" -o json | jq -e '.items[] | select(.status.phase=="Running" and .status.containerStatuses[0].restartCount==0)' &> /dev/null; then
            echo -e "${COLOR_SUCCESS}✅ Parabéns! Desafio resolvido!${COLOR_RESET}"
            resolved=true
        else
            echo -e "${COLOR_ERROR}❌ O pod ainda está crashando ou reiniciando. Tente novamente!${COLOR_RESET}"
            if get_yes_no "Deseja ver uma dica?"; then
                echo -e "\n${COLOR_WARNING}💡 Dica: Verifique os logs e a variável de ambiente PORT.${COLOR_RESET}"
            fi
        fi
    done
    
    wait_any_key
    remove_challenge_namespace "$namespace"
    return 0
}

# ============================================================================
# DESAFIO 1.3 - Service sem endpoints
# ============================================================================
start_challenge_1_3() {
    local namespace="desafio-1-3"
    local title="Service não expondo o pod"
    
    remove_challenge_namespace "$namespace"
    kubectl create namespace "$namespace" &> /dev/null
    
    kubectl apply -f - <<EOF &> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: $namespace
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
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: $namespace
spec:
  selector:
    app: front
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
    
    sleep 8
    
    show_challenge 1 3 "$title" \
        "Você tem um deployment 'frontend' rodando perfeitamente, mas ao tentar acessar via service, recebe erro de conexão." \
        "Identificar por que o service não está encaminhando tráfego para os pods." \
        "$namespace" \
        "kubectl get pods,svc -n $namespace" \
        "kubectl describe svc frontend-service -n $namespace" \
        "kubectl get endpoints -n $namespace"
    
    local resolved=false
    while [ "$resolved" = false ]; do
        wait_any_key "Pressione ENTER quando resolver o desafio..."
        
        if kubectl get endpoints frontend-service -n "$namespace" -o json | jq -e '.subsets[]?.addresses[]?' &> /dev/null; then
            echo -e "${COLOR_SUCCESS}✅ Excelente! O service agora tem endpoints!${COLOR_RESET}"
            resolved=true
        else
            echo -e "${COLOR_ERROR}❌ O service ainda não tem endpoints. Continue!${COLOR_RESET}"
            if get_yes_no "Deseja ver uma dica?"; then
                echo -e "\n${COLOR_WARNING}💡 Dica: Compare os labels dos pods com o selector do service.${COLOR_RESET}"
            fi
        fi
    done
    
    wait_any_key
    remove_challenge_namespace "$namespace"
    return 0
}

# ============================================================================
# DESAFIO 1.4 - ConfigMap não aplicado
# ============================================================================
start_challenge_1_4() {
    local namespace="desafio-1-4"
    local title="ConfigMap não aplicado"
    
    remove_challenge_namespace "$namespace"
    kubectl create namespace "$namespace" &> /dev/null
    
    kubectl apply -f - <<EOF &> /dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: $namespace
data:
  APP_ENV: "production"
  APP_DEBUG: "false"
  DATABASE_HOST: "db.example.com"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: $namespace
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
EOF
    
    sleep 8
    
    show_challenge 1 4 "$title" \
        "Uma aplicação deveria estar lendo variáveis de ambiente de um ConfigMap, mas os valores não estão sendo aplicados." \
        "Corrigir a configuração para que a aplicação receba as variáveis corretas." \
        "$namespace" \
        "kubectl get configmap -n $namespace" \
        "kubectl describe pod <pod-name> -n $namespace" \
        "kubectl exec <pod-name> -n $namespace -- env | grep APP_"
    
    local resolved=false
    while [ "$resolved" = false ]; do
        wait_any_key "Pressione ENTER quando resolver o desafio..."
        
        local pod_name=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$pod_name" ] && kubectl exec "$pod_name" -n "$namespace" -- env 2>&1 | grep -q "APP_ENV"; then
            echo -e "${COLOR_SUCCESS}✅ Ótimo! As variáveis agora estão disponíveis!${COLOR_RESET}"
            resolved=true
        else
            echo -e "${COLOR_ERROR}❌ As variáveis ainda não estão no pod. Tente novamente!${COLOR_RESET}"
            if get_yes_no "Deseja ver uma dica?"; then
                echo -e "\n${COLOR_WARNING}💡 Dica: O ConfigMap existe, mas precisa ser referenciado no pod (envFrom).${COLOR_RESET}"
            fi
        fi
    done
    
    wait_any_key
    remove_challenge_namespace "$namespace"
    return 0
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================
main() {
    show_banner
    check_prerequisites
    
    # Selecionar nível
    if [ -z "$LEVEL" ]; then
        LEVEL=$(get_level_selection)
        if [ "$LEVEL" = "0" ]; then
            echo -e "${COLOR_INFO}👋 Até logo!${COLOR_RESET}"
            exit 0
        fi
    fi
    
    # Definir desafios por nível
    local max_challenges=4
    case $LEVEL in
        1) max_challenges=4 ;;
        2) max_challenges=5 ;;
        3) max_challenges=5 ;;
        4) max_challenges=6 ;;
    esac
    
    # Selecionar desafio
    if [ -z "$CHALLENGE" ]; then
        CHALLENGE=$(get_challenge_selection "$LEVEL" "$max_challenges")
    fi
    
    # Determinar quais desafios executar
    local challenges_to_run=()
    if [ "$CHALLENGE" = "0" ]; then
        for ((i=1; i<=max_challenges; i++)); do
            challenges_to_run+=("$i")
        done
    else
        challenges_to_run=("$CHALLENGE")
    fi
    
    # Executar desafios
    for num in "${challenges_to_run[@]}"; do
        local challenge_key="Desafio $LEVEL.$num"
        local success=false
        
        if [ "$LEVEL" = "1" ]; then
            case $num in
                1) start_challenge_1_1 && success=true ;;
                2) start_challenge_1_2 && success=true ;;
                3) start_challenge_1_3 && success=true ;;
                4) start_challenge_1_4 && success=true ;;
            esac
        else
            echo -e "\n${COLOR_WARNING}⚠️  Desafio $challenge_key ainda não implementado neste script.${COLOR_RESET}"
            echo -e "${COLOR_INFO}   Consulte SETUP.md para criar manualmente.${COLOR_RESET}"
            wait_any_key
            continue
        fi
        
        RESULTS+=("$challenge_key:$success")
    done
    
    # Mostrar resultado final
    if [ ${#RESULTS[@]} -gt 0 ]; then
        show_score
    fi
    
    echo -e "${COLOR_INFO}✨ Obrigado por usar o Desafio Runner!${COLOR_RESET}\n"
}

# Executar
main "$@"
