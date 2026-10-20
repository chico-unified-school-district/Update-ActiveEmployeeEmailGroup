# Update-ActiveEmployeeEmail

 Update Active Directory ActiveEmployeeEmail Security Group

Adds enabled users that have a mail address and an employee ID (and a recent logon, or a
"Board Member" description) to the group, and removes group members that are no longer eligible.

## Requirements

- `ActiveDirectory` module (Get-ADUser, Get-ADGroupMember, Add-ADGroupMember, Remove-ADGroupMember)
- `CommonScriptFunctions` module (Show-BlockInfo, Show-TestRun)

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-ADCredential` | Yes | PSCredential used for all Active Directory cmdlets. |
| `-ADGroup` | Yes | Security group to update. |
| `-OrgUnit` | Yes | Search base (OU) used to find eligible users. |
| `-MonthsSinceLastLogon` | Yes | Users must have logged on within this many months. |
| `-WhatIf` (`-wi`) | No | Show the changes without making them. |

## Example

```powershell
.\Update-ActiveEmployeeEmailGroup.ps1 -ADCredential $cred -ADGroup 'ActiveEmployeeEmail' `
 -OrgUnit 'OU=Users,DC=example,DC=org' -MonthsSinceLastLogon 6 -WhatIf
```