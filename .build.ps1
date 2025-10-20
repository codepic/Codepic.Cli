#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Bootstrapper for build operations.

.DESCRIPTION
    Initializes required PowerShell modules and sets up the environment for deployment tasks.
    This script is designed to work both locally and in Azure DevOps pipelines.

    The script leverages Invoke-Build, a powerful build and test automation tool for PowerShell.
    Invoke-Build simplifies task management by allowing users to define tasks in scripts, execute them incrementally, and even run them in parallel.
    It supports persistent builds that can resume after interruptions, making it ideal for complex build pipelines.
    Additionally, it integrates seamlessly with tools like Visual Studio Code and provides features like task dependency management, task graph visualization, and batch test execution.

.PARAMETER Scope
    Specifies the module scope to load. Use '.' for the root module or provide a module folder name.

.PARAMETER Tasks
    Specifies the build tasks to execute. Build tasks are defined in the .tasks.ps1 file with the task blocks.

.PARAMETER IsDevOpsBuild
    Specifies whether the script is running in Azure DevOps or locally. Default is determined by the TF_BUILD environment variable.

.PARAMETER HERE
    Specifies the location of the current script. Default is the directory of the script being executed.

.PARAMETER RestArgs
    Specifies unbound arguments passed to the .tasks.ps1 file. These are passed to the task files as parameters when dot-sourced.

.EXAMPLE
    ./pipelines/.build.ps1 export-solution dev
    Runs the specified tasks (export-solution) in the dev environment.

.NOTES
    - This script ensures that all prerequisites are met, including the installation and import of required modules like Invoke-Build.
    - It dot-sources any *.tasks.ps1 files it finds, passing along overflow arguments from the $RestArgs parameter.
    - The .tasks.ps1 file inherits all parameters and script & global scoped variables from .build.ps1.
    - The script uses Invoke-Build to manage and execute build tasks, ensuring modularity and reusability.
    - Task files (*.tasks.ps1) are loaded and dot-sourced with provided arguments, making their parameters available in the current scope.
    - Invoke-Build enhances the build process by supporting incremental builds, parallel execution, and task dependency management, making it a robust choice for automating complex workflows.
#>
[CmdletBinding()]
param (
    # The module scope to load ('.' for root or the module folder name)
    [Parameter(Position = 0, Mandatory = $true)]
    [string]
    $Scope,
    # The build tasks to execute
    [Parameter(Position = 1, Mandatory = $true)]
    [string]
    $Tasks,
    # Whether the script is running in Azure DevOps or locally
    [Parameter(Mandatory = $false)]
    [bool]
    $IsDevOpsBuild = [bool]::Parse($Env:TF_BUILD ?? $false),

    # Location of the current script
    [Parameter(Mandatory = $false)]
    $HERE = (Split-Path $MyInvocation.MyCommand.Path),

    # Unbound arguments passed to the .tasks.ps1 file. These are passed to the task files as parameters when dot-sourced.
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]$RestArgs
)

begin {
    # Set error action to stop for all tasks to be executed in the pipeline
    $script:ErrorActionPreference = 'Stop'
    # Ensure strict mode is on for all scripts to enforce best practices and catch common errors
    Set-StrictMode -Version Latest

    if ($env:AGENT_DIAGNOSTIC) {
        # If Azure DevOps Diagnostic Logging is Enabled, set -Verbose to true for all commands
        $PSDefaultParameterValues['*:Verbose'] = $true
    }

    # Output PowerShell version table in verbose mode
    Write-Verbose $($PSVersionTable | Out-String)
}

process {
    # Produce a gate to invoke the .build.ps1 through Invoke-Build
    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {

        # Bootstrap the Invoke-Build module if not already installed
        if (!!($Env:TF_BUILD)) {
            # We are running in Azure DevOps
            if (!(Get-InstalledModule InvokeBuild -ErrorAction SilentlyContinue)) {
                Install-Module InvokeBuild -Force
            }
        }
        else {
            # We are running locally
            if (!(Get-InstalledModule InvokeBuild -ErrorAction SilentlyContinue)) {
                # Aktia workstations install User-Scoped modules in network path
                # So we need to install them for all users
                # Requires admin rights (first run only)
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
                Install-Module InvokeBuild -Scope AllUsers -Force
            }
        }
        # Import the InvokeBuild module, which is used to manage and execute build tasks
        Import-Module InvokeBuild

        # Invoke the build file again using the Invoke-Build module
        # The task to execute is passed via the $Tasks parameter and resolved to the task file later
        Invoke-Build $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
        return
    }

    # Running through Invoke-Build
    # Load and dot-source task files (*.tasks.ps1) located in the current directory and its subdirectories
    # This block ensures that any additional task definitions are sourced with provided arguments
    $taskFiles = @()
    if ($Scope -eq '.') {
        $modulePath = Join-Path -Path $HERE -ChildPath "modules"
        Write-Verbose "Searching for task files in: $modulePath"
        $taskFiles += Get-ChildItem -Path $modulePath -Filter '*.tasks.ps1' -ErrorAction SilentlyContinue -Force # -Force to include hidden files
    }
    else {
        $modulePath = Join-Path -Path $HERE -ChildPath "modules\$($Scope.ToLower())"
        Write-Verbose "Searching for task files in module path: $modulePath"
        $taskFiles += Get-ChildItem -Path $modulePath -Recurse -Filter '*.tasks.ps1' -ErrorAction SilentlyContinue -Force # -Force to include hidden files
    }

    $taskFiles | ForEach-Object {
        Write-Verbose "Loading tasks file: $($_.FullName)"

        # Prepare a hashtable ($splat) to hold arguments for the task file
        $splat = @{}

        # Initialize a variable to track the current key for arguments
        $key = ''

        # Process any arguments not explicitly bound in this .build.ps1
        # These arguments are dot-sourced to the task files as parameters
        if ($RestArgs) {
            $RestArgs | ForEach-Object {
                if ($_.GetType() -ne [string]) {
                    # Handle non-string arguments
                    $splat += @{ $key = $_ }
                }
                elseif ($_.StartsWith('-') -and !$_.StartsWith('--')) {
                    # Handle single-dash keys (e.g., -Key Bar)
                    # Extract the key from the argument
                    $key = $_.TrimStart('-')
                    $key = $_.Substring(1)
                }
                else {
                    # Handle single-dash values (e.g., -Foo Value)
                    $splat += @{ $key = $_ }
                }
            }
        }

        # Dot-source the task file with the prepared arguments
        # This allows the task file to inherit parameters and execute properly
        . $_.FullName @splat
    }

    # The control flow continues here to be handled by Invoke-Build
    # Since we dot-sourced the task files with arguments, they are now available in the current scope with correct parameterization
}

end {

}
