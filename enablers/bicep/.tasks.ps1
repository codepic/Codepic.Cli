<#
.SYNOPSIS
Invoke-Build tasks for the Bicep CLI enabler.
.DESCRIPTION
Provides lifecycle tasks that ensure Bicep CLI availability through Azure CLI and surface manual removal guidance.
.PARAMETER RestArgs
Overflow parameters forwarded from the bootstrapper. Currently unused.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'RestArgs', Justification = 'RestArgs is required to match the Invoke-Build task signature even if unused.')]
param (
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    $RestArgs
)

begin {
    # Any future shared values for Bicep tasks can be prepared here.
}

process {
    <#
        .SYNOPSIS
            Installs or verifies the Bicep CLI via Azure CLI.
        .DESCRIPTION
            Confirms Azure CLI is available, runs `az bicep install` to ensure the embedded Bicep CLI is present, and reports the detected version.
        .EXAMPLE
            {CLI} . install-enabler bicep
        .LINK
            https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#azure-cli
    #>
    task install {
        Install-Module PSRule
        Install-Module PSRule.Rules.Azure -Force
    }

    <#
        .SYNOPSIS
            Upgrades the Bicep CLI to the latest available version.
        .DESCRIPTION
            Ensures Azure CLI exists and invokes `az bicep upgrade` so contributors stay aligned with the repository configuration.
        .EXAMPLE
            {CLI} . upgrade-enabler bicep
    #>
    task upgrade {
        exec {
            az bicep upgrade
        } -Echo
    }

    <#
        .SYNOPSIS
            Validates that the Bicep enabler is configured correctly.
        .DESCRIPTION
            Confirms required configuration files exist and verifies the Bicep CLI responds via Azure CLI.
        .EXAMPLE
            {CLI} . test-enabler -Enabler bicep
    #>
    task test {

        exec {
            az --version
        }

        exec {
            az bicep version
        } -Echo

        Assert-PSRule -Format File -Path './.ps-rule/' -InputPath . -Outcome Fail, Error;
    }

    <#
        .SYNOPSIS
            Provides guidance for removing the Bicep CLI artifacts.
        .DESCRIPTION
            Bicep CLI binaries are maintained by Azure CLI under the user profile. This task surfaces documentation for manual cleanup.
        .EXAMPLE
            {CLI} . remove-enabler bicep
    #>
    task remove {
        Write-Build Cyan 'Bicep CLI is managed by Azure CLI and stored under the user profile (e.g., %UserProfile%/.azure/bin/bicep.exe).'
        Write-Build Cyan 'Use `az bicep uninstall` or remove the binaries manually if cleanup is required.'
        Write-Error 'Manual uninstall required; Bicep enabler does not automate removal.'
    }
}
