<#
    .SYNOPSIS
        Represents a string that is always normalized to lowercase.

    .DESCRIPTION
        The LowerCase class wraps a string and ensures that its value
        is stored in lowercase form. It provides an implicit cast from
        [string] and overrides ToString() for easy use.

    .EXAMPLE
        [LowerCase]"HELLO"
        # Returns an instance whose Value is "hello"
#>
class LowerCase {
    [string]$Value
    LowerCase([string]$s) { $this.Value = $s.ToLowerInvariant() }
    static [LowerCase] op_Implicit([string]$s) { return [LowerCase]::new($s) }
    [string] ToString() { return $this.Value }
}
