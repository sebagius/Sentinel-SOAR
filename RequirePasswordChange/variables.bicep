/*
The following variables are references for project wide settings
*/
@export()
var deploymentSubscription = ''

@export()
var deploymentResourceGroup = ''

@export()
var apiConnection = {
  id: '/subscriptions/${deploymentSubscription}/providers/Microsoft.Web/locations/australiasoutheast/managedApis/azuresentinel'
  connectionId: '/subscriptions/${deploymentSubscription}/resourceGroups/${deploymentResourceGroup}/providers/Microsoft.Web/connections/azuresentinel-${backgroundPlaybookName}'
  connectionName: 'azuresentinel-${backgroundPlaybookName}'
  connectionProperties: {
    authentication: {
      type: 'ManagedServiceIdentity'
    }
  }
}

/*
The following variables are references used for the main playbook which executes the code as well as service principal privileges
*/
@export()
var backgroundPlaybookName = 'RequirePasswordChange'

@export()
var backgroundPlaybookFriendlyName = 'Require Password Change'

@export()
var backgroundPlaybookReference = '/subscriptions/${deploymentSubscription}/resourceGroups/${deploymentResourceGroup}/providers/Microsoft.Logic/workflows/${backgroundPlaybookName}'

/*
The following variables are references used for the sentinel based playbooks
*/
@export()
var incidentInstantPasswordChange = 'RequirePasswordChangeInstant'

/*
The following variables reference email related settings
*/
@export()
var mailboxAddress = 'cybersecurity@example.org'
