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

module entraScript 'scripts/entra_privileges.bicep' = if(!features.manualScriptDeployment) {
  name: 'script-deployment-entra'
}

module mailScript 'scripts/mailbox_setup.bicep' = if(!features.manualScriptDeployment && features.email.enabled) {
  name: 'script-deployment-exchange'
}
