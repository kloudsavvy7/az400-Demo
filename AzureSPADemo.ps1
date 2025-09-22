
    $Username = "3a9e9b00-fdab-49a7-b418-c6ae098ff160"
    $plianPassword = '~VG8Q~fUnTdfAmnF.Y~p0yLjo1C1jicvjx7nbax3'
    $SecurePassword = ConvertTo-SecureString -String $plianPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)


Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant '094c4f1d-3a4d-4cba-a940-ed572636e781'

Get-AzResource | select Name