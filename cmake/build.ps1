#!/usr/bin/env pwsh

<#

.SYNOPSIS
        build
        Created By: Stefano Sinigardi
        Created Date: February 18, 2019
        Last Modified Date: April 1, 2022

.DESCRIPTION
Build tool using CMake, trying to properly setup the environment around compiler

.PARAMETER DisableInteractive
Disable script interactivity (useful for CI runs)

.PARAMETER DisableDLLcopy
Disable automatic DLL deployment through vcpkg at the end

.PARAMETER EnableCUDA
Build tool with CUDA support

.PARAMETER EnableOpenMP
Build tool with OpenMP support

.PARAMETER EnableVTK
Build tool with VTK support

.PARAMETER EnableCXSDKIntegration
Enable CX (LMI 3D) SDK integration

.PARAMETER EnableGOSDKIntegration
Enable GO (Gocator) SDK integration

.PARAMETER UseVCPKG
Use VCPKG to build tool dependencies. Clone it if not already found on system

.PARAMETER DoNotUpdateVCPKG
Do not update vcpkg before running the build (valid only if vcpkg is cloned by this script or the version found on the system is git-enabled)

.PARAMETER VCPKGSuffix
Specify a suffix to the vcpkg local folder for searching, useful to point to a custom version

.PARAMETER VCPKGFork
Specify a fork username to point to a custom version of vcpkg (ex: -VCPKGFork "custom" to point to github.com/custom/vcpkg)

.PARAMETER VCPKGBranch
Specify a branch to checkout in the vcpkg folder, useful to point to a custom version especially for forked vcpkg versions

.PARAMETER DoNotUpdateTOOL
Do not update the tool before running the build (valid only if tool is git-enabled)

.PARAMETER DoNotDeleteBuildFolder
Do not delete temporary cmake build folder at the end of the script

.PARAMETER DoNotSetupVS
Do not setup VisualStudio environment using the vcvars script

.PARAMETER DoNotUseNinja
Do not use Ninja for build

.PARAMETER ForceStaticLib
Create library as static instead of the default linking mode of your system

.PARAMETER ForceVCPKGCacheRemoval
Force clean up of the local vcpkg binary cache before building

.PARAMETER ForceVCPKGBuildtreesRemoval
Force clean up of vcpkg buildtrees temp folder at the end of the script

.PARAMETER ForceVCPKGPackagesRemoval
Force clean up of vcpkg packages folder at the end of the script

.PARAMETER ForceSetupVS
Forces Visual Studio setup, also on systems on which it would not have been enabled automatically

.PARAMETER ForceGCCVersion
Force a specific GCC version

.PARAMETER NumberOfBuildWorkers
Forces a specific number of threads for parallel building

.PARAMETER AdditionalBuildSetup
Additional setup parameters to manually pass to CMake

.EXAMPLE
.\build -DisableInteractive -DoNotDeleteBuildFolder -UseVCPKG

#>

<#
Copyright (c) Stefano Sinigardi

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

param (
  [switch]$DisableInteractive = $false,
  [switch]$DisableDLLcopy = $false,
  [switch]$EnableCUDA = $false,
  [switch]$EnableOpenMP = $false,
  [switch]$EnableVTK = $false,
  [switch]$EnableCXSDKIntegration = $false,
  [switch]$EnableGOSDKIntegration = $false,
  [switch]$UseVCPKG = $false,
  [switch]$DoNotUpdateVCPKG = $false,
  [string]$VCPKGSuffix = "",
  [string]$VCPKGFork = "",
  [string]$VCPKGBranch = "",
  [switch]$DoNotUpdateTOOL = $false,
  [switch]$DoNotDeleteBuildFolder = $false,
  [switch]$DoNotSetupVS = $false,
  [switch]$DoNotUseNinja = $false,
  [switch]$ForceStaticLib = $false,
  [switch]$ForceVCPKGCacheRemoval = $false,
  [switch]$ForceVCPKGBuildtreesRemoval = $false,
  [switch]$ForceVCPKGPackagesRemoval = $false,
  [switch]$ForceSetupVS = $false,
  [Int32]$ForceGCCVersion = 0,
  [Int32]$NumberOfBuildWorkers = 8,
  [string]$AdditionalBuildSetup = ""  # "-DCMAKE_CUDA_ARCHITECTURES=30"
)

