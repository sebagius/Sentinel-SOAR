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

## Important: Deployment Scripts
To provide the necessary privileges to the service principal which conducts graph activities a deployment script needs to be executed. One of two options can be used to run the deployment scripts.
1. Not recommended: Run the deployment scripts manually as an authenticated user - these can be found in the [scripts/manual](scripts/manual) directory.
2. Recommended: Deploy a user assigned managed identity to the resource group with the required privileges* for deployment, this script can be found in the [scripts/uami/deploy.ps1](scripts/uami/deploy.ps1) file.

*This managed identity will provide the privileges using PIM if it is available. If it is, during deployment the service principal will request to elevate to the required deployment privileges. If PIM is not available, the privileges will be assigned permanently. If you require a similar PIM functionality without Entra ID P2, you will have to manually remove and assign the privileges at your direction.

Note: PIM is only used for deployment privileges, not for functional privileges. Due to the time-sensitive nature of incident response, it is recommended to keep the privileges enabled 24/7. The background managed identity is only accessible by the logic app function itself, there is no associated password, secret or certificate associated with the identity. 

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

# Feature Status
:white_check_mark: Background Service Playbook
:white_check_mark: Sample 24H Time-bound Playbook
:white_check_mark: Manual Deployment scripts (for mailbox privileges and graph privileges)
:x: Dynamic time-bound/trigger playbook generation
:x: Automatic deployment scripts
:x: PIM for automatic deployment scripts
:x: Sample Automation Rules
:x: Configuration documentation
:x: Rework email system