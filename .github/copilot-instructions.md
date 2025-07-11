# Copilot Instructions for NorthernMasterModule

## Project Overview
- This repository is a PowerShell master module for Northern Computer, consolidating SharePoint and Teams automation tasks using PnP.PowerShell, MSGraph, and Exchange.
- Scripts are organized by function: `public/` for user-facing commands, `private/` for helpers, and `classes/` for reusable PowerShell classes.
- The module is designed for ongoing evolution and is used by technical staff for SharePoint/Teams management.

## Architecture & Patterns
- **Entry Points:** Main scripts are in `public/`. These dot-source helpers from `private/` and use classes from `classes/`.
- **Helper Functions:** Place reusable logic in `private/` scripts. Example: `ConnectToSharePointSite.ps1` provides a connection helper for PnP.PowerShell.
- **Classes:** Use the `classes/` directory for PowerShell class definitions to encapsulate business logic or data models.
- **Configuration:** Repository-wide variables (e.g., tenant name) are stored in `tenant.psd1` and loaded via `Import-PowerShellDataFile`.
- **External Dependencies:** Scripts rely on PnP.PowerShell and MSGraph modules. Ensure these are installed and imported as needed.

## Developer Workflows
- **Running Scripts:** Execute scripts from `public/` after dot-sourcing required helpers. Example:
  ```powershell
  . $PSScriptRoot\..\..\private\ConnectToSharePointSite.ps1
  $connection = Connect-ToSharePointSite -SiteUrl $siteUrl
  ```
- **Testing:** Tests are located in `Tests/` and should be run using standard PowerShell testing practices.
- **Debugging:** Use verbose output and `Write-Host` for step-by-step feedback. Scripts prompt for user input where needed.

## Project-Specific Conventions
- **Dot-Sourcing:** Always use dot-sourcing to load helper scripts and classes before use.
- **Pathing:** Use `$PSScriptRoot` for relative paths to ensure scripts work from any location.
- **Content Type Management:** Scripts like `Update-SiteContentTypes.ps1` modernize SharePoint content types by nulling `NewFormClientSideComponentId` and calling `Update()`/`Invoke-PnPQuery`.
- **List Selection:** Scripts prompt users to select lists/content types interactively.

## Integration Points
- **SharePoint:** Connect using PnP.PowerShell with interactive authentication.
- **Teams/Exchange:** Integrate via MSGraph and Exchange modules as needed.

## Examples
- See `public/Update-SiteContentTypes.ps1` for a pattern of interactive list/content type selection and update.
- See `private/ConnectToSharePointSite.ps1` for a reusable connection helper.

## Recommendations for AI Agents
- Follow the directory conventions for helpers, classes, and entry points.
- Always load configuration from `tenant.psd1` for tenant-specific values.
- Use interactive prompts for user-driven workflows.
- Reference existing scripts for patterns before introducing new ones.

---

If any section is unclear or missing, please provide feedback to improve these instructions.
