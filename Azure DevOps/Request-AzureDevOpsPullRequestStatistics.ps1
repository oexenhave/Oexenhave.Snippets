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
    [Parameter (Mandatory = $true)][String]$organization
    )

    $allResults = New-Object -TypeName System.Collections.ArrayList

    $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)")) }

    $projectsUri = ('https://dev.azure.com/' + $organization + '/_apis/projects?stateFilter=wellFormed')
    $projects = Invoke-RestMethod -Uri $projectsUri -Headers $AzureDevOpsAuthenicationHeader

    foreach ($project in $projects.value)
    {
        Write-Host ('Project: ' + $project.name)
        $repositoriesUri = ('https://dev.azure.com/' + $organization + '/' + $project.name + '/_apis/git/repositories')
        $repositories = Invoke-RestMethod -Uri $repositoriesUri -Headers $AzureDevOpsAuthenicationHeader
        foreach ($repository in $repositories.value)
        {
            Write-Host (' -> Repository: ' + $repository.name)
            
            $skip = 0
            $top = 1000
            $ballout = 10000
            $firstRequest = $true

            while ($latestResultCount -ne 0 -or $firstRequest -eq $true)
            {
                $firstRequest = $false

                Write-Host "Fetching $top results, skipping $skip"
                $pullRequestsUri = ('https://dev.azure.com/' + $organization + '/' + $project.name + '/_apis/git/repositories/' + $repository.id + '/pullrequests?api-version=6.0&searchCriteria.status=completed')
                $pullRequestsUri += '&$top=' + $top
                $pullRequestsUri += '&$skip=' + $skip

                Write-Host $pullRequestsUri
                $pullRequests = Invoke-RestMethod -Uri $pullRequestsUri -Headers $AzureDevOpsAuthenicationHeader

                $result = $pullRequests.value | Select-Object `
                    @{Name='project';Expression={$project.name}}, `
                    @{Name='repository';Expression={$repository.name}}, `
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
        }
    }

    $allResults | Where-Object {$_ -ne $null} | foreach-object {$_} | Export-Csv -Path .\AzureDevOpsStats.csv -NoTypeInformation
}