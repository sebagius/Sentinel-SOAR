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
$serviceprincipalAppId = $servicePrincipal.AppId
Disconnect-Entra

$mailboxAddress = 'cybersecurity'
$mailboxDisplayName = "ICT Cyber Security"
$securityGroupAlias = 'cybersecurity_bgservice'
$securityGroupName = "Cyber Security Background Email Services"

Connect-ExchangeOnline
$mbox = Get-Mailbox -Identity $mailboxAddress -ErrorAction SilentlyContinue
if($null -eq $mbox) {
    $mbox = New-Mailbox -Shared -Name $mailboxDisplayName -DisplayName $mailboxDisplayName -Alias $mailboxAddress

    if($null -eq $mbox) {
        Write-Host "Failed to create mailbox. Quitting"
        Exit-PSSession
    }
}

$securitydg = Get-DistributionGroup -Identity $securityGroupAlias -ErrorAction SilentlyContinue

if($null -eq $securitydg) {
    $securitydg = New-DistributionGroup -Name $securityGroupName -Alias $securityGroupAlias -Type security -ErrorAction SilentlyContinue

    if($null -eq $securitydg) {
        Write-Host "Failed to create distribution group. Quitting"
        Exit-PSSession
    }
}

$res = Add-DistributionGroupMember -Identity $securitydg.Alias -Member $mailboxAddress -ErrorAction SilentlyContinue
if($null -eq $res) { # todo, result is null even if success
    Write-Host "Failed to add distribution group member"
}

$res = New-ApplicationAccessPolicy -AppId $serviceprincipalAppId -PolicyScopeGroupId $securitydg.Alias -AccessRight RestrictAccess -Description "Allows the app to use a shared mailbox to send emails."
if($null -eq $res) {
    Write-Host "Failed to assign access policy - beware if mail privileges was granted the service principal can send on behalf of anyone!"
}

Test-ApplicationAccessPolicy -Identity $mailboxAddress -AppId $serviceprincipalAppId
Test-ApplicationAccessPolicy -Identity 'postmaster' -AppId $serviceprincipalAppId
Disconnect-ExchangeOnline