$build_ps1_version = "2.1.0"

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -Path $PSScriptRoot/../build.log

Function MyThrow ($Message) {
  if ($DisableInteractive) {
    Write-Host $Message -ForegroundColor Red
    throw
  }
  else {
    # Check if running in PowerShell ISE
    if ($psISE) {
      # "ReadKey" not supported in PowerShell ISE.
      # Show MessageBox UI
      $Shell = New-Object -ComObject "WScript.Shell"
      $Shell.Popup($Message, 0, "OK", 0)
      throw
    }

    $Ignore =
    16, # Shift (left or right)
    17, # Ctrl (left or right)
    18, # Alt (left or right)
    20, # Caps lock
    91, # Windows key (left)
    92, # Windows key (right)
    93, # Menu key
    144, # Num lock
    145, # Scroll lock
    166, # Back
    167, # Forward
    168, # Refresh
    169, # Stop
    170, # Search
    171, # Favorites
    172, # Start/Home
    173, # Mute
    174, # Volume Down
    175, # Volume Up
    176, # Next Track
    177, # Previous Track
    178, # Stop Media
    179, # Play
    180, # Mail
    181, # Select Media
    182, # Application 1
    183  # Application 2

    Write-Host $Message -ForegroundColor Red
    Write-Host -NoNewline "Press any key to continue..."
    while (($null -eq $KeyInfo.VirtualKeyCode) -or ($Ignore -contains $KeyInfo.VirtualKeyCode)) {
      $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
    Write-Host ""
    throw
  }
}

Function DownloadNinja() {
  Write-Host "Unable to find Ninja, downloading a portable version on-the-fly" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue ninja
  Remove-Item -Force -ErrorAction SilentlyContinue ninja.zip
  if ($IsWindows -or $IsWindowsPowerShell) {
    $url = "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip"
  }
  elseif ($IsLinux) {
    $url = "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip"
  }
  elseif ($IsMacOS) {
    $url = "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-mac.zip"
  }
  else {
    MyThrow("Unknown OS, unsupported")
  }
  Invoke-RestMethod -Uri $url -Method Get -ContentType application/zip -OutFile "ninja.zip"
  Expand-Archive -Path ninja.zip
  Remove-Item -Force -ErrorAction SilentlyContinue ninja.zip
}


Write-Host "Build script version ${build_ps1_version}"

if ((-Not $DisableInteractive) -and (-Not $UseVCPKG)) {
  $Result = Read-Host "Enable vcpkg to install dependencies (yes/no)"
  if (($Result -eq 'Yes') -or ($Result -eq 'Y') -or ($Result -eq 'yes') -or ($Result -eq 'y')) {
    $UseVCPKG = $true
  }
}

Write-Host -NoNewLine "PowerShell version:"
$PSVersionTable.PSVersion

if ($PSVersionTable.PSVersion.Major -eq 5) {
  $IsWindowsPowerShell = $true
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
  MyThrow("Your PowerShell version is too old, please update it.")
}

if ($IsLinux -or $IsMacOS) {
  $bootstrap_ext = ".sh"
  $exe_ext = ""
}
elseif ($IsWindows -or $IsWindowsPowerShell) {
  $bootstrap_ext = ".bat"
  $exe_ext = ".exe"
}
if ($UseVCPKG) {
  Write-Host "vcpkg bootstrap script: bootstrap-vcpkg${bootstrap_ext}"
}

if ((-Not $IsWindows) -and (-Not $IsWindowsPowerShell) -and (-Not $ForceSetupVS)) {
  $DoNotSetupVS = $true
}

if ($ForceStaticLib) {
  Write-Host "Forced CMake to produce a static library"
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DBUILD_SHARED_LIBS=OFF "
}

if (($IsLinux -or $IsMacOS) -and ($ForceGCCVersion -gt 0)) {
  Write-Host "Manually setting CC and CXX variables to gcc version $ForceGCCVersion"
  $env:CC = "gcc-$ForceGCCVersion"
  $env:CXX = "g++-$ForceGCCVersion"
}

$vcpkg_triplet_set_by_this_script = $false

if (($IsWindows -or $IsWindowsPowerShell) -and (-Not $env:VCPKG_DEFAULT_TRIPLET)) {
  $env:VCPKG_DEFAULT_TRIPLET = "x64-windows-release"
  $vcpkg_triplet_set_by_this_script = $true
}
elseif ($IsMacOS -and (-Not $env:VCPKG_DEFAULT_TRIPLET)) {
  $env:VCPKG_DEFAULT_TRIPLET = "x64-osx-release"
  $vcpkg_triplet_set_by_this_script = $true
}
elseif ($IsLinux -and (-Not $env:VCPKG_DEFAULT_TRIPLET)) {
  $env:VCPKG_DEFAULT_TRIPLET = "x64-linux-release"
  $vcpkg_triplet_set_by_this_script = $true
}

if ($VCPKGSuffix -ne "" -and -not $UseVCPKG) {
  Write-Host "You specified a vcpkg folder suffix but didn't enable vcpkg integration, doing that for you" -ForegroundColor Yellow
  $UseVCPKG = $true
}

if ($VCPKGFork -ne "" -and -not $UseVCPKG) {
  Write-Host "You specified a vcpkg fork but didn't enable vcpkg integration, doing that for you" -ForegroundColor Yellow
  $UseVCPKG = $true
}

if ($VCPKGBranch -ne "" -and -not $UseVCPKG) {
  Write-Host "You specified a vcpkg branch but didn't enable vcpkg integration, doing that for you" -ForegroundColor Yellow
  $UseVCPKG = $true
}

if ($EnableCUDA) {
  if ($IsMacOS) {
    Write-Host "Cannot enable CUDA on macOS" -ForegroundColor Yellow
    $EnableCUDA = $false
  }
  Write-Host "CUDA is enabled"
}
elseif (-Not $IsMacOS) {
  Write-Host "CUDA is disabled, please pass -EnableCUDA to the script to enable"
}

if ($UseVCPKG) {
  Write-Host "VCPKG is enabled"
  if ($DoNotUpdateVCPKG) {
    Write-Host "VCPKG will not be updated to latest version if found" -ForegroundColor Yellow
  }
  else {
    Write-Host "VCPKG will be updated to latest version if found"
  }
}
else {
  Write-Host "VCPKG is disabled, please pass -UseVCPKG to the script to enable"
}

if ($DoNotSetupVS) {
  Write-Host "VisualStudio integration is disabled"
}
else {
  Write-Host "VisualStudio integration is enabled, please pass -DoNotSetupVS to the script to disable"
}

if ($DoNotUseNinja) {
  Write-Host "Ninja is disabled"
}
else {
  Write-Host "Ninja is enabled, please pass -DoNotUseNinja to the script to disable"
}

Push-Location $PSScriptRoot

$GIT_EXE = Get-Command "git" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
if (-Not $GIT_EXE) {
  MyThrow("Could not find git, please install it")
}
else {
  Write-Host "Using git from ${GIT_EXE}"
}

if (Test-Path "$PSScriptRoot/../.git") {
  Write-Host "This tool has been added as a submodule in a repo cloned with git and which supports self-updating mechanism"
  if ($DoNotUpdateTOOL) {
    Write-Host "This tool will not self-update sources" -ForegroundColor Yellow
  }
  else {
    Write-Host "This tool will self-update sources, please pass -DoNotUpdateTOOL to the script to disable"
    Set-Location "$PSScriptRoot/.."
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "pull"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Updating this tool sources failed! Exited with error code $exitCode.")
    }
    if (Test-Path "$PSScriptRoot/../.gitmodules") {
      $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "submodule update --init --recursive"
      $handle = $proc.Handle
      $proc.WaitForExit()
      $exitCode = $proc.ExitCode
      if (-Not ($exitCode -eq 0)) {
        MyThrow("Updating this tool submodule sources failed! Exited with error code $exitCode.")
      }
    }
    Set-Location "$PSScriptRoot"
  }
}

