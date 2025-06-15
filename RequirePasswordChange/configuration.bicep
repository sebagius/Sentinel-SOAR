/*
The following variables are configuration options you are required to set
*/
@export()
var features = {
  scriptDeployment: {
    enabled: true
    identityName: 'script-deployment-identity'
  }
  backgroundService: {
    identity: {
      entraRole: 'Privileged Authentication Administrator' // Recommended: Privileged Authentication Administrator or Authentication Administrator
    }
  }
  email: {
    enabled: true
    statusNotifications: true
    senderAddress: 'cybersecurity@example.org'
    senderDisplayName: 'ICT Cyber Security'
    securityGroupAlias: 'cybersecurity_bgservice'
    securityGroupName: 'Cyber Security Background Email Services'
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
