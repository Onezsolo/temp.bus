function Get-HouseRuleHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $leaf = Split-Path -Leaf $Path

    if ($leaf -eq 'SKILL.md') {
        $skillDir = Split-Path -Parent $Path
        $parts = New-Object System.Collections.Generic.List[string]

        Get-ChildItem -LiteralPath $skillDir -Recurse -File -ErrorAction Stop | Sort-Object FullName | ForEach-Object {
            $relative = $_.FullName.Substring($skillDir.Length + 1).Replace('\', '/')
            $fileHash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
            $parts.Add("$relative`n$fileHash")
        }

        $text = ($parts -join "`n") + "`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        $sha = [System.Security.Cryptography.SHA256]::Create()

        try {
            $hash = $sha.ComputeHash($bytes)
        } finally {
            $sha.Dispose()
        }

        return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}
