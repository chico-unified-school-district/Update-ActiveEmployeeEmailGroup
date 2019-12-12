<# 
.SYNOPSIS
 Update Active Directory ActiveEmployeeEmail Security Group
.DESCRIPTION
.EXAMPLE
 .\Update-ActiveEmployeeEmail.ps1 -DomainController MyDC.us.org -Credential $adtasksCredObj
.EXAMPLE
 .\Update-ActiveEmployeeEmail.ps1 -DomainController MyDC.us.org -Credential $adtasksCredObj -Verbose -WhatIf
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
 [Parameter(Position = 3, Mandatory = $false)]
 [SWITCH]$WhatIf
)

# Imported Functions
. .\lib\Add-Log.ps1

Add-Log info 'Start Domain Controller Session'
$adCmdLets = 'Get-ADUser', 'Get-ADGroupMember', 'Add-ADGroupMember'
$adSession = New-PSSession -ComputerName $DomainController -Credential $Credential
Import-PSSession -Session $adSession -Module ActiveDirectory -CommandName $adCmdLets -AllowClobber | Out-Null

# Check Group
if ( !(Get-ADGroup -filter {name -eq 'ActiveEmployeeEmail'}) ) {
    Add-Log error "ActiveEmployeeEmail group does not exist. Please create the group in AD and try again."
}
$cutOffdate = (Get-Date).AddMonths(-6)

$aDParams = @{
 Filter     = {
  ( mail -like "*@*" ) -and
  ( employeeID -like "*" )
 }
 Properties = 'employeeId','lastLogonDate'
 Searchbase = 'OU=Employees,OU=Users,OU=Domain_Root,DC=chico,DC=usd'
}

$staffSams = (Get-Aduser @aDParams | Where-Object { ($_.employeeId -match "\d{4,}") -and ($_.lastLogonDate -gt $cutOffdate) }).samAccountName
$groupSams = (Get-ADGroupMember -Identity 'ActiveEmployeeEmail').SamAccountName

$missingSams = Compare-Object -ReferenceObject $groupSams -DifferenceObject $staffSams | 
Where-Object { $_.SideIndicator -eq '=>' }
if ($missingSams) {
 "Adding missing user objects to ActiveEmployeeEmail group."
 foreach ($user in ($missingSams).InputObject) {
  $user
 }
 Add-ADGroupMember -Identity 'ActiveEmployeeEmail' -Members ($missingSams).InputObject -WhatIf:$WhatIf
}
else { Add-Log info "ActiveEmployeeEmail security group has no missing user objects." }

$groupSams = (Get-ADGroupMember -Identity 'ActiveEmployeeEmail').SamAccountName
Add-Log info ('ActiveEmployeeEmail group members: {0}' -f $groupSams.count) -WhatIf:$WhatIf

'Tearing down sessions...'
Get-PSSession | Remove-PSSession