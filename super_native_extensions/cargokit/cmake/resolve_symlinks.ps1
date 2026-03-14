function Resolve-Symlinks {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    [string] $separator = '/'
    [string] $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    [string[]] $parts = $normalizedPath.Replace('\', $separator).Split($separator)

    [string] $realPath = ''
    foreach ($part in $parts) {
        if ([string]::IsNullOrEmpty($part)) {
            continue
        }

        if ($realPath -and !$realPath.EndsWith($separator)) {
            $realPath += $separator
        }

        $realPath += $part

        # The slash is important when using Get-Item on Drive letters in pwsh.
        if (-not($realPath.Contains($separator)) -and $realPath.EndsWith(':')) {
            $realPath += '/'
        }

        try {
            $item = Get-Item -LiteralPath $realPath -Force -ErrorAction Stop
        }
        catch {
            return $normalizedPath.Replace('\', '/')
        }

        if ($item.LinkTarget) {
            $linkTarget = $item.LinkTarget
            if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
                $linkTarget = Join-Path $item.DirectoryName $linkTarget
            }

            $realPath = [System.IO.Path]::GetFullPath($linkTarget).Replace('\', '/')
        }
    }

    if ([string]::IsNullOrWhiteSpace($realPath)) {
        return $normalizedPath.Replace('\', '/')
    }

    $realPath
}

$path = Resolve-Symlinks -Path $args[0]
Write-Host $path
