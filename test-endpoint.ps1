# Script de teste completo para o endpoint /identify
# Testa todos os cenários: CPF inválido, CPF válido, fluxo Cognito CUSTOM_AUTH

param(
    [string]$ApiUrl = "https://84n1x9fx52.execute-api.us-east-1.amazonaws.com"
)

$ErrorActionPreference = 'Continue'

Write-Host "=== TESTE COMPLETO DO ENDPOINT /identify ===" -ForegroundColor Green
Write-Host "API URL: $ApiUrl" -ForegroundColor Yellow
Write-Host ""

# Função para fazer requisições HTTP com tratamento de erro
function Invoke-TestRequest {
    param(
        [string]$Url,
        [string]$Method = "POST",
        [string]$Body,
        [string]$Description
    )
    
    Write-Host "🧪 Testando: $Description" -ForegroundColor Cyan
    Write-Host "   URL: $Url"
    Write-Host "   Body: $Body"
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $Body -ContentType 'application/json' -TimeoutSec 30
        Write-Host "   ✅ Status: SUCCESS" -ForegroundColor Green
        Write-Host "   Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorBody = ""
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
        }
        catch {
            $errorBody = $_.Exception.Message
        }
        
        Write-Host "   ❌ Status: ERROR ($statusCode)" -ForegroundColor Red
        Write-Host "   Error: $errorBody" -ForegroundColor Red
        return $null
    }
    
    Write-Host ""
}

# Teste 1: CPF inválido (formato)
Write-Host "--- TESTE 1: CPF com formato inválido ---" -ForegroundColor Yellow
$body1 = @{ cpf = "123" } | ConvertTo-Json
$response1 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body1 -Description "CPF muito curto"

# Teste 2: CPF inválido (dígitos verificadores)
Write-Host "--- TESTE 2: CPF com dígitos verificadores inválidos ---" -ForegroundColor Yellow
$body2 = @{ cpf = "12345678901" } | ConvertTo-Json
$response2 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body2 -Description "CPF com dígitos inválidos"

# Teste 3: CPF válido
Write-Host "--- TESTE 3: CPF válido ---" -ForegroundColor Yellow
$body3 = @{ cpf = "11144477735" } | ConvertTo-Json  # CPF válido
$response3 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body3 -Description "CPF válido"

# Teste 4: Sem CPF no body
Write-Host "--- TESTE 4: Request sem CPF ---" -ForegroundColor Yellow
$body4 = @{ } | ConvertTo-Json
$response4 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body4 -Description "Request sem campo CPF"

# Teste 5: CPF nulo
Write-Host "--- TESTE 5: CPF nulo ---" -ForegroundColor Yellow
$body5 = @{ cpf = $null } | ConvertTo-Json
$response5 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body5 -Description "CPF nulo"

# Teste 6: Outro CPF válido
Write-Host "--- TESTE 6: Outro CPF válido ---" -ForegroundColor Yellow
$body6 = @{ cpf = "02890291076" } | ConvertTo-Json  # Outro CPF válido
$response6 = Invoke-TestRequest -Url "$ApiUrl/identify" -Body $body6 -Description "Segundo CPF válido"

# Teste 7: Endpoint inexistente
Write-Host "--- TESTE 7: Endpoint inexistente ---" -ForegroundColor Yellow
$response7 = Invoke-TestRequest -Url "$ApiUrl/nonexistent" -Body $body3 -Description "Endpoint que não existe"

