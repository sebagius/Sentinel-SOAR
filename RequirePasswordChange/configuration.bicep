/*
The following variables are configuration options you are required to set
*/
@export()
var features = {
  manualScriptDeployment: false // If you would like to run scripts manually outside of the deployment, set this to true
  backgroundService: {
    identity: {
      entraRole: 'Privileged Authentication Administrator' // Recommended: Privileged Authentication Administrator or Authentication Administrator
    }
  }
  email: {
    enabled: true
    statusNotifications: true
    senderAddress: 'cybersecurity@example.org'
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
The following variables are for deployment of playbooks/logic apps
*/
@export()
var playbooks = {
  backgroundService: {
    name: 'RequirePasswordChange'
    friendlyName: 'Require Password Change'
  }
  immediatePasswordChange: {
    name: 'RequirePasswordChangeInstant'
  }
}
