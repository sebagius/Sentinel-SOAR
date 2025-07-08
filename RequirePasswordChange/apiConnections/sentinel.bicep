/* Originally developed by Sebastian Agius */
import {features} from '../configuration.bicep'

@export()
func getApiConnect(identityId string) object => {
    id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceGroup().location, 'azuresentinel')
    connectionId: resourceId('Microsoft.Web/connections', 'azuresentinel-${features.identity.name}')
    connectionName: 'azuresentinel-${features.identity.name}'
    connectionProperties: {
      authentication: {
        type: 'ManagedServiceIdentity'
        identity: identityId
      }
    }
}

resource connections_azuresentinel 'Microsoft.Web/connections@2016-06-01' = {
  name: getApiConnect('').connectionName
  location: resourceGroup().location
#disable-next-line BCP187
  kind: 'V1' // not part of spec but part of deployed resource
  properties: {
    displayName: getApiConnect('').connectionName
    customParameterValues: {}
    #disable-next-line BCP037 //This is required for managed identity support
    authenticatedUser: {}
    #disable-next-line BCP037 //This is required for managed identity support
    alternativeParameterValues: {}
    #disable-next-line BCP037 //This is required for managed identity support
    parameterValueType: 'Alternative'
    api: {
#disable-next-line BCP037
      name: 'azuresentinel'
      displayName: 'Microsoft Sentinel'
      description: 'Cloud-native SIEM with a built-in AI so you can focus on what matters most'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/v1.0.1753/1.0.1753.4224/azuresentinel/icon.png'
      id: getApiConnect('').id
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}
