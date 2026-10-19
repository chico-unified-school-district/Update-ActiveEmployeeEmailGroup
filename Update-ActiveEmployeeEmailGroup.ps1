[cmdletbinding()]
param (
 [Parameter(Mandatory = $True)][PSCredential]$ADCredential,
 [Parameter(Mandatory = $True)][string]$ADGroup,
 [Parameter(Mandatory = $True)][string]$OrgUnit,
 [Parameter(Mandatory = $True)][int]$MonthsSinceLastLogon,
 [Alias('wi')][switch]$WhatIf
)

function Get-EligibleUsers ($ou, [PSCredential]$cred) {
 process {
  $cutOffDate = (Get-Date).AddMonths(-$MonthsSinceLastLogon)
  $filter = "
   mail -like '*' -and
   EmployeeID -like '*' -and
   Enabled -eq 'True'
  "
  $params = @{
   Filter     = $filter
   SearchBase = $ou
   Properties = 'lastLogonDate', 'MemberOf', 'EmployeeId', 'description'
   Credential = $cred
  }
  Get-ADUser @params | Where-Object {
   (($_.employeeId -match '^\d{4,}$') -and ($_.lastLogonDate -gt $cutOffdate)) -or
   ($_.Description -like '*Board*Member*')
  }
 }
}

function Update-GroupMembership ($group, [PSCredential]$cred) {
 begin {
  $removed = 0
  $added = 0
 }
 process {
  if ($_.SideIndicator -eq '=>') {
   $removed ++
   Remove-ADGroupMember -Identity $group -Members $_.SamAccountName -Credential $cred -Confirm:$false -WhatIf:$WhatIf
   return (Write-Host ('{0},Remove,{1},{2}' -f $MyInvocation.MyCommand.Name, $group, $_.SamAccountName) -F DarkYellow)
  }
  elseif ($_.SideIndicator -eq '<=') {
   $added ++
   Add-ADGroupMember -Identity $group -Members $_.SamAccountName -Credential $cred -Confirm:$false -WhatIf:$WhatIf
   Write-Host ('{0},Add,{1},{2}' -f $MyInvocation.MyCommand.Name, $group, $_.SamAccountName) -f Blue
  }
 }
 end {
  Write-Host ('{0},Summary,{1},Added:{2},Removed:{3}' -f $MyInvocation.MyCommand.Name, $group, $added, $removed) -f Green
 }
}

# ================================= main ==================================
Show-BlockInfo start

Import-Module -Name CommonScriptFunctions -Cmdlet Show-BlockInfo, Show-TestRun
$adCmdlets = 'Get-ADUser', 'Get-ADGroupMember', 'Add-ADGroupMember', 'Remove-ADGroupMember'
Import-Module -Name ActiveDirectory -Cmdlet $adCmdlets -WarningAction SilentlyContinue -ErrorAction Stop

Show-BlockInfo main

if ($WhatIf) { Show-TestRun }

$groupUsers = Get-ADGroupMember -Identity $ADGroup -Credential $ADCredential
$eligibleUsers = Get-EligibleUsers -ou $OrgUnit -cred $ADCredential
Compare-Object -ReferenceObject $eligibleUsers -DifferenceObject $groupUsers -Property SamAccountName |
 Update-GroupMembership -group $ADGroup -cred $ADCredential

$groupUsers = Get-ADGroupMember -Identity $ADGroup -Credential $ADCredential
Write-Host ('{0},New group count: {1}' -f $MyInvocation.MyCommand.Name, @($groupUsers).Count) -f Green

if ($WhatIf) { Show-TestRun }
Show-BlockInfo end
