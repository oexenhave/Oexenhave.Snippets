Connect-MgGraph -Scopes "Group.Read.All", "Group.ReadWrite.All"

# Get all groups
$groups = Invoke-MgGraphRequest -Method GET 'https://graph.microsoft.com/v1.0/groups'

$allResults = New-Object -TypeName System.Collections.ArrayList

# For each group, get plans
foreach ($group in $groups.value) {

    # Get the plans for the group
    $plans = Invoke-MgGraphRequest -Method GET ("https://graph.microsoft.com/v1.0/groups/" + $group.id + "/planner/plans")

    # If there are plans
    if($plans.value){
        # For each plan, get details and output to console
        foreach ($plan in $plans.value) {
            # Fetch the details
            # $planDetails = Invoke-MgGraphRequest -Method GET ("https://graph.microsoft.com/v1.0/planner/plans/" + $plan.id + "/details")

            # Fetch last activity from tasks
            $tasks = Invoke-MgGraphRequest -Method GET ("https://graph.microsoft.com/v1.0/planner/plans/" + $plan.id + "/tasks")
            $lastActivity = ($tasks.value | Sort-Object -Property dueDateTime -Descending | Select-Object -First 1).dueDateTime

            $result = @{
                Title = $plan.title
                DisplayName = $group.displayName
                LastActivity = $lastActivity

            }            
            $allResults.Add($result) >> null

            # Write details to console
            Write-Host ($result)
        }
    }
}

$allResults | Where-Object {$_ -ne $null} | foreach-object {$_} | Export-Csv -Path .\PlannerStatistics.csv -NoTypeInformation