/*
The following variables are for the deployment target
*/
@export()
var deployment = {
  subscriptionId: ''
  resourceGroupName: ''
}

/*
The following variables are configuration options you are required to set
*/
@export()
var features = {
  email: {
    enabled: true
    statusNotifications: true
  }
  sentinel: {
    enabled: true
    incidentPlaybooks: {
      immediateChange: true
      waitTimeChange: [
        {
          amount: 24
          measure: 'hours'
        }
        {
          amount: 7
          measure: 'days'
        }
      ]
    }
    entityPlaybooks: {
      immediateChange: true
      waitTimeChange: []
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
var backgroundPlaybookReference = '/subscriptions/${deployment.subscriptionId}/resourceGroups/${deployment.resourceGroupName}/providers/Microsoft.Logic/workflows/${backgroundPlaybookName}'

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
