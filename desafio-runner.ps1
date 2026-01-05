<#
.SYNOPSIS
    Script interativo para executar desafios de troubleshooting Kubernetes

.DESCRIPTION
    Este script apresenta desafios de troubleshooting Kubernetes de forma interativa,
    criando automaticamente os cenários de falha, apresentando o desafio,
    aguardando a resolução do usuário, e verificando a solução.

.PARAMETER Level
    Nível de dificuldade (1-4). Se não especificado, pergunta ao usuário.

.PARAMETER Challenge
    Número do desafio específico. Se não especificado, executa todos do nível.

.EXAMPLE
    .\desafio-runner.ps1
    Modo interativo - pergunta nível e desafio

.EXAMPLE
    .\desafio-runner.ps1 -Level 1
    Executa todos os desafios do Nível 1

.EXAMPLE
    .\desafio-runner.ps1 -Level 2 -Challenge 3
    Executa apenas o Desafio 2.3
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,4)]
    [int]$Level,
    
    [Parameter(Mandatory=$false)]
    [int]$Challenge
)

# Cores para output
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"
$ColorPrompt = "Magenta"

# Verificar se kubectl está disponível
function Test-Prerequisites {
    Write-Host "`n🔍 Verificando pré-requisitos..." -ForegroundColor $ColorInfo
    
    # Verificar kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Host "❌ kubectl não encontrado! Instale kubectl primeiro." -ForegroundColor $ColorError
        exit 1
    }
    
    # Verificar cluster
    try {
        kubectl cluster-info | Out-Null
        Write-Host "✅ Cluster Kubernetes detectado" -ForegroundColor $ColorSuccess
    }
    catch {
        Write-Host "❌ Não foi possível conectar ao cluster Kubernetes!" -ForegroundColor $ColorError
        Write-Host "   Execute 'kubectl cluster-info' para diagnóstico." -ForegroundColor $ColorWarning
        exit 1
    }
    
    Write-Host ""
}

# Banner do desafio
function Show-Banner {
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host "    🔍 DESAFIOS DE TROUBLESHOOTING KUBERNETES 🔍      " -ForegroundColor $ColorInfo
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
}

