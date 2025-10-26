<#
.SYNOPSIS
Invoke-Build tasks for the Azure CLI enabler.
.DESCRIPTION
Provides lifecycle tasks that verify Azure CLI availability, trigger upgrades, and document manual removal expectations.
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
    $TEMP = [System.IO.Path]::GetTempPath()
    $archiveFile = (Join-Path $TEMP ([guid]::NewGuid().ToString())) + '.zip'
}

process {
    <#
        .SYNOPSIS
            Ensures the Azure CLI is available and records the detected version.
        .DESCRIPTION
            Verifies that the `az` command is accessible. If it is missing, the task fails with remediation guidance so operators install Azure CLI before continuing.
        .EXAMPLE
            codepic . install-enabler azcli
        .LINK
            https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
    #>
    task install {
        if (!(Get-Command -Name az -ErrorAction Ignore)) {
            Write-Build Cyan 'Azure CLI was not detected on this machine.'
            Write-Error 'Install Azure CLI (https://learn.microsoft.com/cli/azure/install-azure-cli) and re-run the enabler install.'
        }

        # Install Latest Version of Azure CLI using `Zip Package` method from Microsoft Docs below.
        # https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&pivots=zip#install-or-update

        # Invoke-WebRequest `
        #     -Uri 'https://aka.ms/installazurecliwindowszipx64' `
        #     -OutFile $archiveFile `
        #     -UseBasicParsing

        # The extracted files need to be stored under the enabler's ./bin directory so the bootstrapper can locate them and
        # add them to the PATH for the current session.
        Expand-Archive `
            -Path $archiveFile `
            -DestinationPath bin `
            -Force

        # Read the enabler.manifest.json to get the binary.paths.windows location for verification.
        exec {
            ./bin/az.cmd version
        } -Echo

        Write-Build Green "Azure CLI enabler verified: $(./bin/az.cmd version --query 'azure-cli' --output tsv 2>$null)"
    }

    <#
        .SYNOPSIS
            Upgrades the Azure CLI to the latest available version.
        .DESCRIPTION
            Invokes `az upgrade --yes` when Azure CLI is present. Useful for keeping developer workstations aligned with minimum compatibility requirements declared in the manifest.
        .EXAMPLE
            codepic . upgrade-enabler azcli
    #>
    task upgrade {
        if (!(Get-Command -Name az -ErrorAction Ignore)) {
            Write-Build Cyan 'Azure CLI is not installed, skipping upgrade.'
            Write-Error 'Install Azure CLI before attempting to upgrade it.'
        }

        exec {
            az upgrade --yes
        } -Echo
    }

    <#
        .SYNOPSIS
            Provides guidance for removing Azure CLI from the current machine.
        .DESCRIPTION
            Azure CLI removal steps vary by platform. This task surfaces a hyperlink to official documentation and throws so automation can detect that manual intervention is required.
        .EXAMPLE
            codepic . remove-enabler azcli
    #>
    task remove {
        Write-Build Cyan 'Follow the official instructions to remove Azure CLI: https://learn.microsoft.com/cli/azure/uninstall-azure-cli'
        Write-Error 'Manual uninstall required; Azure CLI enabler does not automate removal.'
    }
}
