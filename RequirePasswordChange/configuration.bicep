/* Originally developed by Sebastian Agius */
/*
The following variables are configuration options you are required to set
*/
@export()
var features = {
  experimental: {
    multitrigger: false
  }

  identity: {
    name: 'RequirePasswordChange'
    sentinelRole: '/providers/Microsoft.Authorization/roleDefinitions/3e150937-b8fe-4cfb-8069-0eaf05ecd056' // This is Sentinel Responder to add comments to incidents. Leave empty for no assignment
    entraRole: 'Privileged Authentication Administrator' // or Authentication Administrator
  }
  
  scriptDeployment: {
    enabled: false // not implemented yet
    identityName: 'script-deployment-identity'
  }

  email: {
    enabled: true
    senderAddress: 'cybersecurity@example.org'
    senderDisplayName: 'ICT Cyber Security'
    securityGroupAlias: 'cybersecurity_bgservice'
    securityGroupName: 'Cyber Security Background Email Services'
    internalNotifications: {
      //todo
      enabled: false
      recipientAddress: 'cybersecurity@example.org'
      template: 'emailTemplates/statusEmail.html'
    }
    endUserNotifications: {
      timeBoundEnabled: true //todo
      timeBoundTemplate: 'emailTemplates/timeChangeRequired.html'
      timeBoundSubject: 'IT Requires you to change your password'
      immediateEnabled: false //todo
      immediateTemplate: 'emailTemplates/immediateChangeRequired.html' //todo
      immediateSubject: 'IT Required you to change your password' //todo
    }
  }

  playbooks: [
    {
      waitTime: 0 // instant/immediate change
      waitMeasure: 'Hour'
      playbookName: 'RequirePasswordChange-Instant'
    }
    {
      waitTime: 24
      waitMeasure: 'Hour'
      playbookName: 'RequirePasswordChange-24H'
    }
    {
      waitTime: 7
      waitMeasure: 'Day'
      playbookName: 'RequirePasswordChange-7D'
    }
  ]
}
