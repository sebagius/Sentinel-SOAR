/* Originally developed by Sebastian Agius */
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
    senderAddress: 'cybersecurity@example.org'
    senderDisplayName: 'ICT Cyber Security'
    securityGroupAlias: 'cybersecurity_bgservice'
    securityGroupName: 'Cyber Security Background Email Services'
    internalNotifications: { //todo
      enabled: false
      recipientAddress: 'cybersecurity@example.org'
      template: 'emailTemplates/statusEmail.html'
    }
    endUserNotifications: {
      timeBoundEnabled: true
      timeBoundTemplate: 'emailTemplates/requireChangeTargetUser.html'
      immediateEnabled: false
      immediateTemplate: 'emailTemplates/immediateChangeRequired.html'
    }
  }
  sentinel: {
    enabled: true
    playbooks: {
      waitTimeChange: [
        {
          amount: 0 // instant/immediate change
          measure: 'hours'
          playbookName: 'RequirePasswordChange-Instant'
        }
        {
          amount: 24
          measure: 'hours'
          playbookName: 'RequirePasswordChange-24H'
        }
        {
          amount: 7
          measure: 'days'
          playbookName: 'RequirePasswordChange-7D'
        }
      ]
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
