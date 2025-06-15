import {playbooks} from 'variables.bicep'
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
