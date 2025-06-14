# Required User Administrator, Application Administrator roles to execute
Connect-Entra -Scopes "Application.ReadWrite.All", "User.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.Read.All","RoleManagement.ReadWrite.Directory"

# Allows the Logic App to modify user passwords via the Graph API using application authentication (not delegated access)
$graphapi = Get-EntraServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'" # Retrieve Graph API Service Principal

$passwordWritePerm = $graphapi.AppRoles `
    | Where-Object Value -Like "User-PasswordProfile.ReadWrite.All" `
    | Select-Object -First 1
$revokeSessionPerm = $graphapi.AppRoles `
    | Where-Object Value -Like "User.RevokeSessions.All" `
    | Select-Object -First 1
$mailsendPerm = $graphapi.AppRoles `
    | Where-Object Value -Like "Mail.Send" `
    | Select-Object -First 1
$serviceprincipal = Get-EntraServicePrincipal -Filter "displayName eq 'RequirePasswordChange'"

New-EntraServicePrincipalAppRoleAssignment -Id $passwordWritePerm.Id -ServicePrincipalId $serviceprincipal.Id -PrincipalId $serviceprincipal.Id -ResourceId $graphapi.Id
New-EntraServicePrincipalAppRoleAssignment -Id $revokeSessionPerm.Id -ServicePrincipalId $serviceprincipal.Id -PrincipalId $serviceprincipal.Id -ResourceId $graphapi.Id
New-EntraServicePrincipalAppRoleAssignment -Id $mailsendPerm.Id -ServicePrincipalId $serviceprincipal.Id -PrincipalId $serviceprincipal.Id -ResourceId $graphapi.Id


# Assign the "Privileged Authentication Administrator" Entra ID Built-in role to the Logic App Service Principal (System assigned Managed Identity)
$privauthadmin = Get-EntraDirectoryRoleDefinition -Filter "displayName eq 'Privileged Authentication Administrator'"
New-EntraDirectoryRoleAssignment -RoleDefinitionId $privauthadmin.Id -PrincipalId $serviceprincipal.Id -DirectoryScopeId '/'

Disconnect-Entra


# Create email notification shared mailbox. Exchange Online Administrator privileges required
# This is optional
Connect-ExchangeOnline
$mbox = Get-Mailbox -Identity 'cybersecurity' -ErrorAction SilentlyContinue
if($null -eq $mbox) {
    $mbox = New-Mailbox -Shared -Name "ICT Cyber Security" -DisplayName "ICT Cyber Security" -Alias 'cybersecurity'
}

New-DistributionGroup -Name "Cyber Security Background Email Services" -Alias "cybersecurity_bgservice" -Type security
Add-DistributionGroupMember -Identity "cybersecurity_bgservice" -Member "cybersecurity"
New-ApplicationAccessPolicy -AppId $serviceprincipal.AppId -PolicyScopeGroupId "cybersecurity_bgservice" -AccessRight RestrictAccess -Description "Allows the app to use a shared mailbox to send emails."
Disconnect-ExchangeOnline