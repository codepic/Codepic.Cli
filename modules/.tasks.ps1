<#
.SYNOPSIS
    Baseline Codepic CLI module tasks.
.DESCRIPTION
    Ships with the CLI to provide reusable automation tasks and setup helpers (like alias creation) that future modules can extend.
.PARAMETER Alias
    The alias name registered for `.build.ps1` to enable shorthand task invocation (defaults to `cc`; swap in your preferred alias).
.PARAMETER Module
    The module name supplied by the caller when tasks require module-specific context (for example, packing a module).
.PARAMETER Git
    The Git repository URL used when cloning a module into the workspace.
.PARAMETER Version
    The module version used when operations need to target a specific packaged artifact (for example, unpacking).
.PARAMETER Enabler
    The enabler name supplied by the caller when tasks require enabler-specific context (for example, installation).
.PARAMETER RestArgs
    Overflow arguments forwarded from `.build.ps1`; ensures splatted parameters bind consistently across task files.
.NOTES
    Invoke tasks via `.build.ps1` or the registered alias once created.
.EXAMPLE
    # Run the init task via the bootstrapper
    ./.build.ps1 init -Alias {CLI}

.EXAMPLE
    # After running init at least once, invoke tasks through the alias
    {CLI} init

.EXAMPLE
    # Run lint checks with the repository's analyzer settings
    {CLI} lint

.EXAMPLE
    # Attempt automatic fixes for analyzer findings
    {CLI} lint-fix
.EXAMPLE
    # Package a module artifact using its manifest
    {CLI} . pack-module -Module sample

.EXAMPLE
    # Restore module files from the packaged artifact
    {CLI} . unpack-module -Module sample -Version 0.1.0

.EXAMPLE
    # Clone a module from a Git repository and place it in the workspace
    {CLI} . clone-module -Module sample -Version 0.1.1 -Git https://github.com/codepic/Codepic.Cli.Sample.git

.EXAMPLE
    # Update a module to a newer version using its manifest source metadata
    {CLI} . update-module -Module sample -Version 0.1.2

.EXAMPLE
    # Remove module files according to the manifest definitions
    {CLI} . remove-module -Module sample

.EXAMPLE
    # Install an enabler from a Git repository and execute its setup task
    {CLI} . install-enabler -Enabler azcli -Version 0.1.0 -Git https://github.com/codepic/Codepic.Cli.Enabler.AzCli.git

.EXAMPLE
    # Update an enabler using its tracked source repository
    {CLI} . upgrade-enabler -Enabler azcli -Version 0.1.1

.EXAMPLE
    # Remove an enabler and clean up its tracked files
    {CLI} . remove-enabler -Enabler azcli
#>
[CmdletBinding()]
param (
    # Alias for CLI calls
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Alias = 'cc',

    # Module identifier consumed by packaging-related tasks
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Module,

    # Git repository URL for module-cloning scenarios
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Git,

    # Version identifier used by packaging tasks when required
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Version,

    # Enabler identifier consumed by enabler lifecycle tasks
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [LowerCase]
    $Enabler,

    # Overflow arguments passed through from .build.ps1
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    $RestArgs
)

begin {
    . ./modules/.tasks.functions.ps1

    # Analyzer settings consumed by lint-oriented tasks; keep relative to repo root for Invoke-Build context.
    $LintTasksAnalyzerSettingsPath = './PSScriptAnalyzerSettings.psd1'

    # Paths consumed by module packaging tasks to assemble, extract, and clean module artifacts.
    $PackRepoRoot = (Resolve-Path '.').ProviderPath
    $PackModulesRoot = Join-Path $PackRepoRoot 'modules'
    $PackDistRoot = Join-Path $PackRepoRoot 'dist'
    $PackEnablersRoot = Join-Path $PackRepoRoot 'enablers'

    # Touch overflow arguments so script analyzer acknowledges the parameter is intentionally unused downstream.
    $null = $RestArgs
}

