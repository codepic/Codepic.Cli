<#[
.SYNOPSIS
    Helper functions for Codepic CLI baseline tasks.
.DESCRIPTION
    Encapsulates task-specific logic to keep Invoke-Build task definitions concise and approachable for contributors.
#>

function Invoke-AliasSetup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Alias,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProfilePath = $PROFILE.CurrentUserAllHosts
    )

    $relativeBuildScript = './.build.ps1'
    $aliasDefinition = "Set-Alias $Alias `"$relativeBuildScript`""
    $existingAlias = Get-Alias -Name $Alias -ErrorAction SilentlyContinue

    if ($existingAlias -and ($existingAlias.Definition -eq $relativeBuildScript)) {
        Write-Build Gray "Alias '$Alias' already points to $relativeBuildScript. No changes made."
        return
    }

    if ($existingAlias) {
        Write-Warning "Alias '$Alias' is currently defined for '$($existingAlias.Definition)'. Update your profile manually if you want it to point to $relativeBuildScript."
        return
    }

    $profileUpdated = $false

    if (Test-Path $ProfilePath) {
        $profileContent = Get-Content $ProfilePath
        if ($profileContent -notcontains $aliasDefinition) {
            Add-Content -Path $ProfilePath -Value $aliasDefinition
            Write-Build Green "Alias '$Alias' added to your PowerShell profile."
            $profileUpdated = $true
        }
        else {
            Write-Build Gray "Alias '$Alias' already exists in your PowerShell profile."
        }
    }
    else {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
        Add-Content -Path $ProfilePath -Value $aliasDefinition
        Write-Build Green "PowerShell profile created and alias '$Alias' added."
        $profileUpdated = $true
    }

    if ($profileUpdated) {
        try {
            . $ProfilePath
            Write-Build Green "Profile reloaded so alias '$Alias' is available in the current session."
        }
        catch {
            Write-Warning "Alias added, but reloading the profile failed: $_"
        }
    }
}
