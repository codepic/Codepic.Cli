<#
.SYNOPSIS
    Adds or updates the CLI alias in the user's PowerShell profile.
.DESCRIPTION
    Ensures the requested alias points to `./.build.ps1`, writing it to the provided profile path when necessary and reloading the profile.
.PARAMETER Alias
    The alias name that should invoke the repository bootstrapper.
.PARAMETER ProfilePath
    Optional override for the PowerShell profile file to update; defaults to the current user, all hosts profile.
.EXAMPLE
    Invoke-AliasSetup -Alias codepic
    Adds the codepic alias to the default profile and reloads it in the current session.
.EXAMPLE
    Invoke-AliasSetup -Alias codepic -ProfilePath $PROFILE.CurrentUserCurrentHost
    Updates only the current host's profile file with the alias definition.
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

    begin {
        $relativeBuildScript = './.build.ps1'
        $aliasDefinition = "Set-Alias $Alias `"$relativeBuildScript`""
        $existingAlias = !!(Get-Alias -Name $Alias -ErrorAction SilentlyContinue)
    }

    process {
        if ($existingAlias -and ($existingAlias.Definition -eq $relativeBuildScript)) {
            Write-Build Gray "Alias '$Alias' already points to $relativeBuildScript. No changes made."
            return
        }

        if ($existingAlias) {
            Write-Warning "Alias '$Alias' is currently defined for '$($existingAlias.Definition)'. Update your profile manually if you want it to point to $relativeBuildScript."
            return
        }

        if (Test-Path $ProfilePath) {
            $profileContent = Get-Content $ProfilePath
            if ($profileContent -notcontains $aliasDefinition) {
                Add-Content -Path $ProfilePath -Value $aliasDefinition
                Write-Build Green "Alias '$Alias' added to your PowerShell profile."
            }
            else {
                Write-Build Gray "Alias '$Alias' already exists in your PowerShell profile."
            }
        }
        else {
            New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
            Add-Content -Path $ProfilePath -Value $aliasDefinition
            Write-Build Green "PowerShell profile created and alias '$Alias' added."
        }
    }

    end {
        # Dot-source the profile to make the alias available in the current session
        . $ProfilePath
    }
}

<#
.SYNOPSIS
    Ensures a directory exists by creating it when missing.
.DESCRIPTION
    Tests for the presence of the supplied path and creates the directory when it does not already exist, leaving existing content untouched. Supports `-WhatIf` / `-Confirm` for safety.
.PARAMETER Path
    The directory path to validate or create.
.EXAMPLE
    Ensure-Directory -Path './enablers/azcli'
    Creates the azcli enabler folder if it does not already exist.
#>
function Ensure-Directory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Ensure-* aligns with CLI opinionated style.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-not (Test-Path $Path -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($Path, 'Create directory')) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
}

<#
.SYNOPSIS
    Creates a uniquely named temporary directory.
.DESCRIPTION
    Generates a new directory under the specified parent path (defaulting to the operating system temporary folder) and returns its absolute path for downstream use.
.PARAMETER Prefix
    Optional name prefix prepended to the generated directory identifier to aid troubleshooting. Defaults to 'codepic'.
.PARAMETER ParentPath
    The parent directory that will receive the temporary directory. Defaults to the system temporary location.
.EXAMPLE
    $temp = New-TemporaryDirectory
    Creates a temporary directory under the system temp path and stores the path in $temp.
.EXAMPLE
    $temp = New-TemporaryDirectory -Prefix 'codepic-clone'
    Creates a temporary directory prefixed with codepic-clone under the system temp path.
#>
function New-TemporaryDirectory {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $Prefix,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParentPath = [IO.Path]::GetTempPath()
    )

    if (-not (Test-Path $ParentPath -PathType Container)) {
        throw "Parent path '$ParentPath' does not exist or is not a directory."
    }

    do {
        $guidSegment = [Guid]::NewGuid().Guid

        $directoryName = if ([string]::IsNullOrWhiteSpace($Prefix)) {
            $guidSegment
        }
        else {
            "$Prefix-$guidSegment"
        }

        $tempDirectory = Join-Path $ParentPath $directoryName
    } while (Test-Path $tempDirectory)

    if (-not $PSCmdlet.ShouldProcess($tempDirectory, 'Create temporary directory')) {
        return
    }

    New-Item -ItemType Directory -Path $tempDirectory | Out-Null

    return $tempDirectory
}

<#
.SYNOPSIS
    Removes a file system path when present.
.DESCRIPTION
    Deletes the supplied directory or file recursively, ignoring requests for paths that do not exist. Supports `-WhatIf` / `-Confirm` for safety.
.PARAMETER LiteralPath
    The file or directory path that should be removed.
.EXAMPLE
    Remove-PathItem -LiteralPath './enablers/azcli/.install'
    Cleans up the azcli enabler install directory when it exists.
#>
function Remove-PathItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath
    )

    if (Test-Path $LiteralPath) {
        if ($PSCmdlet.ShouldProcess($LiteralPath, 'Remove item recursively')) {
            Remove-Item -LiteralPath $LiteralPath -Force -Recurse
        }
    }
}

<#
.SYNOPSIS
    Executes a lifecycle task exposed by an enabler.
.DESCRIPTION
    Invokes the specified Invoke-Build task from an enabler's task file when present, otherwise logs that the task was skipped.
.PARAMETER TaskPath
    Full path to the enabler's `.tasks.ps1` file.
.PARAMETER TaskName
    Name of the Invoke-Build task to execute inside the enabler task file.
.EXAMPLE
    Invoke-EnablerTask -TaskPath './enablers/azcli/.tasks.ps1' -TaskName 'enabler:install'
    Runs the azcli enabler install routine if the task file exists.
#>
function Invoke-EnablerTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TaskName
    )

    if (Test-Path $TaskPath -PathType Leaf) {
        Invoke-Build $TaskName -File $TaskPath
    }
    else {
        Write-Build Cyan "Skipped enabler task '$TaskName'; task file not found at $TaskPath."
    }
}

<#
    .SYNOPSIS
        Guards against null or empty input objects.
    .DESCRIPTION
        Validates that the provided input object is neither null nor empty. If the check fails, an error is written with the supplied message.
    .PARAMETER InputObject
        The object to validate.
    .PARAMETER Message
                  [AllowEmptyString()]
                  [string]
                  $Prefix = 'codepic',
#>
function Guard-NotNullOrEmpty {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Common guard function; verb usage acceptable here.')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$InputObject,
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    process {
        if (-not $InputObject) {
            Write-Error $Message
        }
        # Pass the value along if valid
        $InputObject
    }
}