$CMAKE_EXE = Get-Command "cmake" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
if (-Not $CMAKE_EXE) {
  MyThrow("Could not find CMake, please install it")
}
else {
  Write-Host "Using CMake from ${CMAKE_EXE}"
  $proc = Start-Process -NoNewWindow -PassThru -FilePath ${CMAKE_EXE} -ArgumentList "--version"
  $handle = $proc.Handle
  $proc.WaitForExit()
  $exitCode = $proc.ExitCode
  if (-Not ($exitCode -eq 0)) {
    MyThrow("CMake version check failed! Exited with error code $exitCode.")
  }
}

if (-Not $DoNotUseNinja) {
  $NINJA_EXE = Get-Command "ninja" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
  if (-Not $NINJA_EXE) {
    DownloadNinja
    $env:PATH = '{0}{1}{2}' -f $env:PATH, [IO.Path]::PathSeparator, "${PSScriptRoot}/ninja"
    $NINJA_EXE = Get-Command "ninja" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
    if (-Not $NINJA_EXE) {
      $DoNotUseNinja = $true
      Write-Host "Could not find Ninja, unable to download a portable ninja, using msbuild or make backends as a fallback" -ForegroundColor Yellow
    }
  }
  if ($NINJA_EXE) {
    Write-Host "Using Ninja from ${NINJA_EXE}"
    Write-Host -NoNewLine "Ninja version "
    $proc = Start-Process -NoNewWindow -PassThru -FilePath ${NINJA_EXE} -ArgumentList "--version"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      $DoNotUseNinja = $true
      Write-Host "Unable to run Ninja previously found, using msbuild or make backends as a fallback" -ForegroundColor Yellow
    }
    else {
      $generator = "Ninja"
      $AdditionalBuildSetup = $AdditionalBuildSetup + " -DCMAKE_BUILD_TYPE=Release"
    }
  }
}

