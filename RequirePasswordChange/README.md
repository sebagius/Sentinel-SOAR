# RequirePasswordChange
This deployment will allow for the execution of a logic app which will require the user to sign-in again and change their password. The logic apps are designed typically to work for an organisation which is a Microsoft powerhouse. For full capabilities, Microsoft Sentinel, Microsoft Exchange Online and Microsoft Entra ID is required. Exchange Online and Sentinel are optional but recommended for full capabilities.

## Design and Requirements
The following architecture diagram depicts the service at a high level.

![Architecture Diagram](../Image%20Resources/architecture%20diagram.jpg?raw=true)

Additional requirements for the playbook managed identity deployment are as following
* Privileges to write to user password profile - Entra role and Graph API access (**Required**)
* Privileges to write to user sign-in session time (to revoke sessions) - Entra role and Graph API access (**Required**)
* Privileges to send email as an application (**Not Required**)
 * This will be restricted by an Exchange Online security group

Additional privileges for the deployment user identity (this is if you plan to continue to deploy the code when updates arrive otherwise these permissions need to be given to the user who will run the deployment scripts manually.)
* Privileges to deploy resources to the resource group (**Required**)
* Privileges to create service principal app role assignments (**Required**)
* Privileges to assign directory roles to apps (**Required**)
* Privileges to create a mailbox if one is not already created (**Not Required**)
* Privileges to create a security distribution group and add mailboxes to it (**Not Required**)
* Privileges to assign application access policy to app  (**Not Required**)

## Important: Deployment Scripts
To provide the necessary privileges to the service principal which conducts graph activities a deployment script needs to be executed. One of two options can be used to run the deployment scripts.
1. Not recommended: Run the deployment scripts manually as an authenticated user - these can be found in the [scripts/manual](scripts/manual) directory. Easy for one time uses.
2. Recommended: Deploy a user assigned managed identity to the resource group with the required privileges* for deployment, this script can be found in the [scripts/deployment-uami/deploy.ps1](scripts/deployment-uami/deploy.ps1) file. Better for continuous deployments.
3. Alternatively - modify the scripts to use your own identity part of your deployment pipeline

*This managed identity will provide the privileges using PIM JIT if it is available (TODO). If it is, during deployment the service principal will request to elevate to the required deployment privileges. If PIM is not available, the privileges will be assigned permanently. If you require a similar PIM functionality without Entra ID P2, you will have to manually remove and assign the privileges at your direction.

Note: PIM JIT is only used for deployment privileges, not for functional privileges. Due to the time-sensitive nature of incident response, it is recommended to keep the privileges enabled 24/7. The background managed identity is only accessible by the logic app function itself, there is no associated password, secret or certificate associated with the identity. 

## Configuration Recommendations
TBD

## Deployment Artifacts
| Name/Resource                                                              | Required           | Type                          | Dependencies |
| -------------------------------------------------------------------------- | ------------------ | ----------------------------- | ------------ |
| [playbooks/base_dynamic](playbooks/base_dynamic.bicep)                     | :white_check_mark: | Logic App                     | None         |
| [UAMI for Playbooks](main.bicep)                                           | :white_check_mark: | Entra Service Principal (App) | playbooks/base_dynamic |
| [apiConnections/sentinel](apiConnections/sentinel.bicep)                   |                    | API Connection                | None         |
| [Shared Mailbox](scripts/mailbox_setup.bicep)                              |                    | Exchange Online Mailbox       | None         |
| [UAMI for Deployment](scripts/deployment-uami/deploy.ps1)                  |                    | Entra Service Principal (App) | None         |

# Feature Status

:white_check_mark: Manual Deployment scripts (for mailbox privileges and graph privileges)

:white_check_mark: Dynamic time-bound/trigger playbook generation

:white_check_mark: Migrate from Managed Identity -> User Assigned Managed Identity (for playbooks)

:x: Automatic deployment scripts (for deployment user assigned managed identity)

:x: PIM for automatic deployment scripts

:x: Sample Automation Rules

:x: Configuration documentation