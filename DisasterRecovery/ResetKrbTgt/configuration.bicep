@export()
var features = {
  targetResource: {
    subscriptionId: ''
    resourceGroupName: ''
    resource: ''
    type: '' // Hybrid Compute / Compute
  }
  approvalFlow: {
    enabled: false // for future use
    approvers: [
      {userPrincipalName: 'test@example.com', stage: 1}
      {userPrincipalName: 'test2@example.com', stage: 1}
      {userPrincipalName: 'test1@example.com', stage: 2}
      {userPrincipalName: 'test3@example.com', stage: 2}
      {userPrincipalName: 'adminuser@example.com', stage: -1} // Master User - can immediately approve without stage requirements.
    ]
  }
}