function getProgramFiles32bit() {
  $out = ${env:PROGRAMFILES(X86)}
  if ($null -eq $out) {
    $out = ${env:PROGRAMFILES}
  }

  if ($null -eq $out) {
    MyThrow("Could not find [Program Files 32-bit]")
  }

  return $out
}

function getLatestVisualStudioWithDesktopWorkloadPath() {
  $programFiles = getProgramFiles32bit
  $vswhereExe = "$programFiles\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhereExe) {
    $output = & $vswhereExe -products * -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -format xml
    [xml]$asXml = $output
    foreach ($instance in $asXml.instances.instance) {
      $installationPath = $instance.InstallationPath -replace "\\$" # Remove potential trailing backslash
    }
    if (!$installationPath) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also partial installations" -ForegroundColor Yellow
      $output = & $vswhereExe -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationPath = $instance.InstallationPath -replace "\\$" # Remove potential trailing backslash
      }
    }
    if (!$installationPath) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also pre-release installations" -ForegroundColor Yellow
      $output = & $vswhereExe -prerelease -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationPath = $instance.InstallationPath -replace "\\$" # Remove potential trailing backslash
      }
    }
    if (!$installationPath) {
      MyThrow("Could not locate any installation of Visual Studio")
    }
  }
  else {
    MyThrow("Could not locate vswhere at $vswhereExe")
  }
  return $installationPath
}


function getLatestVisualStudioWithDesktopWorkloadVersion() {
  $programFiles = getProgramFiles32bit
  $vswhereExe = "$programFiles\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhereExe) {
    $output = & $vswhereExe -products * -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -format xml
    [xml]$asXml = $output
    foreach ($instance in $asXml.instances.instance) {
      $installationVersion = $instance.InstallationVersion
    }
    if (!$installationVersion) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also partial installations" -ForegroundColor Yellow
      $output = & $vswhereExe -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationVersion = $instance.installationVersion
      }
    }
    if (!$installationVersion) {
      Write-Host "Warning: no full Visual Studio setup has been found, extending search to include also pre-release installations" -ForegroundColor Yellow
      $output = & $vswhereExe -prerelease -products * -latest -format xml
      [xml]$asXml = $output
      foreach ($instance in $asXml.instances.instance) {
        $installationVersion = $instance.installationVersion
      }
    }
    if (!$installationVersion) {
      MyThrow("Could not locate any installation of Visual Studio")
    }
  }
  else {
    MyThrow("Could not locate vswhere at $vswhereExe")
  }
  return $installationVersion
}

