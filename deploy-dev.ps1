# deploy-dev.ps1
# Automates two-phase Terraform deploy for Cognito custom auth + Lambda triggers and adds permission for Cognito to invoke Lambda.
# Usage: .\deploy-dev.ps1 [-DevTfvarsPath '.\\dev.tfvars']

param(
  [string]$DevTfvarsPath = "./dev.tfvars"
)

$ErrorActionPreference = 'Stop'

Write-Host "Starting dev deployment (two-phase)"
$Root = Resolve-Path ".." | Select-Object -ExpandProperty Path
# Compute repo paths relative to infra
$RepoRoot = Resolve-Path "$(Split-Path -Path $PSScriptRoot -Parent)" | Select-Object -ExpandProperty Path
$InfraDir = Join-Path $RepoRoot 'infra'
$LambdaDir = Join-Path $RepoRoot 'fast-food-auth-lambda'

Write-Host "Repo root: $RepoRoot"
Write-Host "Lambda dir: $LambdaDir"
Write-Host "Infra dir: $InfraDir"

# 1) Build and package Lambda
Write-Host "\n==> Building and packaging Lambda"
Push-Location $LambdaDir
if (-Not (Test-Path node_modules)) {
  Write-Host "Installing npm dependencies..."
  npm ci
} else {
  Write-Host "node_modules exists, running npm ci to ensure consistency..."
  npm ci
}

Write-Host "Running build..."
npm run build

$deployDir = Join-Path $LambdaDir 'deploy'
if (-Not (Test-Path $deployDir)) { New-Item -ItemType Directory -Path $deployDir | Out-Null }
$zipPath = Join-Path $deployDir 'fast-food-auth-lambda.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Write-Host "Creating zip artifact at $zipPath"
Compress-Archive -Path (Join-Path $LambdaDir 'dist\*') -DestinationPath $zipPath -Force

Pop-Location

# 2) First Terraform apply (create User Pool, Lambda, API, Secrets, IAM)
Write-Host "\n==> Terraform init & first apply"
Push-Location $InfraDir
terraform init -input=false

Write-Host "Running terraform apply (phase 1) using $DevTfvarsPath"
terraform apply -var-file=$DevTfvarsPath -auto-approve

# 3) Discover resources
Write-Host "\n==> Discovering deployed resources"
# read region from dev.tfvars (simple parse)
$dev = Get-Content $DevTfvarsPath -Raw
$region = 'us-east-1'
$match = [regex]::Match($dev, 'aws_region\s*=\s*"([^"]+)"')
if ($match.Success) { $region = $match.Groups[1].Value }

# read lambda function name from dev.tfvars
$fnMatch = [regex]::Match($dev, 'lambda_function_name\s*=\s*"([^"]+)"')
if ($fnMatch.Success) { $functionName = $fnMatch.Groups[1].Value } else { $functionName = 'fast-food-auth-identify-dev' }
Write-Host "Lambda function name: $functionName"

# Get function ARN via AWS CLI
Write-Host "Retrieving Lambda ARN via AWS CLI"
$functionArn = aws lambda get-function --function-name $functionName --query 'Configuration.FunctionArn' --output text --region $region 2>$null
if (-not $functionArn) { Write-Host "Could not retrieve Lambda ARN. Ensure AWS CLI is configured and function exists."; Exit 1 }
Write-Host "Lambda ARN: $functionArn"

# 4) Create temporary tfvars to register Cognito triggers
$tempTfvars = Join-Path $InfraDir 'dev.cognito.tfvars'
@"
cognito_lambda_config = {
  define_auth_challenge = "$functionArn"
  create_auth_challenge = "$functionArn"
  verify_auth_challenge = "$functionArn"
}
"@ | Out-File -FilePath $tempTfvars -Encoding utf8
Write-Host "Created temp tfvars: $tempTfvars"

# 5) Second apply to wire triggers into Cognito
Write-Host "\n==> Terraform apply (phase 2) to register Cognito lambda_config"
terraform apply -var-file=$DevTfvarsPath -var-file=$tempTfvars -auto-approve

# 6) Add Lambda permission for Cognito to invoke the function
Write-Host "\n==> Adding lambda permission for Cognito to invoke the function"
$accountId = aws sts get-caller-identity --query Account --output text --region $region
$userPoolId = terraform output -raw cognito_user_pool_id
$sourceArn = "arn:aws:cognito-idp:${region}:${accountId}:userpool/${userPoolId}"

Write-Host "Source ARN for permission: $sourceArn"
$statementId = "cognito-invoke-$(Get-Random)"
try {
  aws lambda add-permission --function-name $functionName --statement-id $statementId --action lambda:InvokeFunction --principal cognito-idp.amazonaws.com --source-arn $sourceArn --region $region | Out-Null
  Write-Host "Added lambda permission with statement-id: $statementId"
} catch {
  Write-Warning "Failed to add permission. It may already exist or AWS CLI returned an error: $_"
}

# 7) Cleanup temp tfvars
Remove-Item $tempTfvars -Force

Write-Host "\nDeployment complete. Outputs (root):"
terraform output

Pop-Location

Write-Host "Done. Test the API endpoint and verify CloudWatch logs if needed."
