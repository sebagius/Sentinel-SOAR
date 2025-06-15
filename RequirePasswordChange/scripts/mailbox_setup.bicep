import {features, playbooks} from '../configuration.bicep'

param identityId string

resource exchangeDeploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'exchangeDeploymentScript'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type:'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '10.0'
    #disable-next-line prefer-interpolation // as the whole script contains curly braces format function does not work on the whole script
    scriptContent: concat(format('''
$mailboxAddress = '{0}'
$mailboxDisplayName = '{1}'
$securityGroupAlias = '{2}'
$securityGroupName = '{3}'
$serviceprincipalAppId = (Get-AzADServicePrincipal -Filter "displayName eq '{4}'").AppId
''', features.email.senderAddress, features.email.senderDisplayName, features.email.securityGroupAlias, features.email.securityGroupName, playbooks.backgroundService.name),
'''
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
        Disconnect-ExchangeOnline
        Exit-PSSession
    }
}

$res = Add-DistributionGroupMember -Identity $securitydg.Alias -Member $mailboxAddress -ErrorAction SilentlyContinue
if($null -eq $res) {
    Write-Host "Failed to add distribution group member"
}

$res = New-ApplicationAccessPolicy -AppId $serviceprincipalAppId -PolicyScopeGroupId $securitydg.Alias -AccessRight RestrictAccess -Description "Allows the app to use a shared mailbox to send emails."
if($null -eq $res) {
    Write-Host "Failed to assign access policy - beware if mail privileges was granted the service principal can send on behalf of anyone!"
}

Test-ApplicationAccessPolicy -Identity $mailboxAddress -AppId $serviceprincipalAppId
Test-ApplicationAccessPolicy -Identity 'postmaster' -AppId $serviceprincipalAppId
Disconnect-Entra
Disconnect-ExchangeOnline
    ''')
    retentionInterval: 'PT1H'
  }
}