$vcpkg_root_set_by_this_script = $false

if ((Test-Path env:VCPKG_ROOT) -and $UseVCPKG -and $VCPKGSuffix -eq "") {
  $vcpkg_path = "$env:VCPKG_ROOT"
  Write-Host "Found vcpkg in VCPKG_ROOT: $vcpkg_path"
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VCPKG_INTEGRATION:BOOL=ON"
}
elseif (-not($null -eq ${env:WORKSPACE}) -and (Test-Path "${env:WORKSPACE}/vcpkg${VCPKGSuffix}") -and $UseVCPKG) {
  $vcpkg_path = "${env:WORKSPACE}/vcpkg${VCPKGSuffix}"
  $env:VCPKG_ROOT = "${env:WORKSPACE}/vcpkg${VCPKGSuffix}"
  $vcpkg_root_set_by_this_script = $true
  Write-Host "Found vcpkg in WORKSPACE/vcpkg${VCPKGSuffix}: $vcpkg_path"
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VCPKG_INTEGRATION:BOOL=ON"
}
elseif (-not($null -eq ${RUNVCPKG_VCPKG_ROOT_OUT})) {
  if ((Test-Path "${RUNVCPKG_VCPKG_ROOT_OUT}") -and $UseVCPKG) {
    $vcpkg_path = "${RUNVCPKG_VCPKG_ROOT_OUT}"
    $env:VCPKG_ROOT = "${RUNVCPKG_VCPKG_ROOT_OUT}"
    $vcpkg_root_set_by_this_script = $true
    Write-Host "Found vcpkg in RUNVCPKG_VCPKG_ROOT_OUT: $vcpkg_path"
    $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VCPKG_INTEGRATION:BOOL=ON"
  }
}
elseif ($UseVCPKG) {
  if (-Not (Test-Path "$PWD/vcpkg${VCPKGSuffix}")) {
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "clone https://github.com/microsoft/vcpkg vcpkg${VCPKGSuffix}"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-not ($exitCode -eq 0)) {
      MyThrow("Cloning vcpkg sources failed! Exited with error code $exitCode.")
    }
  }
  $vcpkg_path = "$PWD/vcpkg${VCPKGSuffix}"
  $env:VCPKG_ROOT = "$PWD/vcpkg${VCPKGSuffix}"
  $vcpkg_root_set_by_this_script = $true
  Write-Host "Found vcpkg in $PWD/vcpkg${VCPKGSuffix}: $vcpkg_path"
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VCPKG_INTEGRATION:BOOL=ON"
}
else {
  if (-not ($VCPKGSuffix -eq "")) {
    MyThrow("Unable to find vcpkg${VCPKGSuffix}")
  }
  else {
    Write-Host "Skipping vcpkg integration`n" -ForegroundColor Yellow
    $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VCPKG_INTEGRATION:BOOL=OFF"
  }
}

$vcpkg_branch_set_by_this_script = $false

if ($UseVCPKG -and (Test-Path "$vcpkg_path/.git")) {
  Push-Location $vcpkg_path
  if ($VCPKGFork -ne "") {
    $git_args = "remote add vcpkgfork https://github.com/${VCPKGFork}/vcpkg"
    Write-Host "git args: $git_args"
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "$git_args"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Adding remote https://github.com/${VCPKGFork}/vcpkg failed! Exited with error code $exitCode.")
    }
    $git_args = "fetch vcpkgfork"
    Write-Host "git args: $git_args"
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "$git_args"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Fetching from remote https://github.com/${VCPKGFork}/vcpkg failed! Exited with error code $exitCode.")
    }
  }
  if ($VCPKGBranch -ne "") {
    if ($VCPKGFork -ne "") {
      $git_args = "checkout vcpkgfork/$VCPKGBranch"
    }
    else {
      $git_args = "checkout $VCPKGBranch"
    }
    Write-Host "git args: $git_args"
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "$git_args"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Checking out branch $VCPKGBranch failed! Exited with error code $exitCode.")
    }
    $vcpkg_branch_set_by_this_script = $true
  }
  if (-Not $DoNotUpdateVCPKG -and $VCPKGFork -eq "") {
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "pull"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Updating vcpkg sources failed! Exited with error code $exitCode.")
    }
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $PWD/bootstrap-vcpkg${bootstrap_ext} -ArgumentList "-disableMetrics"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Bootstrapping vcpkg failed! Exited with error code $exitCode.")
    }
  }
  Pop-Location
}

