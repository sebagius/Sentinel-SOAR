# Sentinel-SOAR
A Collection of SOAR playbooks and automation rules for Microsoft Sentinel, along with a standalone platform for executing the automations.

## RequirePasswordChange
Forces an Entra ID user to change their password with configurable options including a wait time with email notification to the user and forcing an MFA requirement or not (this is also influenced by conditional access and security defaults)

## Multi-trigger Extension
Currently the Sentinel UI does not show multi-trigger playbooks for execution in different contexts (incident, entity, alert). This is purely a frontend/ui limitation. This extension will ensure that multi-trigger playbooks do pop up and work.