process {
    <#
        .SYNOPSIS
            Initializes the project by setting up necessary configurations and files.
        .DESCRIPTION
            This task sets up the project environment by creating an alias in the user's PowerShell profile
            that points to the .build.ps1 script located in the project root directory.
        .PARAMETER Alias
            The alias name to be created in the PowerShell profile. This alias will point to the .build.ps1 script.
        .EXAMPLE
            ./.build.ps1 init -Alias {CLI}
    #>
    task init {
        Invoke-AliasSetup -Alias $Alias
    }

    <#
        .SYNOPSIS
            Runs PSScriptAnalyzer across the repository.
        .DESCRIPTION
            Executes Invoke-ScriptAnalyzer with the repository's PSScriptAnalyzerSettings.psd1 to surface
            cross-platform PowerShell 7+ compatibility issues for Windows and Ubuntu environments.
        .EXAMPLE
            {CLI} lint
    #>
    task lint {
        exec {
            Invoke-ScriptAnalyzer -Path '.' `
                -Settings $LintTasksAnalyzerSettingsPath `
                -Recurse
        } -Echo
    }

    <#
        .SYNOPSIS
            Attempts to correct Script Analyzer findings automatically.
        .DESCRIPTION
            Runs Invoke-ScriptAnalyzer with -Fix and then re-runs lint to verify no diagnostics remain.
            Any remaining issues are surfaced for manual remediation.
        .EXAMPLE
            {CLI} lint-fix
    #>
    task lint-fix {
        exec {
            Invoke-ScriptAnalyzer -Path '.' `
                -Settings $LintTasksAnalyzerSettingsPath `
                -Recurse `
                -Severity Information, Warning `
                -Fix `
                -EnableExit
        } -Echo
    }

    <#
        .SYNOPSIS
            Clones a module from a Git repository and installs it into the workspace.
        .DESCRIPTION
            Clones the supplied Git repository to a temporary location, locates a module manifest whose name and version match the supplied parameters, and copies the manifest's include paths into the current repository.
        .PARAMETER Module
            The module name expected inside the remote manifest.
        .PARAMETER Version
            The module version required from the remote manifest.
        .PARAMETER Git
            The Git repository URL to clone.
        .EXAMPLE
            {CLI} . clone-module -Module sample -Version 0.1.1 -Git https://github.com/codepic/Codepic.Cli.Sample.git
    #>
    task clone-module {
        if (-not $Module) {
            Write-Error "Specify -Module when invoking clone-module."
        }

        if (-not $Version) {
            Write-Error "Specify -Version when invoking clone-module."
        }

        if (-not $Git) {
            Write-Error "Specify -Git when invoking clone-module."
        }

        $moduleName = $Module.ToLowerInvariant()
        $moduleRoot = Join-Path $PackModulesRoot $moduleName

        if (Test-Path $moduleRoot -PathType Container) {
            Write-Error "Module directory already exists at $moduleRoot. Remove it before cloning."
        }

        $tempRoot = New-TemporaryDirectory
        $repoClonePath = Join-Path $tempRoot 'repo'

        try {
            $gitRepositoryUrl = $Git
            $gitCloneTarget = $repoClonePath
            $gitCloneBranch = "v$Version"

            exec {
                git clone --quiet --depth 1 --branch $gitCloneBranch --single-branch $gitRepositoryUrl $gitCloneTarget
            } -Echo

            $manifestModuleName = $moduleName
            $manifestVersion = $Version

            $manifestCandidate = Get-ChildItem -Path $repoClonePath -Recurse -Filter 'module.manifest.json' -ErrorAction SilentlyContinue |
            Where-Object {
                try {
                    $candidate = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
                    ($candidate.name -and $candidate.name.ToString().ToLowerInvariant() -eq $manifestModuleName) -and `
                    ($candidate.version -and $candidate.version.ToString() -eq $manifestVersion)
                }
                catch {
                    $false
                }
            } |
            Select-Object -First 1

            if (-not $manifestCandidate) {
                Write-Error "Unable to find a module.manifest.json matching name '$moduleName' and version '$Version' in $Git."
            }

            $manifest = Get-Content -Raw -LiteralPath $manifestCandidate.FullName | ConvertFrom-Json

            foreach ($include in $manifest.include) {
                $sourcePath = Join-Path $repoClonePath $include
                if (-not (Test-Path $sourcePath)) {
                    Write-Error "Clone archive missing expected path '$include'."
                }

                $destinationPath = Join-Path $PackRepoRoot $include
                $destinationDir = Split-Path $destinationPath -Parent
                if ($destinationDir -and -not (Test-Path $destinationDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -Recurse
            }

            Write-Build Green "Cloned module '$moduleName' version $Version from $Git."
        }
        finally {
            if (Test-Path $tempRoot -PathType Container) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
            }
        }
    }

    <#
        .SYNOPSIS
            Updates an installed module to the requested version.
        .DESCRIPTION
            Clones the module's canonical repository (or a supplied Git URL), checks out the specified version tag, removes the installed files, and copies in the new version described by the manifest.
        .PARAMETER Module
            The module name currently installed in the workspace.
        .PARAMETER Version
            The module version to install from the repository.
        .PARAMETER Git
            Optional override for the repository URL when manifest metadata is missing or overridden.
        .EXAMPLE
            {CLI} . update-module -Module sample -Version 0.1.2
    #>
    task update-module {
        if (-not $Module) {
            Write-Error "Specify -Module when invoking update-module."
        }

        if (-not $Version) {
            Write-Error "Specify -Version when invoking update-module."
        }

        $moduleName = $Module.ToLowerInvariant()
        $moduleRoot = Join-Path $PackModulesRoot $moduleName
        $manifestPath = Join-Path $moduleRoot 'module.manifest.json'

        if (-not (Test-Path $manifestPath -PathType Leaf)) {
            Write-Error "Module manifest not found at $manifestPath. Clone or unpack the module before updating."
        }

        $installedManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

        $repositoryUrl = if ($Git) {
            $Git
        }
        elseif ($installedManifest.source -and $installedManifest.source.git) {
            $installedManifest.source.git
        }
        else {
            Write-Error "Specify -Git or ensure manifest.source.git is defined for module '$moduleName' before running update-module."
        }

        $tagPrefix = 'v'
        if ($installedManifest.source -and $installedManifest.source.PSObject.Properties['tagPrefix']) {
            $tagPrefix = $installedManifest.source.tagPrefix
            if ($null -eq $tagPrefix) {
                $tagPrefix = ''
            }
        }

        if ([string]::IsNullOrWhiteSpace($tagPrefix)) {
            $gitTag = $Version
        }
        else {
            $gitTag = "$tagPrefix$Version"
        }

        $tempRoot = New-TemporaryDirectory
        $repoClonePath = Join-Path $tempRoot 'repo'

        try {
            $gitRepositoryUrl = $repositoryUrl
            $gitCloneTarget = $repoClonePath
            $gitCloneBranch = $gitTag

            exec {
                git clone --quiet --depth 1 --branch $gitCloneBranch --single-branch $gitRepositoryUrl $gitCloneTarget
            } -Echo

            $manifestModuleName = $moduleName
            $manifestVersion = $Version

            $manifestCandidate = Get-ChildItem -Path $repoClonePath -Recurse -Filter 'module.manifest.json' -ErrorAction SilentlyContinue |
            Where-Object {
                try {
                    $candidate = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
                    ($candidate.name -and $candidate.name.ToString().ToLowerInvariant() -eq $manifestModuleName) -and `
                    ($candidate.version -and $candidate.version.ToString() -eq $manifestVersion)
                }
                catch {
                    $false
                }
            } |
            Select-Object -First 1

            if (-not $manifestCandidate) {
                Write-Error "Unable to find a module.manifest.json matching name '$moduleName' and version '$Version' in $repositoryUrl."
            }

            $newManifest = Get-Content -Raw -LiteralPath $manifestCandidate.FullName | ConvertFrom-Json

            foreach ($include in $installedManifest.include) {
                $targetPath = Join-Path $PackRepoRoot $include
                if (Test-Path $targetPath) {
                    Remove-Item -LiteralPath $targetPath -Force -Recurse
                }
            }

            if ((Test-Path $moduleRoot -PathType Container) -and -not (Get-ChildItem -LiteralPath $moduleRoot -Force)) {
                Remove-Item -LiteralPath $moduleRoot -Force
            }

            foreach ($include in $newManifest.include) {
                $sourcePath = Join-Path $repoClonePath $include
                if (-not (Test-Path $sourcePath)) {
                    Write-Error "Update archive missing expected path '$include'."
                }

                $destinationPath = Join-Path $PackRepoRoot $include
                $destinationDir = Split-Path $destinationPath -Parent
                if ($destinationDir -and -not (Test-Path $destinationDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -Recurse
            }

            Write-Build Green "Updated module '$moduleName' to version $Version from $repositoryUrl."
        }
        finally {
            if (Test-Path $tempRoot -PathType Container) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
            }
        }
    }

    <#
        .SYNOPSIS
            Installs an enabler and triggers its install routine.
        .DESCRIPTION
            Ensures an enabler name is supplied, invokes `download-enabler` when a Git source is provided, and then runs the enabler's own `install` task so it can perform post-copy setup.
        .PARAMETER Enabler
            Name of the enabler to activate within the workspace.
        .PARAMETER Version
            Target version for the enabler. Required when `-Git` is supplied so the download task knows which tag to fetch.
        .PARAMETER Git
            Optional Git repository containing the enabler files. When omitted, the task assumes the enabler is already present under `./enablers/<name>/`.
        .EXAMPLE
            {CLI} . install-enabler -Enabler azcli -Version 0.1.0 -Git https://github.com/codepic/Codepic.Cli.Enabler.AzCli.git
        .EXAMPLE
            {CLI} . install-enabler -Enabler azcli
    #>
    task install-enabler download-enabler, {
        $Enabler | Guard-NotNullOrEmpty 'Specify -Enabler when invoking install-enabler.'

        $enablerTasksPath = Join-Path $PackRepoRoot "enablers/$Enabler/.tasks.ps1"
        Invoke-EnablerTask -TaskPath $enablerTasksPath -TaskName 'install'

        Write-Build Green "Installed enabler '$Enabler' version $Version from $Git."
    }

    <#
        .SYNOPSIS
            Downloads an enabler from a Git repository.
        .DESCRIPTION
            Clones the supplied Git repository to a temporary location, locates a matching enabler manifest, and copies the manifest's include paths into the current repository.
        .PARAMETER Enabler
            Name of the enabler expected inside the remote manifest.
        .PARAMETER Version
            Version tag to install from the remote manifest.
        .PARAMETER Git
            The Git repository URL to clone.
        .EXAMPLE
            {CLI} . install-enabler -Enabler azcli -Version 0.1.0 -Git https://github.com/codepic/Codepic.Cli.Enabler.AzCli.git
    #>
    task download-enabler -If ($Git) {
        $Version | Guard-NotNullOrEmpty 'Specify -Version when installing enabler from git.'
        $Git     | Guard-NotNullOrEmpty 'Specify -Git when installing enabler from git.'

        Ensure-Directory -Path $PackEnablersRoot
        $tempRoot = New-TemporaryDirectory

        try {
            $gitCloneBranch = "v$Version"
            $repoClonePath = Join-Path $tempRoot 'repo'

            exec {
                git clone --quiet --depth 1 --branch $gitCloneBranch --single-branch $Git $repoClonePath
            } -Echo

            $manifestCandidate = Get-ChildItem -Path $repoClonePath -Recurse -Filter 'enabler.manifest.json' -ErrorAction SilentlyContinue |
            Where-Object {
                try {
                    $candidate = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
                    ($candidate.name -and $candidate.name.ToString().ToLowerInvariant() -eq $Enabler.Value) -and `
                    ($candidate.version -and $candidate.version.ToString() -eq $Version)
                }
                catch {
                    $false
                }
            } | Select-Object -First 1

            if (-not $manifestCandidate) {
                Write-Error "Unable to find an enabler.manifest.json matching name '$Enabler' and version '$Version' in $Git."
            }

            $manifest = Get-Content -Raw -LiteralPath $manifestCandidate.FullName | ConvertFrom-Json

            foreach ($include in $manifest.include) {
                $sourcePath = Join-Path $repoClonePath $include
                if (-not (Test-Path $sourcePath)) {
                    Write-Error "Install archive missing expected path '$include'."
                }

                $destinationPath = Join-Path $PackRepoRoot $include
                $destinationDir = Split-Path $destinationPath -Parent
                if ($destinationDir) {
                    Ensure-Directory -Path $destinationDir
                }

                Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force -Recurse
            }
        }
        finally {
            if (Test-Path $tempRoot -PathType Container) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
            }
        }
    }

    <#
        .SYNOPSIS
            Upgrades an installed enabler to a newer version.
        .DESCRIPTION
            Invokes the enabler's own `upgrade` task so it can perform version-specific update logic.
        .PARAMETER Enabler
            Name of the enabler to upgrade within the workspace.
        .PARAMETER Git
            Optional Git repository containing the enabler files. When omitted, the task assumes the enabler is already present under `./enablers/<name>/`.
        .EXAMPLE
            {CLI} . upgrade-enabler -Enabler azcli
    #>
    task upgrade-enabler {
        if (-not $Enabler) {
            Write-Error "Specify -Enabler when invoking upgrade-enabler."
        }

        Invoke-Build upgrade -File ./enablers/$Enabler/.tasks.ps1 -Parameters @RestArgs
    }

    <#
        .SYNOPSIS
            Removes an installed enabler and its tracked files.
        .DESCRIPTION
            Executes the enabler removal task (if present) and deletes every include path declared in the manifest.
        .PARAMETER Enabler
            Name of the enabler to remove from the workspace.
        .EXAMPLE
            {CLI} . remove-enabler -Enabler azcli
    #>
    task remove-enabler {
        if (-not $Enabler) {
            Write-Error "Specify -Enabler when invoking remove-enabler."
        }

        $enablerRoot = Join-Path $PackEnablersRoot $Enabler
        $manifestPath = Join-Path $enablerRoot 'enabler.manifest.json'

        if (-not (Test-Path $manifestPath -PathType Leaf)) {
            Write-Error "Enabler manifest not found at $manifestPath. Nothing to remove."
        }

        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        $enablerTasksPath = Join-Path $PackRepoRoot "enablers/$Enabler/.tasks.ps1"

        if (Test-Path $enablerTasksPath -PathType Leaf) {
            try {
                Invoke-EnablerTask -TaskPath $enablerTasksPath -TaskName 'remove'
            }
            catch {
                Write-Warning $_
            }
        }

        foreach ($include in $manifest.include) {
            $targetPath = Join-Path $PackRepoRoot $include
            Remove-PathItem -LiteralPath $targetPath
        }

        if ((Test-Path $enablerRoot -PathType Container) -and -not (Get-ChildItem -LiteralPath $enablerRoot -Force)) {
            Remove-Item -LiteralPath $enablerRoot -Force
        }

        Write-Build Green "Removed enabler '$Enabler'."
    }

    <#
        .SYNOPSIS
            Executes the test routine for a named enabler.
        .DESCRIPTION
            Validates that the enabler task file exists and invokes its `test` task so the enabler can run self-checks or smoke tests.
        .PARAMETER Enabler
            Name of the enabler whose test routine should be executed.
        .EXAMPLE
            {CLI} . test-enabler -Enabler bicep
    #>
    task test-enabler {
        if (-not $Enabler) {
            Write-Error "Specify -Enabler when invoking test-enabler."
        }

        $enablerTasksPath = Join-Path $PackRepoRoot "enablers/$Enabler/.tasks.ps1"

        if (-not (Test-Path $enablerTasksPath -PathType Leaf)) {
            Write-Error "Enabler task file not found at $enablerTasksPath. Install the enabler before running its tests."
        }

        Invoke-EnablerTask -TaskPath $enablerTasksPath -TaskName 'test'

        Write-Build Green "Ran test task for enabler '$Enabler'."
    }

    <#
        .SYNOPSIS
            Creates a portable archive of a module based on its manifest.
        .DESCRIPTION
            Validates the module manifest, gathers all declared include paths, and writes Module.zip under ./dist/<module>/.
        .PARAMETER Module
            The module name whose manifest should be evaluated.
        .EXAMPLE
            {CLI} . pack-module -Module sample
    #>
    task pack-module {
        if (-not $Module) {
            Write-Error "Specify -Module when invoking pack-module."
        }

        $moduleName = $Module.ToLowerInvariant()
        $moduleRoot = Join-Path $PackModulesRoot $moduleName
        $manifestPath = Join-Path $moduleRoot 'module.manifest.json'

        if (-not (Test-Path $manifestPath -PathType Leaf)) {
            Write-Error "Module manifest not found at $manifestPath."
        }

        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace($manifest.version)) {
            Write-Error "Manifest version is required to create a versioned archive."
        }

        if ($Version -and $Version -ne $manifest.version) {
            Write-Error "Specified -Version '$Version' does not match manifest version '$($manifest.version)'."
        }

        if ($manifest.name -ne $moduleName) {
            Write-Error "Manifest name '$($manifest.name)' must match module directory '$moduleName'."
        }

        foreach ($include in $manifest.include) {
            Resolve-Path -Path (Join-Path $PackRepoRoot $include) -ErrorAction Stop | Out-Null
        }

        $archiveRelativePaths = [System.Collections.Generic.List[string]]::new()
        foreach ($includePath in $manifest.include) {
            $archiveRelativePaths.Add($includePath)
        }

        if ($manifest.exclude) {
            foreach ($exclude in $manifest.exclude) {
                Resolve-Path -Path (Join-Path $PackRepoRoot $exclude) -ErrorAction Stop | Out-Null
            }
            $archiveRelativePaths = $archiveRelativePaths | Where-Object { $manifest.exclude -notcontains $_ }
        }

        $archiveRelativePaths = $archiveRelativePaths | Sort-Object -Unique

        if (-not $archiveRelativePaths) {
            Write-Error "Manifest include set resolved to an empty file list."
        }

        if (-not (Test-Path $PackDistRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $PackDistRoot | Out-Null
        }

        $distModuleRoot = Join-Path $PackDistRoot $moduleName
        if (-not (Test-Path $distModuleRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $distModuleRoot | Out-Null
        }

        $zipFileName = "$moduleName.$($manifest.version).zip"
        $zipPath = Join-Path $distModuleRoot $zipFileName
        if (Test-Path $zipPath -PathType Leaf) {
            Remove-Item -LiteralPath $zipPath -Force
        }

        $legacyZipPath = Join-Path $distModuleRoot 'Module.zip'
        if (Test-Path $legacyZipPath -PathType Leaf) {
            Remove-Item -LiteralPath $legacyZipPath -Force
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

        $zipArchive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($relativePath in $archiveRelativePaths) {
                $sourcePath = Join-Path $PackRepoRoot $relativePath
                $entryName = $relativePath -replace '\\', '/'
                $entry = $zipArchive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
                $entryStream = $entry.Open()
                try {
                    $fileStream = [System.IO.File]::OpenRead($sourcePath)
                    try {
                        $fileStream.CopyTo($entryStream)
                    }
                    finally {
                        $fileStream.Dispose()
                    }
                }
                finally {
                    $entryStream.Dispose()
                }
            }
        }
        finally {
            $zipArchive.Dispose()
        }

        Write-Build Green "Packaged module '$moduleName' version $($manifest.version) to $zipPath."
    }

    <#
        .SYNOPSIS
            Expands a packaged module archive back into the repository.
        .DESCRIPTION
            Extracts Module.zip from ./dist/<module>/ and restores its contents to the repository root, overwriting existing files if present.
        .PARAMETER Module
            The module name whose archive should be extracted.
        .EXAMPLE
            {CLI} . unpack-module -Module sample
    #>
    task unpack-module {
        if (-not $Module) {
            Write-Error "Specify -Module when invoking unpack-module."
        }

        if (-not $Version) {
            Write-Error "Specify -Version when invoking unpack-module."
        }

        $moduleName = $Module.ToLowerInvariant()
        $distModuleRoot = Join-Path $PackDistRoot $moduleName

        $zipPath = Join-Path $distModuleRoot "$moduleName.$Version.zip"
        if (-not (Test-Path $zipPath -PathType Leaf)) {
            $legacyPath = Join-Path $distModuleRoot "Module.$Version.zip"
            if (Test-Path $legacyPath -PathType Leaf) {
                $zipPath = $legacyPath
            }
            else {
                Write-Error "Module archive version '$Version' not found. Expected one of: '$($moduleName).$Version.zip' or 'Module.$Version.zip' in $distModuleRoot."
            }
        }

        $archiveVersion = $Version

        $tempRoot = New-TemporaryDirectory

        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $tempRoot -Force

            $manifestRelativePath = Join-Path (Join-Path 'modules' $moduleName) 'module.manifest.json'
            $expandedManifestPath = Join-Path $tempRoot $manifestRelativePath

            if (-not (Test-Path $expandedManifestPath -PathType Leaf)) {
                $alternateManifestPath = Join-Path $tempRoot 'module.manifest.json'
                if (Test-Path $alternateManifestPath -PathType Leaf) {
                    $expandedManifestPath = $alternateManifestPath
                }
                else {
                    Write-Error "Manifest not found inside archive at $manifestRelativePath or in the archive root."
                }
            }

            $manifest = Get-Content -Raw -LiteralPath $expandedManifestPath | ConvertFrom-Json

            foreach ($include in $manifest.include) {
                $sourcePath = Join-Path $tempRoot $include
                if (-not (Test-Path $sourcePath -PathType Leaf)) {
                    $fallbackSourcePath = Join-Path $tempRoot (Split-Path $include -Leaf)
                    if (Test-Path $fallbackSourcePath -PathType Leaf) {
                        $sourcePath = $fallbackSourcePath
                    }
                    else {
                        Write-Error "Archive missing expected file '$include'."
                    }
                }

                $destinationPath = Join-Path $PackRepoRoot $include
                $destinationDir = Split-Path $destinationPath -Parent
                if ($destinationDir -and -not (Test-Path $destinationDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
            }
        }
        finally {
            if (Test-Path $tempRoot -PathType Container) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force
            }
        }

        if ([string]::IsNullOrWhiteSpace($archiveVersion)) {
            Write-Build Green "Unpacked module '$moduleName' from $zipPath."
        }
        else {
            Write-Build Green "Unpacked module '$moduleName' version $archiveVersion from $zipPath."
        }
    }

    <#
        .SYNOPSIS
            Removes a module's files based on its manifest definitions.
        .DESCRIPTION
            Reads the module.manifest.json file and deletes each referenced include path before cleaning up any empty module directory.
        .PARAMETER Module
            The module name whose files should be removed from the workspace.
        .EXAMPLE
            {CLI} . remove-module -Module sample
    #>
    task remove-module {
        if (-not $Module) {
            Write-Error "Specify -Module when invoking remove-module."
        }

        $moduleName = $Module.ToLowerInvariant()
        $moduleRoot = Join-Path $PackModulesRoot $moduleName
        $manifestPath = Join-Path $moduleRoot 'module.manifest.json'

        if (-not (Test-Path $manifestPath -PathType Leaf)) {
            Write-Error "Module manifest not found at $manifestPath."
        }

        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

        foreach ($include in $manifest.include) {
            $targetPath = Join-Path $PackRepoRoot $include
            if (Test-Path $targetPath) {
                Remove-Item -LiteralPath $targetPath -Force -Recurse
            }
        }

        if ((Test-Path $moduleRoot -PathType Container) -and -not (Get-ChildItem -LiteralPath $moduleRoot -Force)) {
            Remove-Item -LiteralPath $moduleRoot -Force
        }

        Write-Build Green "Removed module '$moduleName' files defined in manifest."
    }
}

end {

}
