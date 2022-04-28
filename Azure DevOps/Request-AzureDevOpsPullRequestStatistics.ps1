# --- Create Azure DevOps personal access token ---
# URL: https://dev.azure.com/timelogonline/_usersSettings/tokens
# Add access for "Code (Read)"
# --- Usage: ---
# Write-Host "Register the function"
# . .\Request-AzureDevOpsPullRequestStatistics.ps1
# 
# $personalAccessToken = ''
# $organization = ''
# $project = ''
# $repositoryId = ''
# 
# Request-AzureDevOpsPullRequestStatistics $personalAccessToken $organization $project $repositoryId

Function Request-AzureDevOpsPullRequestStatistics
{
    param(
    [Parameter (Mandatory = $true)][String]$personalAccessToken,
    [Parameter (Mandatory = $true)][String]$organization,
    [Parameter (Mandatory = $true)][String]$project,
    [Parameter (Mandatory = $true)][String]$repositoryId
    )

    $skip = 0
    $top = 1000
    $ballout = 10000
    $allResults = New-Object -TypeName System.Collections.ArrayList

    while ($latestResultCount -ne 0 -or $allResults.Count -eq 0)
    {
        Write-Host "Fetching $top results, skipping $skip"
        $pullRequestsUri = ('https://dev.azure.com/' + $organization + '/' + $project + '/_apis/git/repositories/' + $repositoryId + '/pullrequests?api-version=6.0&searchCriteria.status=completed')
        $pullRequestsUri += '&$top=' + $top
        $pullRequestsUri += '&$skip=' + $skip

        $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)")) }
        $pullRequests = Invoke-RestMethod -Uri $pullRequestsUri -Headers $AzureDevOpsAuthenicationHeader

        $result = $pullRequests.value | Select-Object `
            @{Name='pullRequestId';Expression={$_.pullRequestId}}, `
            @{Name='title';Expression={$_.title}}, `
            @{Name='creationDate';Expression={[DateTime]$_.creationDate}}, `
            @{Name='closedDate';Expression={[DateTime]$_.closedDate}}, `
            @{Name='status';Expression={$_.status}}, `
            @{Name='leadTimeHours';Expression={([DateTime]$_.closedDate).Subtract([DateTime]$_.creationDate).TotalHours}},
            @{Name='leadTimeDays';Expression={([DateTime]$_.closedDate).Subtract([DateTime]$_.creationDate).TotalDays}}
            #@{Name='';Expression={}},

        $allResults.Add($result) >> null

        $latestResultCount = $pullRequests.value.Length
        $skip += $top

        if ($ballout -le $skip)
        {
            break;
        }

        Start-Sleep -Seconds 1
    }

    $allResults | Where-Object {$_ -ne $null} | foreach-object {$_} | Export-Csv -Path .\AzureDevOpsStats.csv -NoTypeInformation
}