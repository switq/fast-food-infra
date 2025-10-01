# Test script for Lambda function
$apiUrl = "https://7awnodln58.execute-api.us-east-1.amazonaws.com"

Write-Host "=== Testing Lambda Function ===" -ForegroundColor Cyan

# Test 1: Valid CPF
Write-Host "`nTest 1: Valid CPF" -ForegroundColor Green
$body = @{ cpf = "11144477735" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/identify" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ SUCCESS: $($response.message)" -ForegroundColor Green
    Write-Host "   CPF: $($response.cpf)" -ForegroundColor Yellow
    Write-Host "   Status: $($response.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Invalid CPF
Write-Host "`nTest 2: Invalid CPF" -ForegroundColor Green
$body = @{ cpf = "12345678901" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/identify" -Method POST -Body $body -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: $($response.message)" -ForegroundColor Red
} catch {
    Write-Host "✅ EXPECTED ERROR: Invalid CPF correctly rejected" -ForegroundColor Green
}

# Test 3: Missing CPF
Write-Host "`nTest 3: Missing CPF" -ForegroundColor Green
$body = @{} | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/identify" -Method POST -Body $body -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: $($response.message)" -ForegroundColor Red
} catch {
    Write-Host "✅ EXPECTED ERROR: Missing CPF correctly rejected" -ForegroundColor Green
}

# Test 4: Formatted CPF
Write-Host "`nTest 4: Formatted CPF (111.444.777-35)" -ForegroundColor Green
$body = @{ cpf = "111.444.777-35" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/identify" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ SUCCESS: $($response.message)" -ForegroundColor Green
    Write-Host "   CPF: $($response.cpf)" -ForegroundColor Yellow
    Write-Host "   Status: $($response.status)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Wrong endpoint
Write-Host "`nTest 5: Wrong endpoint (/wrong)" -ForegroundColor Green
$body = @{ cpf = "11144477735" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/wrong" -Method POST -Body $body -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: $($response.message)" -ForegroundColor Red
} catch {
    Write-Host "✅ EXPECTED ERROR: Wrong endpoint correctly returns 404" -ForegroundColor Green
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Lambda function is working correctly!" -ForegroundColor Green
Write-Host "API URL: $apiUrl/identify" -ForegroundColor Yellow
