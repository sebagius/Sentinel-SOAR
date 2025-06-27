/* Originally developed by Sebastian Agius */
import { apiConnection } from '../apiConnections/sentinel.bicep'

param playbookName string
param waitTime int
param waitMeasure string

param notifierEmail string
param alertRecipient string

param immediateSubject string
param immediateTemplate string
param timeBoundSubject string
param timeBoundTemplate string

param identityId string

resource workflows_baseDynamicPlaybook 'Microsoft.Logic/workflows@2019-05-01' = {
  #disable-next-line BCP187 // not in the latest spec but gets added automatically anyway, decreases deployment what-if output
  kind: 'V1'
  name: playbookName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
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
        notifier_email: {
          defaultValue: notifierEmail
          type: 'String'
        }
        alert_email: {
          defaultValue: alertRecipient
          type: 'String'
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
              callback_url: '@listCallbackUrl()'
            }
            path: '/incident-creation'
          }
        }
        Microsoft_Sentinel_entity: {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            body: {
              callback_url: '@listCallbackUrl()'
            }
            path: '/entity/@{encodeURIComponent(\'Account\')}'
          }
        }
        /*http: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {
              type: 'object'
              properties: {
                users: {
                  type: 'array'
                  items: {
                    type: 'string'
                  }
                }
              }
            }
          }
        }*/
      }
      actions: {
        Trigger_Type: {
          runAfter: {
            Initialise_user_list: [
              'Succeeded'
            ]
          }
          cases: {
            Incident_Type: {
              case: '/incident-creation'
              actions: {
                'Entities_-_Get_Accounts': {
                  runAfter: {
                    'Add_comment_to_incident_(V3)': [
                      'Succeeded'
                      'Failed'
                      'TimedOut'
                    ]
                  }
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
                For_each_incident_account: {
                  foreach: '@body(\'Entities_-_Get_Accounts\')?[\'Accounts\']'
                  actions: {
                    Append_to_array_variable: {
                      type: 'AppendToArrayVariable'
                      inputs: {
                        name: 'user_list'
                        value: '@concat(item()?[\'Name\'],\'@\',item()?[\'UPNSuffix\'])'
                      }
                    }
                  }
                  runAfter: {
                    'Entities_-_Get_Accounts': [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                }
                'Add_comment_to_incident_(V3)': {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      incidentArmId: '@triggerBody()?[\'object\']?[\'id\']'
                      message: '<p class="editor-paragraph">Executing playbook {${playbookName}</p>'
                    }
                    path: '/Incidents/Comment'
                  }
                }
              }
            }
            Entity_Type: {
              case: '/entity/Account'
              actions: {
                Append_sentinel_entity: {
                  type: 'AppendToArrayVariable'
                  inputs: {
                    name: 'user_list'
                    value: '@concat(triggerBody()?[\'Entity\']?[\'properties\']?[\'Name\'], \'@\', triggerBody()?[\'Entity\']?[\'properties\']?[\'UPNSuffix\'])'
                  }
                }
              }
            }
            Http_Type: {
              case: 'POST'
              actions: {
                For_each_http_entity: {
                  foreach: '@triggerBody()?[\'users\']'
                  actions: {
                    Append_all_http_inputs: {
                      type: 'AppendToArrayVariable'
                      inputs: {
                        name: 'user_list'
                        value: '@items(\'For_each_http_entity\')'
                      }
                    }
                  }
                  type: 'Foreach'
                }
              }
            }
          }
          default: {
            actions: {
              Terminate_unknown_trigger: {
                type: 'Terminate'
                inputs: {
                  runStatus: 'Failed'
                  runError: {
                    message: 'Unknown trigger'
                  }
                }
              }
            }
          }
          expression: '@coalesce(trigger().inputs?[\'path\'], coalesce(trigger().inputs?[\'method\'], \'unknown\'))'
          type: 'Switch'
        }
        Initialise_user_list: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'user_list'
                type: 'array'
              }
            ]
          }
        }
        For_each_user: {
          foreach: '@variables(\'user_list\')'
          actions: changePasswordActions
          runAfter: {
            Trigger_Type: [
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

var changePasswordActions = {
  Verify_user_exists: {
    runAfter: {}
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{item()}'
      method: 'GET'
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  Validate_response: {
    runAfter: {
      Verify_user_exists: [
        'Succeeded'
      ]
    }
    type: 'ParseJson'
    inputs: {
      content: '@body(\'Verify_user_exists\')'
      schema: {
        type: 'object'
        properties: {
          userPrincipalName: {
            type: 'string'
          }
          id: {
            type: 'string'
          }
        }
      }
    }
  }
  'Email_-_Verify_user_exists_failure': {
    runAfter: {
      Verify_user_exists: [
        'Failed'
        'TimedOut'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{parameters(\'notifier_email\')}/sendMail'
      method: 'POST'
      headers: {
        'Content-Type': 'application/json'
      }
      body: {
        saveToSentItems: false
        message: {
          toRecipients: [
            {
              emailAddress: {
                address: '@{parameters(\'alert_email\')}'
              }
            }
          ]
          subject: 'Require Password Change failed to run'
          body: {
            contentType: 'text'
            content: 'Failed to retrieve user id @{item()}'
          }
        }
      }
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  'Email_-_Success': {
    runAfter: {
      Revoke_Sessions: [
        'Succeeded'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{parameters(\'notifier_email\')}/sendMail'
      method: 'POST'
      headers: {
        'Content-Type': 'application/json'
      }
      body: {
        saveToSentItems: false
        message: {
          toRecipients: [
            {
              emailAddress: {
                address: '@{parameters(\'alert_email\')}'
              }
            }
          ]
          subject: 'Require Password Change succeeded in running'
          body: {
            contentType: 'text'
            content: 'Successfully required @{body(\'Validate_response\')?[\'userPrincipalName\']} to change password next logon'
          }
        }
      }
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  Revoke_Sessions: {
    runAfter: {
      Password_Change: [
        'Succeeded'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{body(\'Validate_response\')?[\'id\']}/revokeSignInSessions'
      method: 'POST'
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  'Email_-_Revoke_Failure_Password_Success': {
    runAfter: {
      Revoke_Sessions: [
        'Failed'
        'TimedOut'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{parameters(\'notifier_email\')}/sendMail'
      method: 'POST'
      headers: {
        'Content-Type': 'application/json'
      }
      body: {
        saveToSentItems: false
        message: {
          toRecipients: [
            {
              emailAddress: {
                address: '@{parameters(\'alert_email\')}'
              }
            }
          ]
          subject: 'Require Password Change partial success in running'
          body: {
            contentType: 'text'
            content: 'Successfully required @{body(\'Validate_response\')?[\'userPrincipalName\']} to change password next logon - but was unable to revoke sign in sessions. Please do this manually.'
          }
        }
      }
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  Wait_for_user: {
    actions: {
      'Email_-_Target_wait_time': {
        type: 'Http'
        inputs: {
          uri: 'https://graph.microsoft.com/v1.0/users/@{parameters(\'notifier_email\')}/sendMail'
          method: 'POST'
          headers: {
            'Content-Type': 'application/json'
          }
          body: {
            saveToSentItems: false
            message: {
              toRecipients: [
                {
                  emailAddress: {
                    address: '@{body(\'Validate_response\')?[\'userPrincipalName\']}'
                  }
                }
              ]
              subject: timeBoundSubject
              body: {
                contentType: 'html'
                content: timeBoundTemplate
              }
            }
          }
          authentication: {
            type: 'ManagedServiceIdentity'
            audience: 'https://graph.microsoft.com'
          }
        }
        runtimeConfiguration: {
          contentTransfer: {
            transferMode: 'Chunked'
          }
        }
      }
      Wait_time: {
        runAfter: {
          Start_time: [
            'Succeeded'
          ]
        }
        type: 'Wait'
        inputs: {
          interval: {
            count: '@${waitTime}'
            unit: waitMeasure
          }
        }
      }
      Get_user_password_change: {
        runAfter: {
          Wait_time: [
            'Succeeded'
          ]
        }
        type: 'Http'
        inputs: {
          uri: 'https://graph.microsoft.com/v1.0/users/@{body(\'Validate_response\')?[\'id\']}?$select=lastPasswordChangeDateTime'
          method: 'GET'
          authentication: {
            type: 'ManagedServiceIdentity'
            audience: 'https://graph.microsoft.com'
          }
        }
        runtimeConfiguration: {
          contentTransfer: {
            transferMode: 'Chunked'
          }
        }
      }
      Parse_JSON: {
        runAfter: {
          Get_user_password_change: [
            'Succeeded'
          ]
        }
        type: 'ParseJson'
        inputs: {
          content: '@body(\'Get_user_password_change\')'
          schema: {
            type: 'object'
            properties: {
              lastPasswordChangeDateTime: {
                type: 'string'
              }
            }
          }
        }
      }
      Start_time: {
        runAfter: {
          'Email_-_Target_wait_time': [
            'Succeeded'
          ]
        }
        type: 'Expression'
        kind: 'CurrentTime'
        inputs: {}
      }
      Did_change_pwd: {
        actions: {}
        runAfter: {
          Parse_JSON: [
            'Succeeded'
          ]
        }
        else: {
          actions: {}
        }
        expression: {
          and: [
            {
              greaterOrEquals: [
                '@parseDateTime(body(\'Parse_JSON\')?[\'lastPasswordChangeDateTime\'])'
                '@body(\'Start_time\')'
              ]
            }
          ]
        }
        type: 'If'
      }
    }
    runAfter: {
      Validate_response: [
        'Succeeded'
      ]
    }
    else: {
      actions: {}
    }
    expression: {
      and: [
        {
          greater: [
            '@${waitTime}'
            '@0'
          ]
        }
      ]
    }
    type: 'If'
  }
  Password_Change: {
    runAfter: {
      Wait_for_user: [
        'Succeeded'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{body(\'Validate_response\')?[\'id\']}'
      method: 'PATCH'
      headers: {
        'Content-Type': 'application/json'
      }
      body: {
        passwordProfile: {
          forceChangePasswordNextSignIn: true
        }
      }
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
  'Email_-_Failure_Pass_Change': {
    runAfter: {
      Password_Change: [
        'TimedOut'
        'Failed'
      ]
    }
    type: 'Http'
    inputs: {
      uri: 'https://graph.microsoft.com/v1.0/users/@{parameters(\'notifier_email\')}/sendMail'
      method: 'POST'
      headers: {
        'Content-Type': 'application/json'
      }
      body: {
        saveToSentItems: false
        message: {
          toRecipients: [
            {
              emailAddress: {
                address: '@{parameters(\'alert_email\')}'
              }
            }
          ]
          subject: 'Require Password Change failed to run'
          body: {
            contentType: 'text'
            content: 'Failed to require password change for user id @{body(\'Validate_response\')?[\'userPrincipalName\']} - it\'s possible that this user is hybrid and that the change password variable is not directory synchronised'
          }
        }
      }
      authentication: {
        type: 'ManagedServiceIdentity'
        audience: 'https://graph.microsoft.com'
      }
    }
    runtimeConfiguration: {
      contentTransfer: {
        transferMode: 'Chunked'
      }
    }
  }
}
