# Teste simples do endpoint
$apiUrl = "https://84n1x9fx52.execute-api.us-east-1.amazonaws.com"

Write-Host "=== TESTE ENDPOINT /identify ===" -ForegroundColor Green
Write-Host "URL: $apiUrl" -ForegroundColor Yellow
Write-Host ""

# Teste 1: CPF inválido
Write-Host "TESTE 1: CPF inválido" -ForegroundColor Cyan
$body1 = '{"cpf":"123"}'
try {
    $result1 = Invoke-RestMethod -Uri "$apiUrl/identify" -Method Post -Body $body1 -ContentType 'application/json'
    Write-Host "Resultado: $($result1 | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Erro (esperado): $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Teste 2: CPF válido  
Write-Host "TESTE 2: CPF válido" -ForegroundColor Cyan
$body2 = '{"cpf":"11144477735"}'
try {
    $result2 = Invoke-RestMethod -Uri "$apiUrl/identify" -Method Post -Body $body2 -ContentType 'application/json'
    Write-Host "Resultado: $($result2 | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Teste 3: Sem CPF
Write-Host "TESTE 3: Request sem CPF" -ForegroundColor Cyan
$body3 = '{}'
try {
    $result3 = Invoke-RestMethod -Uri "$apiUrl/identify" -Method Post -Body $body3 -ContentType 'application/json'
    Write-Host "Resultado: $($result3 | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Erro (esperado): $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Teste 4: Endpoint 404
Write-Host "TESTE 4: Endpoint inexistente" -ForegroundColor Cyan
try {
    $result4 = Invoke-RestMethod -Uri "$apiUrl/inexistente" -Method Post -Body $body2 -ContentType 'application/json'
    Write-Host "Resultado inesperado: $($result4 | ConvertTo-Json)" -ForegroundColor Red
} catch {
    Write-Host "404 (esperado): OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== FIM DOS TESTES ===" -ForegroundColor Green
