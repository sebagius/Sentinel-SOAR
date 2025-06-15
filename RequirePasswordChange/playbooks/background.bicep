import {playbooks, features} from '../variables.bicep'

var emailTemplate = loadTextContent('../emailTemplates/requireChangeTargetUser.html')
var emailTemplateSubject = 'IT Requires you to change your password'

#disable-next-line BCP081 //Bicep cannot look up the spec as it is not published correctly by Microsoft
resource backgroundServicePlaybook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: playbooks.backgroundService.name
  location: 'australiasoutheast'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    accessControl: {
      actions: {
        allowedCallerIpAddresses: []
      }
      triggers: {
        allowedCallerIpAddresses: []
      }
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        notifier_email: {
          defaultValue: features.email.senderAddress
          type: 'String'
        }
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {
              type: 'object'
              properties: {
                initiator: {
                  type: 'string'
                }
                user_id: {
                  type: 'string'
                }
                mfa: {
                  type: 'boolean'
                }
                wait: {
                  type: 'object'
                  properties: {
                    enabled: {
                      type: 'boolean'
                    }
                    hours: {
                      type: 'integer'
                    }
                  }
                }
              }
            }
          }
          conditions: []
          operationOptions: 'EnableSchemaValidation'
        }
      }
      actions: {
        Verify_user_exists: {
          runAfter: {
            Valid_Caller: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            uri: 'https://graph.microsoft.com/v1.0/users/@{triggerBody()?[\'user_id\']}'
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
                      address: '@{triggerBody()?[\'initiator\']}'
                    }
                  }
                ]
                subject: '${playbooks.backgroundService.friendlyName} failed to run'
                body: {
                  contentType: 'text'
                  content: 'Failed to retrieve user id @{triggerBody()?[\'user_id\']}'
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
        Terminate_Email_Success: {
          runAfter: {
            'Email_-_Verify_user_exists_failure': [
              'Succeeded'
            ]
          }
          type: 'Terminate'
          inputs: {
            runStatus: 'Failed'
            runError: {
              message: 'Failed to retrieve user - email notification sent to initiator'
            }
          }
        }
        Terminate_Email_Failure: {
          runAfter: {
            'Email_-_Verify_user_exists_failure': [
              'Failed'
              'TimedOut'
            ]
          }
          type: 'Terminate'
          inputs: {
            runStatus: 'Failed'
            runError: {
              message: 'Failed to retrieve user - notification failed'
            }
          }
        }
        Condition: {
          actions: {
            MFA_Password_Change: {
              type: 'Http'
              inputs: {
                uri: 'https://graph.microsoft.com/v1.0/users/@{body(\'Validate_response\')?[\'id\']}'
                method: 'PATCH'
                headers: {
                  'Content-Type': 'application/json'
                }
                body: {
                  passwordProfile: {
                    forceChangePasswordNextSignInWithMfa: true
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
            'Email_-_Failure_MFA_Pass_Change': {
              runAfter: {
                MFA_Password_Change: [
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
                          address: '@{triggerBody()?[\'initiator\']}'
                        }
                      }
                    ]
                    subject: '${playbooks.backgroundService.friendlyName} failed to run'
                    body: {
                      contentType: 'text'
                      content: 'Failed to require password change with MFA for @{body(\'Validate_response\')?[\'userPrincipalName\']} - it\'s possible that this user is hybrid and that the mfa change password is not directory synchronised'
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
            Terminate_Email_Success_2: {
              runAfter: {
                'Email_-_Failure_MFA_Pass_Change': [
                  'Succeeded'
                ]
              }
              type: 'Terminate'
              inputs: {
                runStatus: 'Failed'
                runError: {
                  message: 'Failed to require MFA password change - email notification sent to initiator'
                }
              }
            }
            Terminate_Email_Failure_2: {
              runAfter: {
                'Email_-_Failure_MFA_Pass_Change': [
                  'Failed'
                  'TimedOut'
                ]
              }
              type: 'Terminate'
              inputs: {
                runStatus: 'Failed'
                runError: {
                  message: 'Failed to require MFA password change - notification failed'
                }
              }
            }
          }
          runAfter: {
            Wait_for_user: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Password_Change: {
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
                            address: '@{triggerBody()?[\'initiator\']}'
                          }
                        }
                      ]
                      subject: '${playbooks.backgroundService.friendlyName} failed to run'
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
              Terminate_Email_Success_3: {
                runAfter: {
                  'Email_-_Failure_Pass_Change': [
                    'Succeeded'
                  ]
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Failed'
                  runError: {
                    message: 'Failed to require password change - email notification sent to initiator'
                  }
                }
              }
              Terminate_Email_Failure_3: {
                runAfter: {
                  'Email_-_Failure_Pass_Change': [
                    'Failed'
                    'TimedOut'
                  ]
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Failed'
                  runError: {
                    message: 'Failed to require password change - notification failed'
                  }
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'mfa\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
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
                      address: '@{triggerBody()?[\'initiator\']}'
                    }
                  }
                ]
                subject: '${playbooks.backgroundService.friendlyName} succeeded in running'
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
        'Success_Run_-_Email_Failure': {
          runAfter: {
            'Email_-_Success': [
              'Failed'
              'TimedOut'
            ]
          }
          type: 'Terminate'
          inputs: {
            runStatus: 'Succeeded'
          }
        }
        Revoke_Sessions: {
          runAfter: {
            Condition: [
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
                      address: '@{triggerBody()?[\'initiator\']}'
                    }
                  }
                ]
                subject: '${playbooks.backgroundService.friendlyName} partial success in running'
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
        'Partial_Success_Run_-_Email_Failure': {
          runAfter: {
            'Email_-_Revoke_Failure_Password_Success': [
              'Failed'
              'TimedOut'
            ]
          }
          type: 'Terminate'
          inputs: {
            runStatus: 'Failed'
            runError: {
              message: 'Successfully required user to change password but failed to revoke sessions. Email notification failure occurred.'
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
                    subject: emailTemplateSubject
                    body: {
                      contentType: 'html'
                      content: emailTemplate
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
                  count: '@triggerBody()?[\'wait\']?[\'hours\']'
                  unit: 'Hour'
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
              actions: {
                User_changed_password: {
                  type: 'Terminate'
                  inputs: {
                    runStatus: 'Succeeded'
                  }
                }
              }
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
                equals: [
                  '@triggerBody()?[\'wait\']?[\'enabled\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
        }
        Valid_Caller: {
          actions: {
            Response: {
              type: 'Response'
              kind: 'Http'
              inputs: {
                statusCode: 200
              }
              operationOptions: 'Asynchronous'
            }
          }
          runAfter: {}
          else: {
            actions: {
              Terminate: {
                runAfter: {
                  Response_failed: [
                    'Succeeded'
                  ]
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Failed'
                  runError: {
                    code: '401'
                    message: 'Invalid Logic app caller'
                  }
                }
              }
              Response_failed: {
                type: 'Response'
                kind: 'Http'
                inputs: {
                  statusCode: 400
                }
                operationOptions: 'Asynchronous'
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerOutputs()?[\'headers\']?[\'x-ms-workflow-resourcegroup-name\']'
                  '${resourceGroup().name}'
                ]
              }
              {
                equals: [
                  '@triggerOutputs()?[\'headers\']?[\'x-ms-workflow-subscription-id\']'
                  '${subscription().id}'
                ]
              }
            ]
          }
          type: 'If'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {}
      }
    }
  }
}

output backgroundServicePlaybookId string = backgroundServicePlaybook.id