if ($UseVCPKG -and ($vcpkg_path.length -gt 40) -and ($IsWindows -or $IsWindowsPowerShell)) {
  Write-Host "vcpkg path is very long and might fail. Please move it or" -ForegroundColor Yellow
  Write-Host "the entire tool folder to a shorter path, like C:\src" -ForegroundColor Yellow
  Write-Host "You can use the subst command to ease the process if necessary" -ForegroundColor Yellow
  if (-Not $DisableInteractive) {
    $Result = Read-Host "Do you still want to continue? (yes/no)"
    if (($Result -eq 'No') -or ($Result -eq 'N') -or ($Result -eq 'no') -or ($Result -eq 'n')) {
      MyThrow("Build aborted")
    }
  }
}

if ($ForceVCPKGCacheRemoval -and (-Not $UseVCPKG)) {
  Write-Host "VCPKG is not enabled, so local vcpkg binary cache will not be deleted even if requested" -ForegroundColor Yellow
}

if ($UseVCPKG -and $ForceVCPKGBuildtreesRemoval) {
  Write-Host "Cleaning folder buildtrees inside vcpkg" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue "$env:VCPKG_ROOT/buildtrees"
}


if ($UseVCPKG -and $ForceVCPKGCacheRemoval) {
  if ($IsWindows -or $IsWindowsPowerShell) {
    $vcpkgbinarycachepath = "$env:LOCALAPPDATA/vcpkg/archive"
  }
  elseif ($IsLinux) {
    $vcpkgbinarycachepath = "$env:HOME/.cache/vcpkg/archive"
  }
  elseif ($IsMacOS) {
    $vcpkgbinarycachepath = "$env:HOME/.cache/vcpkg/archive"
  }
  else {
    MyThrow("Unknown OS, unsupported")
  }
  Write-Host "Removing local vcpkg binary cache from $vcpkgbinarycachepath" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $vcpkgbinarycachepath
}

if (-Not $DoNotSetupVS) {
  $CL_EXE = Get-Command "cl" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
  if ((-Not $CL_EXE) -or ($CL_EXE -match "HostX86\\x86") -or ($CL_EXE -match "HostX64\\x86")) {
    $vsfound = getLatestVisualStudioWithDesktopWorkloadPath
    Write-Host "Found VS in ${vsfound}"
    Push-Location "${vsfound}\Common7\Tools"
    cmd.exe /c "VsDevCmd.bat -arch=x64 & set" |
    ForEach-Object {
      if ($_ -match "=") {
        $v = $_.split("="); Set-Item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
      }
    }
    Pop-Location
    Write-Host "Visual Studio Command Prompt variables set"
  }

  $tokens = getLatestVisualStudioWithDesktopWorkloadVersion
  $tokens = $tokens.split('.')
  if ($DoNotUseNinja) {
    $selectConfig = " --config Release "
    if ($tokens[0] -eq "14") {
      $generator = "Visual Studio 14 2015"
      $AdditionalBuildSetup = $AdditionalBuildSetup + " -T `"host=x64`" -A `"x64`""
    }
    elseif ($tokens[0] -eq "15") {
      $generator = "Visual Studio 15 2017"
      $AdditionalBuildSetup = $AdditionalBuildSetup + " -T `"host=x64`" -A `"x64`""
    }
    elseif ($tokens[0] -eq "16") {
      $generator = "Visual Studio 16 2019"
      $AdditionalBuildSetup = $AdditionalBuildSetup + " -T `"host=x64`" -A `"x64`""
    }
    elseif ($tokens[0] -eq "17") {
      $generator = "Visual Studio 17 2022"
      $AdditionalBuildSetup = $AdditionalBuildSetup + " -T `"host=x64`" -A `"x64`""
    }
    else {
      MyThrow("Unknown Visual Studio version, unsupported configuration")
    }
  }
}
if ($DoNotSetupVS -and $DoNotUseNinja) {
  $generator = "Unix Makefiles"
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DCMAKE_BUILD_TYPE=Release"
}
Write-Host "Setting up environment to use CMake generator: $generator"

