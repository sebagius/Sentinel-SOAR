/* Originally developed by Sebastian Agius */
import {features} from '../configuration.bicep'

@export()
var apiConnection = {
    id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceGroup().location, 'azuresentinel')
    connectionId: resourceId('Microsoft.Web/connections', 'azuresentinel-${features.identity.name}')
    connectionName: 'azuresentinel-${features.identity.name}'
    connectionProperties: {
      authentication: {
        type: 'ManagedServiceIdentity'
      }
    }
}

resource connections_azuresentinel 'Microsoft.Web/connections@2016-06-01' = {
  name: apiConnection.connectionName
  location: resourceGroup().location
  //kind: 'V1' //removed in 2016 api version but exists in 2015 version
  properties: {
    displayName: apiConnection.connectionName
    customParameterValues: {}
    #disable-next-line BCP037 //This is required for managed identity support
    authenticatedUser: {}
    #disable-next-line BCP037 //This is required for managed identity support
    alternativeParameterValues: {}
    #disable-next-line BCP037 //This is required for managed identity support
    parameterValueType: 'Alternative'
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
