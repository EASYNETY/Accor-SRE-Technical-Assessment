param(
  [string]$BucketName = "redemption-terraform-state",
  [string]$DynamoTable = "redemption-terraform-lock",
  [string]$Region = $env:AWS_DEFAULT_REGION
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

if (-not $Region) {
  Write-Error "AWS_DEFAULT_REGION environment variable not set. Set it and re-run, e.g. `$env:AWS_DEFAULT_REGION='us-east-1'"
  exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  Write-Error "AWS CLI not found in PATH. Install AWS CLI v2 before continuing."
  exit 1
}

Write-Host "Creating S3 bucket '$BucketName' in region '$Region'..."
try {
  if ($Region -eq 'us-east-1') {
    aws s3api create-bucket --bucket $BucketName --region $Region | Out-Null
  } else {
    aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region | Out-Null
  }
} catch {
  Write-Warning "Create-bucket returned an error: $_"
}

Write-Host "Enabling versioning on bucket..."
aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration '{"Status":"Enabled"}'

Write-Host "Enabling server-side encryption (AES256)..."
aws s3api put-bucket-encryption --bucket $BucketName --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

Write-Host "Creating DynamoDB table '$DynamoTable' for state locking..."
aws dynamodb create-table --table-name $DynamoTable --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region $Region

Write-Host "Backend bootstrap completed."

# Try to run terraform init -reconfigure if terraform is available
$tf = $null
if (Get-Command terraform -ErrorAction SilentlyContinue) { $tf = 'terraform' }
elseif (Test-Path (Join-Path $scriptDir 'terraform.exe')) { $tf = Join-Path $scriptDir 'terraform.exe' }
elseif (Test-Path (Join-Path $scriptDir '..\terraform.exe')) { $tf = Join-Path $scriptDir '..\terraform.exe' }

if ($tf) {
  Write-Host "Running '$tf init -reconfigure' in 'infra\\terraform'..."
  Push-Location (Join-Path $scriptDir 'infra\\terraform')
  & $tf init -reconfigure
  Pop-Location
  Write-Host "If init succeeded, run plan/apply as needed."
} else {
  Write-Host "Terraform binary not found on PATH or repo root. Run init manually with the terraform executable."
}