# Resumo dos testes
Write-Host "=== RESUMO DOS TESTES ===" -ForegroundColor Green
Write-Host "Teste 1 (CPF curto): $( if ($response1 -eq $null) { '❌ FALHOU' } else { '✅ PASSOU' })"
Write-Host "Teste 2 (CPF inválido): $( if ($response2 -eq $null) { '❌ FALHOU' } else { '✅ PASSOU' })"
Write-Host "Teste 3 (CPF válido): $( if ($response3 -ne $null) { '✅ PASSOU' } else { '❌ FALHOU' })"
Write-Host "Teste 4 (Sem CPF): $( if ($response4 -eq $null) { '❌ FALHOU' } else { '✅ PASSOU' })"
Write-Host "Teste 5 (CPF nulo): $( if ($response5 -eq $null) { '❌ FALHOU' } else { '✅ PASSOU' })"
Write-Host "Teste 6 (Segundo CPF): $( if ($response6 -ne $null) { '✅ PASSOU' } else { '❌ FALHOU' })"
Write-Host "Teste 7 (404): $( if ($response7 -eq $null) { '❌ FALHOU' } else { '✅ PASSOU' })"

# Informações adicionais para debug
Write-Host ""
Write-Host "=== INFORMAÇÕES PARA DEBUG ===" -ForegroundColor Magenta

# Verificar logs da Lambda (se tiver permissão)
Write-Host "🔍 Verificando logs da Lambda..." -ForegroundColor Cyan
try {
    $logGroups = aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/fast-food-auth" --query 'logGroups[].logGroupName' --output text 2>$null
    if ($logGroups) {
        Write-Host "   Log Groups encontrados: $logGroups" -ForegroundColor Green
        
        # Pegar logs mais recentes
        $recentLogs = aws logs filter-log-events --log-group-name "/aws/lambda/fast-food-auth-identify-dev" --start-time $((Get-Date).AddMinutes(-10).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")) --query 'events[].message' --output text 2>$null
        if ($recentLogs) {
            Write-Host "   Logs recentes:" -ForegroundColor Yellow
            Write-Host "   $recentLogs"
        }
    } else {
        Write-Host "   ⚠️  Não foi possível acessar os logs da Lambda" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   ⚠️  Erro ao acessar logs: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Verificar se a Lambda existe
Write-Host ""
Write-Host "🔍 Verificando status da Lambda..." -ForegroundColor Cyan
try {
    $lambdaInfo = aws lambda get-function --function-name "fast-food-auth-identify-dev" --query 'Configuration.{State:State,LastModified:LastModified,Runtime:Runtime}' --output json 2>$null | ConvertFrom-Json
    if ($lambdaInfo) {
        Write-Host "   ✅ Lambda existe" -ForegroundColor Green
        Write-Host "   Estado: $($lambdaInfo.State)" -ForegroundColor Green
        Write-Host "   Última modificação: $($lambdaInfo.LastModified)" -ForegroundColor Green
        Write-Host "   Runtime: $($lambdaInfo.Runtime)" -ForegroundColor Green
    }
}
catch {
    Write-Host "   ❌ Lambda não encontrada ou sem permissão" -ForegroundColor Red
}

# Verificar se o API Gateway existe
Write-Host ""
Write-Host "🔍 Verificando status do API Gateway..." -ForegroundColor Cyan
try {
    $apiId = $ApiUrl.Split('.')[0].Replace('https://', '')
    $apiInfo = aws apigatewayv2 get-api --api-id $apiId --query '{Name:Name,ProtocolType:ProtocolType,CreatedDate:CreatedDate}' --output json 2>$null | ConvertFrom-Json
    if ($apiInfo) {
        Write-Host "   ✅ API Gateway existe" -ForegroundColor Green
        Write-Host "   Nome: $($apiInfo.Name)" -ForegroundColor Green
        Write-Host "   Protocolo: $($apiInfo.ProtocolType)" -ForegroundColor Green
        Write-Host "   Criado em: $($apiInfo.CreatedDate)" -ForegroundColor Green
    }
}
catch {
    Write-Host "   ❌ API Gateway não encontrado ou sem permissão" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FIM DOS TESTES ===" -ForegroundColor Green
Write-Host "Execute novamente com: .\test-endpoint.ps1 -ApiUrl 'SUA_URL_AQUI'" -ForegroundColor Gray
