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

Connect-Entra -Scopes "Application.ReadWrite.All", "User.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.Read.All","RoleManagement.ReadWrite.Directory"
$servicePrincipalName = 'RequirePasswordChange'
$servicePrincipal = New-EntraMultipleSPAppRoleAssignment -ServicePrincipalName $servicePrincipalName -ResourceId "00000003-0000-0000-c000-000000000000" -Perms @("Mail.Send")
$appId = $servicePrincipal.AppId
$spId = $servicePrincipal.Id
Disconnect-Entra

$mailboxAddress = 'cybersecurity'
$mailboxDisplayName = "ICT Cyber Security"

Connect-ExchangeOnline
$mbox = Get-Mailbox -Identity $mailboxAddress -ErrorAction SilentlyContinue
if($null -eq $mbox) {
    $mbox = New-Mailbox -Shared -Name $mailboxDisplayName -DisplayName $mailboxDisplayName -Alias $mailboxAddress

    if($null -eq $mbox) {
        Write-Host "Failed to create mailbox. Quitting"
        Exit-PSSession
    }
}

New-ServicePrincipal -AppId "${appId}" -ObjectId "${spId}" -DisplayName "EOSP-${servicePrincipalName}"
New-ManagementScope -Name "EOMS-${servicePrincipalName}" -RecipientRestrictionFilter "Alias -eq '$mailboxAddress'"
New-ManagementRoleAssignment -Name "EOMRA-${servicePrincipalName}" -Role "Application Mail.Send" -App "${appId}" -CustomResourceScope "EOMS-${servicePrincipalName}"

Test-ServicePrincipalAuthorization -Identity ${appId} -Resource $mailboxAddress
Test-ServicePrincipalAuthorization -Identity ${appId} -Resource "postmaster"

Disconnect-ExchangeOnline