if (-Not $IsMacOS -and $EnableCUDA) {
  $NVCC_EXE = Get-Command "nvcc" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
  if (-Not $NVCC_EXE) {
    if (Test-Path env:CUDA_PATH) {
      $env:PATH = '{0}{1}{2}' -f $env:PATH, [IO.Path]::PathSeparator, "${env:CUDA_PATH}/bin"
      Write-Host "Found cuda in ${env:CUDA_PATH}"
    }
    else {
      Write-Host "Unable to find CUDA, if necessary please install it or define a CUDA_PATH env variable pointing to the install folder" -ForegroundColor Yellow
    }
  }

  if (Test-Path env:CUDA_PATH) {
    if (-Not(Test-Path env:CUDA_TOOLKIT_ROOT_DIR)) {
      $env:CUDA_TOOLKIT_ROOT_DIR = "${env:CUDA_PATH}"
      Write-Host "Added missing env variable CUDA_TOOLKIT_ROOT_DIR" -ForegroundColor Yellow
    }
    if (-Not(Test-Path env:CUDACXX)) {
      $env:CUDACXX = "${env:CUDA_PATH}/bin/nvcc"
      Write-Host "Added missing env variable CUDACXX" -ForegroundColor Yellow
    }
  }
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_CUDA=ON"
}

if ($EnableOpenMP) {
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_OPENMP=ON"
}

if ($EnableVTK) {
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DENABLE_VTK=ON"
}

if (-Not $DisableDLLcopy) {
  $AdditionalBuildSetup = $AdditionalBuildSetup + " -DX_VCPKG_APPLOCAL_DEPS_INSTALL=ON"
}

if ($EnableCXSDKIntegration) {
  if (-Not (Test-Path "${env:CX_SDK_ROOT_64}")) {
    MyThrow("The tool requires cxSDK!")
  }

  if (-Not (Test-Path "${env:CVB}")) {
    MyThrow("The tool requires Stemmer Imaging Common Vision Blox!")
  }
}

