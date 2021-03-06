﻿<# 
 .Synopsis
  Compile Objects to Nav Container
 .Description
  Create a session to a Nav container and run Compile-NavApplicationObject
 .Parameter containerName
  Name of the container for which you want to enter a session
 .Parameter filter
  filter of the objects you want to compile (default is modified=Yes)
 .Parameter sqlCredential
  Credentials for the SQL admin user if using NavUserPassword authentication. User will be prompted if not provided
 .Example
  Compile-ObjectsToNavContainer -containerName test2 -sqlCredential (get-credential -credential 'sa')
 .Example
  Compile-ObjectsToNavContainer -containerName test2
#>
function Compile-ObjectsInNavContainer {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$containerName, 
        [string]$filter = "compiled=No", 
        [System.Management.Automation.PSCredential]$sqlCredential = $null 
    )

    $sqlCredential = Get-DefaultSqlCredential -containerName $containerName -sqlCredential $sqlCredential
    $session = Get-NavContainerSession -containerName $containerName
    Invoke-Command -Session $session -ScriptBlock { Param($filter, $sqlCredential)

        $customConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
        [xml]$customConfig = [System.IO.File]::ReadAllText($customConfigFile)
        $databaseServer = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value
        $databaseInstance = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value
        $databaseName = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseName']").Value
        if ($databaseInstance) { $databaseServer += "\$databaseInstance" }

        $params = @{}
        if ($sqlCredential) {
            $params = @{ 'Username' = $sqlCredential.UserName; 'Password' = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlCredential.Password))) }
        }
        Write-Host "Compiling objects"
        Compile-NAVApplicationObject @params -Filter $filter `
                                     -DatabaseName $databaseName `
                                     -DatabaseServer $databaseServer `
                                     -Recompile `
                                     -SynchronizeSchemaChanges Force `
                                     -NavServerName localhost `
                                     -NavServerInstance NAV `
                                     -NavServerManagementPort 7045

    } -ArgumentList $filter, $sqlCredential
    Write-Host -ForegroundColor Green "Objects successfully compiled"
}
Export-ModuleMember -Function Compile-ObjectsInNavContainer
