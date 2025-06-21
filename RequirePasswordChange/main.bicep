/* Originally developed by Sebastian Agius */
import {features} from 'configuration.bicep'
import {apiConnection} from 'apiConnections/sentinel.bicep'

module sentinelApi 'apiConnections/sentinel.bicep' = {
  name: apiConnection.connectionName
}

module playbookDeployment 'playbooks/base_dynamic.bicep' = [for playbook in features.playbooks: {
  dependsOn: [sentinelApi]
  name: playbook.playbookName
  params: {
    playbookName: playbook.playbookName
    waitMeasure: playbook.waitMeasure
    waitTime: playbook.waitTime
    notifierEmail: features.email.senderAddress
    alertRecipient: features.email.internalNotifications.recipientAddress
  }
}]

/*resource deploymentScriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if(features.scriptDeployment.enabled) {
  name: features.scriptDeployment.identityName
  location: resourceGroup().location
}

/*module entraScript 'scripts/entra_privileges.bicep' = if(!features.manualScriptDeployment) {
  name: 'script-deployment-entra'
} not developed yet*/

/*module mailScript 'scripts/mailbox_setup.bicep' = if(features.scriptDeployment.enabled && features.email.enabled) {
  name: 'script-deployment-exchange'
  params: {
    identityId: deploymentScriptIdentity.id
  }
}*/
