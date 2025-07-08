/* Originally developed by Sebastian Agius */
import {features} from 'configuration.bicep'
import {apiConnection} from 'apiConnections/sentinel.bicep'

module sentinelApi 'apiConnections/sentinel.bicep' = {
  name: apiConnection.connectionName
}

resource playbookIdentityDeployment 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: features.identity.name
  location:resourceGroup().location
}

resource playbookIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(features.identity.sentinelRole)) {
  name:guid(playbookIdentityDeployment.id, features.identity.sentinelRole, resourceGroup().id)
  scope: resourceGroup()
  properties: {
    principalId:playbookIdentityDeployment.properties.principalId
    roleDefinitionId: features.identity.sentinelRole
    principalType: 'ServicePrincipal'
  }
}

module entityPlaybookDeployment 'playbooks/base_dynamic_entity.bicep' = [for playbook in features.playbooks: if(!features.experimental.multitrigger) {
  dependsOn: [sentinelApi]
  name: 'Entity-${playbook.playbookName}'
  params: {
    playbookName: 'Entity-${playbook.playbookName}'
    waitMeasure: playbook.waitMeasure
    waitTime: playbook.waitTime
    notifierEmail: features.email.senderAddress
    alertRecipient: features.email.internalNotifications.recipientAddress
    timeBoundSubject: features.email.endUserNotifications.timeBoundSubject
    timeBoundTemplate: replace(loadTextContent(features.email.endUserNotifications.timeBoundTemplate), '{time}', '${playbook.waitTime} ${playbook.waitMeasure}s')
    //immediateSubject: features.email.endUserNotifications.timeBoundSubject
    //immediateTemplate: loadTextContent(features.email.endUserNotifications.immediateTemplate)
    identityId: playbookIdentityDeployment.id
  }
}]

module incidentPlaybookDeployment 'playbooks/base_dynamic_incident.bicep' = [for playbook in features.playbooks: if(!features.experimental.multitrigger) {
  dependsOn: [sentinelApi]
  name: 'Incident-${playbook.playbookName}'
  params: {
    playbookName: 'Incident-${playbook.playbookName}'
    waitMeasure: playbook.waitMeasure
    waitTime: playbook.waitTime
    notifierEmail: features.email.senderAddress
    alertRecipient: features.email.internalNotifications.recipientAddress
    timeBoundSubject: features.email.endUserNotifications.timeBoundSubject
    timeBoundTemplate: replace(loadTextContent(features.email.endUserNotifications.timeBoundTemplate), '{time}', '${playbook.waitTime} ${playbook.waitMeasure}s')
    //immediateSubject: features.email.endUserNotifications.timeBoundSubject
    //immediateTemplate: loadTextContent(features.email.endUserNotifications.immediateTemplate)
    identityId: playbookIdentityDeployment.id
  }
}]




/* Multitrigger experimental deployment */
module experimentalPlaybookDeployment 'playbooks/base_dynamic.bicep' = [for playbook in features.playbooks: if(features.experimental.multitrigger) {
  dependsOn: [sentinelApi]
  name: playbook.playbookName
  params: {
    playbookName: playbook.playbookName
    waitMeasure: playbook.waitMeasure
    waitTime: playbook.waitTime
    notifierEmail: features.email.senderAddress
    alertRecipient: features.email.internalNotifications.recipientAddress
    timeBoundSubject: features.email.endUserNotifications.timeBoundSubject
    timeBoundTemplate: replace(loadTextContent(features.email.endUserNotifications.timeBoundTemplate), '{time}', '${playbook.waitTime} ${playbook.waitMeasure}s')
    //immediateSubject: features.email.endUserNotifications.timeBoundSubject
    //immediateTemplate: loadTextContent(features.email.endUserNotifications.immediateTemplate)
    identityId: playbookIdentityDeployment.id
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
