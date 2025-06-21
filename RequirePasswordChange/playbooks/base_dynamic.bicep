/* Originally developed by Sebastian Agius */
//import { features } from '../configuration.bicep'
import { apiConnection } from '../apiConnections/sentinel.bicep'
//import { changePasswordActions } from './background.bicep' todo

param playbookName string
//param waitTime int
//param waitMeasure string

#disable-next-line BCP081 //Bicep cannot look up the spec as it is not published correctly by Microsoft
resource workflows_baseDynamicPlaybook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: playbookName
  location: resourceGroup().location
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
        sentinelIncident: {
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
        sentinelEntity: {
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
            path: '/entity/@{encodeURIComponent(\'Account\')}'
          }
        }
        http: {
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
        }
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
                      message: '<p class="editor-paragraph">Executing playbook {name}</p>'
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
          actions: {}//changePasswordActions
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
