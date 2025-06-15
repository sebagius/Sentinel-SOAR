import {playbooks, features} from 'configuration.bicep'
import {apiConnection} from 'apiConnections/sentinel.bicep'

module sentinelApi 'apiConnections/sentinel.bicep' = {
  name: apiConnection.connectionName
}

module backgroundService 'playbooks/background.bicep' = {
  name: playbooks.backgroundService.name
}

module immediateChange 'playbooks/incident_instantchange.bicep' = {
  dependsOn: [sentinelApi]
  name: playbooks.immediatePasswordChange.name
  params: {
    backgroundServicePlaybookId: backgroundService.outputs.backgroundServicePlaybookId
  }
}

resource exchangeDeploymentScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if(features.scriptDeployment.enabled && features.email.enabled) {
  name: features.scriptDeployment.identityName
  location: resourceGroup().location
}

/*module entraScript 'scripts/entra_privileges.bicep' = if(!features.manualScriptDeployment) {
  name: 'script-deployment-entra'
} not developed yet*/

module mailScript 'scripts/mailbox_setup.bicep' = if(features.scriptDeployment.enabled && features.email.enabled) {
  name: 'script-deployment-exchange'
  params: {
    identityId: exchangeDeploymentScriptIdentity.id
  }
}
