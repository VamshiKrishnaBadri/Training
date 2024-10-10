# Parameters
$organization = "wwtraining"    # Azure DevOps organization name
$project = "Demo"              # Azure DevOps project name
$pipelineId = "1"            # ID of your pipeline
$pat = "$env:AZURE_DEVOPS_PAT"         # Azure DevOps Personal Access Token (PAT)

# Base64-encode the PAT for the authorization header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# API URL to get the latest builds from the pipeline
$url = "https://dev.azure.com/$organization/$project/_apis/build/builds?definitions=$pipelineId&api-version=6.0"

# Make a GET request to Azure DevOps REST API
$response = Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# Get the latest build details
$latestBuild = $response.value | Select-Object -First 1

# Output build information
$buildId = $latestBuild.id
$buildStatus = $latestBuild.status
$buildResult = $latestBuild.result
$buildLink = $latestBuild._links.web.href

Write-Output "Build ID: $buildId"
Write-Output "Status: $buildStatus"
Write-Output "Result: $buildResult"
Write-Output "Build Link: $buildLink"
