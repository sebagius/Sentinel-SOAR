# Originally developed by Sebastian Agius #
function New-EntraMultipleSPAppRoleAssignment {
    param([string]$ServicePrincipalName, [string]$ResourceId, [string[]]$Perms)

    $targetResource = Get-EntraServicePrincipal -Filter "AppId eq '$ResourceId'"
    $targetPrincipal = Get-EntraServicePrincipal -Filter "displayName eq '$ServicePrincipalName'"

    foreach($permName in $Perms) {
        $perm = $targetResource.AppRoles | Where-Object Value -eq $permName | Select-Object -First 1
        New-EntraServicePrincipalAppRoleAssignment -Id $perm.Id -ServicePrincipalId $targetPrincipal.Id -PrincipalId $targetPrincipal.Id -ResourceId $targetResource.Id
    }

    return $targetPrincipal
}

$servicePrincipalName = 'RequirePasswordChange' # If deploying manually, ensure this reflects #features.identity.name
$privilegedRole = 'Privileged Authentication Administrator' # If deploying manually, ensure this reflects features.identity.role

# Required User Administrator, Application Administrator roles to execute
Connect-Entra -Scopes "Application.ReadWrite.All", "User.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.Read.All","RoleManagement.ReadWrite.Directory"

$serviceprincipal = New-EntraMultipleSPAppRoleAssignment -ServicePrincipalName $servicePrincipalName -ResourceId "00000003-0000-0000-c000-000000000000" -Perms @("User-PasswordProfile.ReadWrite.All", "User.RevokeSessions.All", "User.Read.All")

# Assign the "Privileged Authentication Administrator" Entra ID Built-in role to the Logic App Service Principal (System assigned Managed Identity)
$privauthadmin = Get-EntraDirectoryRoleDefinition -Filter "displayName eq '$privilegedRole'"
New-EntraDirectoryRoleAssignment -RoleDefinitionId $privauthadmin.Id -PrincipalId $serviceprincipal.Id -DirectoryScopeId '/'

Disconnect-Entra