if ($EnableGOSDKIntegration) {
  if (-Not (Test-Path "${env:GO_SDK_4}")) {
    if (-Not (Test-Path "$PSScriptRoot\..\..\GO_SDK\")) {
      MyThrow("Gocator_examples requires GO_SDK_4!")
    }
    else {
      $GOSDKPATH = "$PSScriptRoot\..\..\GO_SDK\bin"
    }
  }
  else {
    $GOSDKPATH = "${env:GO_SDK_4}\bin\win64"
  }
}

$build_folder = "$PSScriptRoot/../build_release"
if (-Not $DoNotDeleteBuildFolder) {
  Write-Host "Removing folder $build_folder" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $build_folder
}

New-Item -Path $build_folder -ItemType directory -Force | Out-Null
Set-Location $build_folder
$cmake_args = "-G `"$generator`" ${AdditionalBuildSetup} -S .."
Write-Host "Configuring CMake project" -ForegroundColor Green
Write-Host "CMake args: $cmake_args"
$proc = Start-Process -NoNewWindow -PassThru -FilePath $CMAKE_EXE -ArgumentList $cmake_args
$handle = $proc.Handle
$proc.WaitForExit()
$exitCode = $proc.ExitCode
if (-Not ($exitCode -eq 0)) {
  MyThrow("Config failed! Exited with error code $exitCode.")
}
Write-Host "Building CMake project" -ForegroundColor Green
$proc = Start-Process -NoNewWindow -PassThru -FilePath $CMAKE_EXE -ArgumentList "--build . ${selectConfig} --parallel ${NumberOfBuildWorkers} --target install"
$handle = $proc.Handle
$proc.WaitForExit()
$exitCode = $proc.ExitCode
if (-Not ($exitCode -eq 0)) {
  MyThrow("Config failed! Exited with error code $exitCode.")
}

if ($EnableGOSDKIntegration -and -Not $DisableDLLcopy) {
  Copy-Item "${GOSDKPATH}\GoSdk.dll"  ..\bin
  Copy-Item "${GOSDKPATH}\kApi.dll"   ..\bin
}

if ($EnableCXSDKIntegration -and -Not $DisableDLLcopy) {
  if (-Not $UseVCPKG) {
    $dllfolder = "${env:CX_SDK_ROOT_64}\bin"
    #$dllfolder = "${env:CX_SDK_ROOT_64}\ThirdParty\opencv-3.4.2\build_win_vc140_64_shared_vtk_static\x64\vc14\bin"
    $dllfiles = Get-ChildItem ${dllfolder}\opencv_*342.dll
    if ($dllfiles) {
      Copy-Item $dllfiles ../bin
    }
  }

  Copy-Item "${env:CX_SDK_ROOT_64}\bin\Cx3dLib_2_2.dll"                  ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\CxBaseLib_2_3.dll"                ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\CxCamLib_2_5.dll"                 ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\GenApi_MD_VC120_v3_1.dll"         ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\GCBase_MD_VC120_v3_1.dll"         ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\Log_MD_VC120_v3_1.dll"            ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\NodeMapData_MD_VC120_v3_1.dll"    ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\MathParser_MD_VC120_v3_1.dll"     ..\bin
  Copy-Item "${env:CX_SDK_ROOT_64}\bin\XmlParser_MD_VC120_v3_1.dll"      ..\bin
  Copy-Item "${env:CVB}\GenICam\bin\win64_x64\TLIs\GEVTL.cti"            ..\bin
  Copy-Item "..\data\xml\calib_bin_v2_compatibel.xml"                    ..\bin
}

Pop-Location

if (-Not $DoNotDeleteBuildFolder) {
  Write-Host "Removing folder $build_folder" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $build_folder
}

Write-Host "Build complete!" -ForegroundColor Green

if ($ForceVCPKGBuildtreesRemoval -and (-Not $UseVCPKG)) {
  Write-Host "VCPKG is not enabled, so local vcpkg buildtrees folder will not be deleted even if requested" -ForegroundColor Yellow
}

if ($UseVCPKG -and $ForceVCPKGBuildtreesRemoval) {
  $vcpkgbuildtreespath = "$vcpkg_path/buildtrees"
  Write-Host "Removing local vcpkg buildtrees folder from $vcpkgbuildtreespath" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $vcpkgbuildtreespath
}

if ($ForceVCPKGPackagesRemoval -and (-Not $UseVCPKG)) {
  Write-Host "VCPKG is not enabled, so local vcpkg packages folder will not be deleted even if requested" -ForegroundColor Yellow
}

if ($UseVCPKG -and $ForceVCPKGPackagesRemoval) {
  $vcpkgpackagespath = "$vcpkg_path/packages"
  Write-Host "Removing local vcpkg packages folder from $vcpkgpackagespath" -ForegroundColor Yellow
  Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $vcpkgpackagespath
}

if ($vcpkg_root_set_by_this_script) {
  $env:VCPKG_ROOT = $null
}

if ($vcpkg_triplet_set_by_this_script) {
  $env:VCPKG_DEFAULT_TRIPLET = $null
}

if ($vcpkg_branch_set_by_this_script) {
  Push-Location $vcpkg_path
  $git_args = "checkout -"
  Write-Host "git args: $git_args"
  $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "$git_args"
  $handle = $proc.Handle
  $proc.WaitForExit()
  $exitCode = $proc.ExitCode
  if (-Not ($exitCode -eq 0)) {
    MyThrow("Checking out previous branch failed! Exited with error code $exitCode.")
  }
  if ($VCPKGFork -ne "") {
    $git_args = "remote rm vcpkgfork"
    Write-Host "git args: $git_args"
    $proc = Start-Process -NoNewWindow -PassThru -FilePath $GIT_EXE -ArgumentList "$git_args"
    $handle = $proc.Handle
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    if (-Not ($exitCode -eq 0)) {
      MyThrow("Checking out previous branch failed! Exited with error code $exitCode.")
    }
  }
  Pop-Location
}

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
