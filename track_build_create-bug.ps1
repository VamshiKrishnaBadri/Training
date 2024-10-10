# Parameters
$organization = "wwtraining"    # Azure DevOps organization name
$project = "Demo"              # Azure DevOps project name
$pipelineId = "1"            # ID of your pipeline
$pat = "$env:AZURE_DEVOPS_PAT"         # Azure DevOps Personal Access Token (PAT)

# Base64-encode the PAT for the authorization header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# API URL to get the latest builds from the pipeline
$url = "https://dev.azure.com/$organization/$project/_apis/build/builds?definitions=$pipelineId&api-version=6.0"

# Make a GET request to Azure DevOps REST API to get the latest build
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

# Check if the build failed
if ($buildResult -eq "failed") {
    Write-Output "Build failed, creating a Bug in Azure Boards..."

    # API URL to get build logs
    $logUrl = "https://dev.azure.com/$organization/$project/_apis/build/builds/$buildId/logs?api-version=6.0"
    $logsResponse = Invoke-RestMethod -Uri $logUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

    # Check if logs are available and retrieve the last few lines
    if ($logsResponse.value.Count -gt 0) {
        # Retrieve the last few lines of the log (assuming log is in string format)
        $logLines = $logsResponse.value | Select-Object -Last 10 | ForEach-Object { $_.text }
        $logsSummary = $logLines -join "`n"
    } else {
        $logsSummary = "No logs available for this build."
    }

    # API URL to create a new work item (Bug)
    $workItemUrl = "https://dev.azure.com/$organization/$project/_apis/wit/workitems/$`Bug?api-version=6.0"

    # Body of the new Bug
    $bugBody = @(
        @{
            "op" = "add"
            "path" = "/fields/System.Title"
            "value" = "Failed Build - Pipeline ID: $pipelineId"
        },
        @{
            "op" = "add"
            "path" = "/fields/System.Description"
            "value" = "Build failed for pipeline **$pipelineId**. Check build details: $buildLink`n`nLog Summary:`n$logsSummary"
        },
        @{
            "op" = "add"
            "path" = "/fields/Microsoft.VSTS.Common.Priority"
            "value" = 1  # Priority 1 (you can adjust as needed)
        },
        @{
            "op" = "add"
            "path" = "/fields/System.AssignedTo"
            "value" = "vamshi.b@waferwire.com"  # Replace with the email of the assignee
        }
        
    ) | ConvertTo-Json

    # Make a POST request to Azure DevOps REST API to create a Bug
    $bugResponse = Invoke-RestMethod -Uri $workItemUrl -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo); "Content-Type"="application/json-patch+json"} -Body $bugBody

    # Check for errors in bug creation
    if ($bugResponse -ne $null) {
        Write-Output "Bug created: $($bugResponse.id)"
    } else {
        Write-Output "Failed to create bug. Response: $($bugResponse | ConvertTo-Json)"
    }
}
else {
    Write-Output "Build did not fail, no Bug created."
}
