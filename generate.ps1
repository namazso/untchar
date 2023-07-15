"Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node", `
    "Registry::HKEY_CURRENT_USER\SOFTWARE\Wow6432Node", `
    "Registry::HKEY_LOCAL_MACHINE\SOFTWARE", `
    "Registry::HKEY_CURRENT_USER\SOFTWARE" | ForEach-Object {
    $Path = "$_\Microsoft\Microsoft SDKs\Windows\v10.0";
    If (Test-Path -Path $Path) {
        $Win10SDK = (Get-ItemProperty -Path $Path).InstallationFolder;
        $Win10SDKVersion = (Get-ItemProperty -Path $Path).ProductVersion;
    }
}

If ($Null -eq $Win10SDK) {
    throw "Windows 10 SDK not found!";
}

$Include = "$Win10SDK\Include\$Win10SDKVersion.0";

$Headers = (Get-ChildItem -Path $Include -Include "*.h" -File -Recurse -ErrorAction SilentlyContinue)

$SuffixA = ($Headers | Select-String -Pattern '^\s*#define\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)A\s*$'
    | Where-Object { $_.Matches[0].Groups[1].Value -eq $_.Matches[0].Groups[2].Value }
    | ForEach-Object { $_.Matches[0].Groups[1].Value }
    | Sort-Object
    | Select-Object -Unique);

$SuffixW = ($Headers | Select-String -Pattern '^\s*#define\s+([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)W\s*$'
    | Where-Object { $_.Matches[0].Groups[1].Value -eq $_.Matches[0].Groups[2].Value }
    | ForEach-Object { $_.Matches[0].Groups[1].Value }
    | Sort-Object
    | Select-Object -Unique);

$TChar = (Get-Item -Path "$Include\ucrt\tchar.h" | Select-String -Pattern '^\s*#define\s+(_[a-zA-Z0-9_]+)\s+(_[a-zA-Z0-9_]+)\s*$'
    | ForEach-Object { $_.Matches[0].Groups[1].Value }
    | Sort-Object
    | Select-Object -Unique);

$Intersect = ($SuffixA | Where-Object { $SuffixW -Contains $_ }) + $TChar;

$Intersect | ForEach-Object {
    "#ifdef $_`n#undef $_`n#endif`n"
} > "untchar.h"
