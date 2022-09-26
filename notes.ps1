$params = @{
 dcs                  = 'Mainframe.chico.usd', 'optimus.chico.usd', 'kickoff.chico.usd'
 ADCred               = $adTasks
 MonthsSinceLastLogon = 18
}
$params
ls -Recurse -Filter *.ps1 | Unblock-File