# Chromium/Edge Multitrigger Extension
There currently exists two bugs in the Sentinel frontend
* If a playbook/logic app has multiple Sentinel triggers, only the first defined one works consistently
* If you rename the trigger **display name** it will not be recognised by the frontend

This extension aims to resolve these two bugs with the following workaround
* Modifying the request response to duplicate a multitrigger playbook into multiple single trigger playbooks for the frontend
* Modify the request response to rename any modified sentinel trigger display names to the recognised format