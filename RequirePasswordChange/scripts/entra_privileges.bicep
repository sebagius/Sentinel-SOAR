resource entraDeploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'entraDeploymentScript'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '10.0'
    scriptContent: '''

    '''
    retentionInterval: 'PT1H'
  }
}
