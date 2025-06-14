# RequirePasswordChange
This deployment will allow for the execution of a logic app which will require the user to sign-in again and change their password. It is a requirement to deploy the background logic app which will do all of the heavy lifting. Every other logic app is optional and has various use cases (i.e. Sentinel incident or entity trigger, wait times - sending an email to the user first and waiting 24 hours or 7 days etc). The logic apps are designed typically to work for an organisation which is a Microsoft powerhouse. For full capabilities, Microsoft Sentinel, Microsoft Exchange Online and Microsoft Entra ID is required. Although Exchange Online and Sentinel are optional, features requiring those products can be excluded from deployment.

## Design and Requirements
The following architecture diagram depicts the service at a high level.

![Architecture Diagram](../Image%20Resources/architecture%20diagram.jpg?raw=true)

Additional requirements for the background service managed identity are as following
* Privileges to write to user password profile - Entra role and Graph API access (**Required**)
* Privileges to write to user sign-in session time (to revoke sessions) - Entra role and Graph API access (**Recommended Required**)
* Privileges to send email as an application (**Not Required**)
 * This will be restricted by an Exchange Online security group

Additional privileges for the deploying user identity
* Privileges to deploy resources to the resource group (**Required**)
* Privileges to create service principal app role assignments (**Required**)
* Privileges to assign directory roles to apps (**Required**)
* Privileges to create a mailbox if one is not already created (**Not Required**)
* Privileges to create a security distribution group and add mailboxes to it (**Not Required**)
* Privileges to assign application access policy to app  (**Not Required**)

## Configuration Recommendations
TBD

## Deployment Artifacts
| Name/Resource                                                              | Required           | Type                          | Dependencies |
| -------------------------------------------------------------------------- | ------------------ | ----------------------------- | ------------ |
| [playbooks/background](playbooks/background.bicep)                         | :white_check_mark: | Logic App                     | None         |
| [Background Service](scripts/entra_privileges.bicep) (Identity)            | :white_check_mark: | Entra Service Principal (App) | playbooks/background |
| [apiConnections/sentinel](apiConnections/sentinel.bicep)                   |                    | API Connection                | None         |
| [Shared Mailbox](scripts/mailbox_setup.bicep)                              |                    | Exchange Online Mailbox       | None         |
| Managed Identities (Logic Apps)                                            |                    | Entra Service Principal (App) | every logic app         |
| [playbooks/incident_instantchange](playbooks/incident_instantchange.bicep) |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange |

### WIP
| Name/Resource                    | Required           | Type                          | Dependencies |
| -------------------------------- | ------------------ | ----------------------------- | ------------ |
| Incident-24HPasswordChange       |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange, Shared Mailbox |
| Incident-7DPasswordChange        |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange, Shared Mailbox |
| Entity-ImmediatePasswordChange   |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange |
| Entity-24HPasswordChange         |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange, Shared Mailbox |
| Entity-7DPasswordChange          |                    | Logic App (Sentinel)          | Sentinel API Connection, RequirePasswordChange, Shared Mailbox |
| LeakedCreds24HPwdChange          |                    | Automation Rule (Sentinel)    | Incident-24HPasswordChange |
| LeakedCredsImmediatePwdChange    |                    | Automation Rule (Sentinel)    | Incident-ImmediatePasswordChange |