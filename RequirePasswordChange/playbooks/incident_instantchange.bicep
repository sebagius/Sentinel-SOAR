import {incidentInstantPasswordChange, backgroundPlaybookReference, apiConnection, mailboxAddress} from '../variables.bicep'

#disable-next-line BCP081 //Bicep cannot look up the spec as it is not published correctly by Microsoft
resource workflows_RequirePasswordChangeInstant_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: incidentInstantPasswordChange
  location: 'australiasoutheast'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Microsoft_Sentinel_incident: {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            body: {
              callback_url: '@{listCallbackUrl()}'
            }
            path: '/incident-creation'
          }
        }
      }
      actions: {
        'Entities_-_Get_Accounts': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: '@triggerBody()?[\'object\']?[\'properties\']?[\'relatedEntities\']'
            path: '/entities/account'
          }
        }
        For_each: {
          foreach: '@body(\'Entities_-_Get_Accounts\')?[\'Accounts\']'
          actions: {
            AadUserId_not_exists: {
              actions: {
                RequirePasswordChange: {
                  type: 'Workflow'
                  inputs: {
                    host: {
                      workflow: {
                        id: backgroundPlaybookReference
                      }
                      triggerName: 'When_a_HTTP_request_is_received'
                    }
                    body: {
                      initiator: mailboxAddress
                      user_id: '@concat(item()?[\'Name\'],\'@\',item()?[\'UPNSuffix\'])'
                      mfa: false
                      wait: {
                        enabled: false
                        hours: 0
                      }
                    }
                  }
                }
              }
              else: {
                actions: {
                  'RequirePasswordChange-copy': {
                    type: 'Workflow'
                    inputs: {
                      host: {
                        workflow: {
                          id: backgroundPlaybookReference
                        }
                        triggerName: 'When_a_HTTP_request_is_received'
                      }
                      body: {
                        initiator: mailboxAddress
                        user_id: '@item()?[\'AadUserId\']'
                        mfa: false
                        wait: {
                          enabled: false
                          hours: 0
                        }
                      }
                    }
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@empty(item()?[\'AadUserId\'])'
                      '@true'
                    ]
                  }
                ]
              }
              type: 'If'
            }
          }
          runAfter: {
            'Entities_-_Get_Accounts': [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: apiConnection
        }
      }
    }
  }
}
