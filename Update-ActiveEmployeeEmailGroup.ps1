<# 
.SYNOPSIS
 Update Active Directory ActiveEmployeeEmail Security Group
.DESCRIPTION
.EXAMPLE
 .\Update-ActiveEmployeeEmail.ps1 -DomainController MyDC.us.org -Credential $adtasksCredObj -MonthsSinceLastLogon 18
.EXAMPLE
 .\Update-ActiveEmployeeEmail.ps1 -DomainController MyDC.us.org -Credential $adtasksCredObj -MonthsSinceLastLogon 18 -Verbose -WhatIf
.INPUTS
.OUTPUTS
.NOTES
 The user account used to build the credential object needs permission to update the Active Directory group.
#>

[cmdletbinding()]
param ( 
 [Parameter(Position = 0, Mandatory = $True)]
 [Alias('DC', 'Server')]
 [string]$DomainController, 
 [Parameter(Position = 1, Mandatory = $True)]
 [Alias('ADCred')]
 [System.Management.Automation.PSCredential]$Credential,
 [int]$MonthsSinceLastLogon,
 [Parameter(Position = 3, Mandatory = $false)]
 [SWITCH]$WhatIf
)

# Imported Functions
. .\lib\Add-Log.ps1

Add-Log info 'Start Domain Controller Session'
$adCmdLets = 'Get-ADUser', 'Get-ADGroup', 'Get-ADGroupMember', 'Add-ADGroupMember', 'Remove-ADGroupMember'
$adSession = New-PSSession -ComputerName $DomainController -Credential $Credential
Import-PSSession -Session $adSession -Module ActiveDirectory -CommandName $adCmdLets -AllowClobber | Out-Null

# Check Group
if ( !(Get-ADGroup -filter { name -eq 'ActiveEmployeeEmail' }) ) {
 Add-Log error "ActiveEmployeeEmail group does not exist. Please create the group in AD and try again."
}
$cutOffdate = (Get-Date).AddMonths(-$MonthsSinceLastLogon)

$aDParams = @{
 Filter     = {
        ( mail -like "*@*" ) -and
        ( employeeID -like "*" ) -and
        ( enabled -eq $True )
 }
 Properties = 'employeeId', 'lastLogonDate', 'Description', 'AccountExpirationDate'
 Searchbase = 'OU=Employees,OU=Users,OU=Domain_Root,DC=chico,DC=usd'
}

# Clear Group
Add-Log query 'Getting current ActiveEmployeeEmail group members'
$groupSams = (Get-ADGroupMember -Identity 'ActiveEmployeeEmail').SamAccountName

Add-Log action 'Clearing ActiveEmployeeEmail group' -WhatIf:$WhatIf
Remove-ADGroupMember 'ActiveEmployeeEmail' $groupSams -Confirm:$false -WhatIf:$WhatIf

Add-Log query 'Getting current, eligible staff members'
$currentStaffSams = (
 Get-Aduser @aDParams | Where-Object {
  (($_.employeeId -match "\d{4,}") -and ($_.lastLogonDate -gt $cutOffdate)) -or
  ($_.Description -like "*Board*Member*") }
).samAccountName
Add-Log info ('Current Staff Count: {0}' -f $currentStaffSams.count)

Add-Log action 'Adding current staff to the ActiveEmployeeEmail group' -WhatIf:$WhatIf
# Add-ADGroupMember -Identity 'ActiveEmployeeEmail' -Members ($missingSams).InputObject -WhatIf:$WhatIf
Add-ADGroupMember -Identity 'ActiveEmployeeEmail' -Members $currentStaffSams -Confirm:$false -WhatIf:$WhatIf

$groupSams = (Get-ADGroupMember -Identity 'ActiveEmployeeEmail').SamAccountName
Add-Log info ('ActiveEmployeeEmail group members: {0}' -f $groupSams.count)

'Tearing down sessions...'
Get-PSSession | Remove-PSSession