<#[
.SYNOPSIS
    PSScriptAnalyzer configuration for Codepic CLI contributors.
.DESCRIPTION
    Enforces cross-platform compatibility for Windows and Ubuntu developers running PowerShell 7 or later.
    See https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer for guidance.
#>
@{
    IncludeDefaultRules = $true
    Severity            = @('Error', 'Warning')
    Rules               = @{
        PSUseCompatibleSyntax     = @{
            Enable         = $true
            TargetVersions = @('7.0')
        }
        PSUseCompatibleCmdlets    = @{
            Enable        = $true
            compatibility = @(
                'core-7.0.0-windows'
                'core-7.0.0-linux'
            )
        }
        PSUseCompatibleCommands   = @{
            Enable         = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
        PSUseCompatibleTypes      = @{
            Enable         = $true
            TargetProfiles = @(
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }
        PSAvoidUsingCmdletAliases = @{
            Enable    = $true
            AllowList = @(
                'exec'
                'task'
                'Invoke-Build'
            )
        }
        PSReviewUnusedParameter   = @{
            Enable             = $true
            CommandsToTraverse = @(
                'task',
                'exec'
            )
        }
    }
}
