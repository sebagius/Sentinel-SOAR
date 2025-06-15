import {deployment,backgroundPlaybookName} from '../variables.bicep'

@export()
var apiConnection = {
    id: '/subscriptions/${deployment.subscriptionId}/providers/Microsoft.Web/locations/australiasoutheast/managedApis/azuresentinel'
    connectionId: '/subscriptions/${deployment.subscriptionId}/resourceGroups/${deployment.resourceGroupName}/providers/Microsoft.Web/connections/azuresentinel-${backgroundPlaybookName}'
    connectionName: 'azuresentinel-${backgroundPlaybookName}'
    connectionProperties: {
      authentication: {
        type: 'ManagedServiceIdentity'
      }
    }
}

resource connections_azuresentinel 'Microsoft.Web/connections@2016-06-01' = {
  name: apiConnection.connectionName
  location: 'australiasoutheast'
  //kind: 'V1' remove in 2016 api version but exists in 2015 version
  properties: {
    displayName: apiConnection.connectionName
    statuses: [
      {
        status: 'Ready'
      }
    ]
    customParameterValues: {}
    createdTime: '2025-06-13T07:21:12.9127029Z'
    changedTime: '2025-06-14T01:27:25.6988525Z'
    api: {
      name: 'azuresentinel'
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/v1.0.1753/1.0.1753.4224/azuresentinel/icon.png'
      id: apiConnection.id
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