# Aguardar tecla
function Wait-AnyKey {
    param([string]$Message = "Pressione qualquer tecla para continuar...")
    Write-Host "`n$Message" -ForegroundColor $ColorPrompt
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Aguardar resposta sim/não
function Get-YesNo {
    param([string]$Question)
    
    while ($true) {
        $response = Read-Host "$Question (s/n)"
        if ($response -match '^[sS]') { return $true }
        if ($response -match '^[nN]') { return $false }
        Write-Host "Por favor, responda 's' ou 'n'" -ForegroundColor $ColorWarning
    }
}

# Limpar namespace do desafio
function Remove-ChallengeNamespace {
    param([string]$Namespace)
    
    Write-Host "`n🧹 Limpando ambiente..." -ForegroundColor $ColorInfo
    kubectl delete namespace $Namespace --ignore-not-found=true --wait=false 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "✅ Ambiente limpo" -ForegroundColor $ColorSuccess
}

# Menu de seleção de nível
function Get-LevelSelection {
    Write-Host "`n📊 Selecione o nível de dificuldade:" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  1. 🟢 Nível 1 - Iniciante      (4 desafios)" -ForegroundColor "Green"
    Write-Host "  2. 🟡 Nível 2 - Intermediário  (5 desafios)" -ForegroundColor "Yellow"
    Write-Host "  3. 🟠 Nível 3 - Avançado       (5 desafios)" -ForegroundColor "DarkYellow"
    Write-Host "  4. 🔴 Nível 4 - Expert         (6 desafios)" -ForegroundColor "Red"
    Write-Host "  0. ❌ Sair" -ForegroundColor "Gray"
    Write-Host ""
    
    while ($true) {
        $selection = Read-Host "Digite o número do nível"
        if ($selection -match '^[0-4]$') {
            return [int]$selection
        }
        Write-Host "Opção inválida! Digite 0-4" -ForegroundColor $ColorWarning
    }
}

# Menu de seleção de desafio
function Get-ChallengeSelection {
    param([int]$Level, [int]$MaxChallenges)
    
    Write-Host "`n🎯 Selecione o desafio:" -ForegroundColor $ColorInfo
    Write-Host ""
    for ($i = 1; $i -le $MaxChallenges; $i++) {
        Write-Host "  $i. Desafio $Level.$i"
    }
    Write-Host "  0. Todos os desafios do nível" -ForegroundColor "Cyan"
    Write-Host ""
    
    while ($true) {
        $selection = Read-Host "Digite o número do desafio (0 para todos)"
        if ($selection -match "^[0-$MaxChallenges]$") {
            return [int]$selection
        }
        Write-Host "Opção inválida! Digite 0-$MaxChallenges" -ForegroundColor $ColorWarning
    }
}

# Apresentar desafio
function Show-Challenge {
    param(
        [int]$Level,
        [int]$ChallengeNum,
        [string]$Title,
        [string]$Scenario,
        [string]$Objective,
        [string]$Namespace,
        [string[]]$InitialCommands
    )
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host " 📋 DESAFIO $Level.$ChallengeNum - $Title" -ForegroundColor $ColorInfo
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "📖 CENÁRIO:" -ForegroundColor "Yellow"
    Write-Host "   $Scenario" -ForegroundColor "White"
    Write-Host ""
    Write-Host "🎯 OBJETIVO:" -ForegroundColor "Green"
    Write-Host "   $Objective" -ForegroundColor "White"
    Write-Host ""
    Write-Host "🔧 COMANDOS INICIAIS SUGERIDOS:" -ForegroundColor "Cyan"
    foreach ($cmd in $InitialCommands) {
        Write-Host "   $cmd" -ForegroundColor "Gray"
    }
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────" -ForegroundColor "DarkGray"
    Write-Host ""
    Write-Host "⏱️  Ambiente criado! O desafio está pronto." -ForegroundColor $ColorSuccess
    Write-Host "💡 Dica: Use outro terminal para resolver o desafio" -ForegroundColor $ColorWarning
    Write-Host ""
}

# Verificar solução
function Test-Solution {
    param(
        [string]$Namespace,
        [scriptblock]$ValidationScript
    )
    
    Write-Host "`n🔍 Verificando solução..." -ForegroundColor $ColorInfo
    Start-Sleep -Seconds 2
    
    try {
        $result = & $ValidationScript
        return $result
    }
    catch {
        return $false
    }
}

# Mostrar pontuação
function Show-Score {
    param([hashtable]$Results)
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host "              📊 RESULTADO FINAL 📊                    " -ForegroundColor $ColorInfo
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $total = 0
    $correct = 0
    
    foreach ($key in $Results.Keys | Sort-Object) {
        $total++
        if ($Results[$key]) {
            $correct++
            Write-Host "  ✅ $key - Resolvido" -ForegroundColor $ColorSuccess
        }
        else {
            Write-Host "  ❌ $key - Não resolvido" -ForegroundColor $ColorError
        }
    }
    
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────" -ForegroundColor "DarkGray"
    
    $percentage = [math]::Round(($correct / $total) * 100, 0)
    $points = $correct * 10
    
    Write-Host ""
    Write-Host "  Desafios completados: $correct de $total" -ForegroundColor "White"
    Write-Host "  Pontuação: $points pontos" -ForegroundColor "Cyan"
    Write-Host "  Percentual: $percentage%" -ForegroundColor "Cyan"
    Write-Host ""
    
    # Certificação
    if ($points -ge 180) {
        Write-Host "  🥇 CERTIFICAÇÃO: OURO - Conhecimento Avançado!" -ForegroundColor "Yellow"
    }
    elseif ($points -ge 140) {
        Write-Host "  🥈 CERTIFICAÇÃO: PRATA - Conhecimento Intermediário" -ForegroundColor "Gray"
    }
    elseif ($points -ge 100) {
        Write-Host "  🥉 CERTIFICAÇÃO: BRONZE - Conhecimento Básico" -ForegroundColor "DarkYellow"
    }
    else {
        Write-Host "  📚 Continue praticando! Você está no caminho certo." -ForegroundColor "White"
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
}

# ============================================================================
# DESAFIO 1.1 - ImagePullBackOff
# ============================================================================
function Start-Challenge1_1 {
    $namespace = "desafio-1-1"
    $title = "Pod que não inicia"
    
    # Limpar ambiente anterior
    Remove-ChallengeNamespace $namespace
    
    # Criar namespace
    kubectl create namespace $namespace 2>&1 | Out-Null
    
    # Criar deployment com erro
    @"
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
"@ | kubectl apply -f - 2>&1 | Out-Null
    
    Start-Sleep -Seconds 5
    
    # Apresentar desafio
    Show-Challenge -Level 1 -ChallengeNum 1 -Title $title `
        -Scenario "Foi feito o deploy de uma aplicação web chamada 'webapp-nginx', mas o pod está com status ImagePullBackOff." `
        -Objective "Identificar e corrigir o problema para que o pod entre em estado Running." `
        -Namespace $namespace `
        -InitialCommands @(
            "kubectl get pods -n $namespace",
            "kubectl describe pod <pod-name> -n $namespace"
        )
    
    # Aguardar resolução
    $resolved = $false
    while (-not $resolved) {
        Wait-AnyKey "Pressione qualquer tecla quando resolver o desafio..."
        
        # Validar solução
        $validation = Test-Solution -Namespace $namespace -ValidationScript {
            $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
            $runningPods = $pods.items | Where-Object { $_.status.phase -eq "Running" }
            return ($runningPods.Count -gt 0)
        }
        
        if ($validation) {
            Write-Host "✅ Parabéns! Desafio resolvido corretamente!" -ForegroundColor $ColorSuccess
            $resolved = $true
        }
        else {
            Write-Host "❌ O pod ainda não está rodando. Continue tentando!" -ForegroundColor $ColorError
            if (Get-YesNo "Deseja ver uma dica?") {
                Write-Host "`n💡 Dica: Verifique o nome da imagem no describe do pod." -ForegroundColor $ColorWarning
            }
        }
    }
    
    Wait-AnyKey
    Remove-ChallengeNamespace $namespace
    return $true
}

# ============================================================================
# DESAFIO 1.2 - CrashLoopBackOff
# ============================================================================
function Start-Challenge1_2 {
    $namespace = "desafio-1-2"
    $title = "Pod crashando constantemente"
    
    Remove-ChallengeNamespace $namespace
    kubectl create namespace $namespace 2>&1 | Out-Null
    
    # Criar ConfigMap
    @"
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
"@ | kubectl apply -f - 2>&1 | Out-Null
    
    # Criar deployment
    @"
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
"@ | kubectl apply -f - 2>&1 | Out-Null
    
    Start-Sleep -Seconds 10
    
    Show-Challenge -Level 1 -ChallengeNum 2 -Title $title `
        -Scenario "O pod 'api-backend' está em loop de restart com status CrashLoopBackOff. A aplicação é um servidor Node.js simples." `
        -Objective "Descobrir por que a aplicação está crashando e corrigir o problema." `
        -Namespace $namespace `
        -InitialCommands @(
            "kubectl get pods -n $namespace",
            "kubectl logs <pod-name> -n $namespace",
            "kubectl describe pod <pod-name> -n $namespace"
        )
    
    $resolved = $false
    while (-not $resolved) {
        Wait-AnyKey "Pressione qualquer tecla quando resolver o desafio..."
        
        $validation = Test-Solution -Namespace $namespace -ValidationScript {
            Start-Sleep -Seconds 5
            $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
            $runningPods = $pods.items | Where-Object { 
                $_.status.phase -eq "Running" -and $_.status.containerStatuses[0].restartCount -eq 0
            }
            return ($runningPods.Count -gt 0)
        }
        
        if ($validation) {
            Write-Host "✅ Parabéns! Desafio resolvido!" -ForegroundColor $ColorSuccess
            $resolved = $true
        }
        else {
            Write-Host "❌ O pod ainda está crashando ou reiniciando. Tente novamente!" -ForegroundColor $ColorError
            if (Get-YesNo "Deseja ver uma dica?") {
                Write-Host "`n💡 Dica: Verifique os logs e a variável de ambiente PORT." -ForegroundColor $ColorWarning
            }
        }
    }
    
    Wait-AnyKey
    Remove-ChallengeNamespace $namespace
    return $true
}

# ============================================================================
# DESAFIO 1.3 - Service sem endpoints
# ============================================================================
function Start-Challenge1_3 {
    $namespace = "desafio-1-3"
    $title = "Service não expondo o pod"
    
    Remove-ChallengeNamespace $namespace
    kubectl create namespace $namespace 2>&1 | Out-Null
    
    @"
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
"@ | kubectl apply -f - 2>&1 | Out-Null
    
    Start-Sleep -Seconds 8
    
    Show-Challenge -Level 1 -ChallengeNum 3 -Title $title `
        -Scenario "Você tem um deployment 'frontend' rodando perfeitamente, mas ao tentar acessar via service, recebe erro de conexão." `
        -Objective "Identificar por que o service não está encaminhando tráfego para os pods." `
        -Namespace $namespace `
        -InitialCommands @(
            "kubectl get pods,svc -n $namespace",
            "kubectl describe svc frontend-service -n $namespace",
            "kubectl get endpoints -n $namespace"
        )
    
    $resolved = $false
    while (-not $resolved) {
        Wait-AnyKey "Pressione qualquer tecla quando resolver o desafio..."
        
        $validation = Test-Solution -Namespace $namespace -ValidationScript {
            $endpoints = kubectl get endpoints frontend-service -n $namespace -o json | ConvertFrom-Json
            return ($endpoints.subsets.Count -gt 0 -and $endpoints.subsets[0].addresses.Count -gt 0)
        }
        
        if ($validation) {
            Write-Host "✅ Excelente! O service agora tem endpoints!" -ForegroundColor $ColorSuccess
            $resolved = $true
        }
        else {
            Write-Host "❌ O service ainda não tem endpoints. Continue!" -ForegroundColor $ColorError
            if (Get-YesNo "Deseja ver uma dica?") {
                Write-Host "`n💡 Dica: Compare os labels dos pods com o selector do service." -ForegroundColor $ColorWarning
            }
        }
    }
    
    Wait-AnyKey
    Remove-ChallengeNamespace $namespace
    return $true
}

# ============================================================================
# DESAFIO 1.4 - ConfigMap não aplicado
# ============================================================================
function Start-Challenge1_4 {
    $namespace = "desafio-1-4"
    $title = "ConfigMap não aplicado"
    
    Remove-ChallengeNamespace $namespace
    kubectl create namespace $namespace 2>&1 | Out-Null
    
    @"
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
"@ | kubectl apply -f - 2>&1 | Out-Null
    
    Start-Sleep -Seconds 8
    
    Show-Challenge -Level 1 -ChallengeNum 4 -Title $title `
        -Scenario "Uma aplicação deveria estar lendo variáveis de ambiente de um ConfigMap, mas os valores não estão sendo aplicados." `
        -Objective "Corrigir a configuração para que a aplicação receba as variáveis corretas." `
        -Namespace $namespace `
        -InitialCommands @(
            "kubectl get configmap -n $namespace",
            "kubectl describe pod <pod-name> -n $namespace",
            "kubectl exec <pod-name> -n $namespace -- env | grep APP_"
        )
    
    $resolved = $false
    while (-not $resolved) {
        Wait-AnyKey "Pressione qualquer tecla quando resolver o desafio..."
        
        $validation = Test-Solution -Namespace $namespace -ValidationScript {
            $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
            if ($pods.items.Count -eq 0) { return $false }
            
            $podName = $pods.items[0].metadata.name
            $envVars = kubectl exec $podName -n $namespace -- env 2>&1
            return ($envVars -match "APP_ENV")
        }
        
        if ($validation) {
            Write-Host "✅ Ótimo! As variáveis agora estão disponíveis!" -ForegroundColor $ColorSuccess
            $resolved = $true
        }
        else {
            Write-Host "❌ As variáveis ainda não estão no pod. Tente novamente!" -ForegroundColor $ColorError
            if (Get-YesNo "Deseja ver uma dica?") {
                Write-Host "`n💡 Dica: O ConfigMap existe, mas precisa ser referenciado no pod (envFrom)." -ForegroundColor $ColorWarning
            }
        }
    }
    
    Wait-AnyKey
    Remove-ChallengeNamespace $namespace
    return $true
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================
function Start-ChallengeRunner {
    Show-Banner
    Test-Prerequisites
    
    # Selecionar nível
    if (-not $Level) {
        $Level = Get-LevelSelection
        if ($Level -eq 0) {
            Write-Host "👋 Até logo!" -ForegroundColor $ColorInfo
            return
        }
    }
    
    # Definir desafios por nível
    $challengesPerLevel = @{
        1 = 4
        2 = 5
        3 = 5
        4 = 6
    }
    
    $maxChallenges = $challengesPerLevel[$Level]
    
    # Selecionar desafio específico ou todos
    if (-not $Challenge) {
        $Challenge = Get-ChallengeSelection -Level $Level -MaxChallenges $maxChallenges
    }
    
    # Determinar quais desafios executar
    $challengesToRun = @()
    if ($Challenge -eq 0) {
        $challengesToRun = 1..$maxChallenges
    }
    else {
        $challengesToRun = @($Challenge)
    }
    
    # Resultados
    $results = @{}
    
    # Executar desafios
    foreach ($num in $challengesToRun) {
        $challengeKey = "Desafio $Level.$num"
        
        # Executar desafio apropriado
        $success = $false
        
        # Nível 1
        if ($Level -eq 1) {
            switch ($num) {
                1 { $success = Start-Challenge1_1 }
                2 { $success = Start-Challenge1_2 }
                3 { $success = Start-Challenge1_3 }
                4 { $success = Start-Challenge1_4 }
            }
        }
        # Adicionar mais níveis aqui conforme necessário
        else {
            Write-Host "`n⚠️  Desafio $challengeKey ainda não implementado neste script." -ForegroundColor $ColorWarning
            Write-Host "   Consulte SETUP.md para criar manualmente." -ForegroundColor $ColorInfo
            Wait-AnyKey
            continue
        }
        
        $results[$challengeKey] = $success
    }
    
    # Mostrar resultado final
    if ($results.Count -gt 0) {
        Show-Score -Results $results
    }
    
    Write-Host "✨ Obrigado por usar o Desafio Runner!" -ForegroundColor $ColorInfo
    Write-Host ""
}

# Executar
Start-ChallengeRunner
