param(
[string] $solutionName,
[string] $clientId,
[string] $clientSecret,
[string] $url
)

$Module = Get-InstalledModule -Name "Microsoft.Xrm.Data.Powershell" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if($Module -ne $null)
{
    Write-host "Module is already installed!!!!, `nModule details:";
    $Module | Format-Table -Wrap 
 }
else
{
    Write-host "Module is not installed,`nInstalling Module('Microsoft.Xrm.Data.Powershell')...";
    Install-Module -Name Microsoft.Xrm.Data.Powershell -Force -Scope CurrentUser
    Write-host "Module('Microsoft.Xrm.Data.Powershell') is installed successfully....";
}
 

#Connection
#$Conn = Connect-CrmOnline -ConnectionString "AuthType=ClientSecret;Url=${url};Timeout=02:00:00; Domain=; ClientId=${clientId};ClientSecret=${clientSecret}"
$conn = Connect-CrmOnline -ConnectionString "RequireNewInstance=True;Url=${url};AuthType= `
    ClientSecret;ClientId=${clientId};SkipDiscovery=True;ClientSecret=${clientSecret} -ConnectionTimeoutInSeconds 500 -LogWriteDirectory "C:\temp\"

if($Conn -eq $null){

 Write-Warning 'You need to Connect to CRM Organization. Use Get-CrmConnection to create it.'
 break

}

$solid = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator "eq" -FilterValue $solutionName -Fields solutionid, friendlyname
Write-Host $solid.Count
if($solid.Count -eq 1) 
{
 $SolutionComponenttype = "Workflow";
 $querySolutionComponent = New-Object Microsoft.Xrm.Sdk.Query.QueryExpression("solutioncomponent");
 $querySolutionComponent.ColumnSet = New-Object Microsoft.Xrm.Sdk.Query.ColumnSet(@('objectid'));
 $querySolutionComponent.Criteria.AddCondition('componenttype', [Microsoft.Xrm.Sdk.Query.ConditionOperator]::Equal, 29);
 $querySolutionComponent.Criteria.AddCondition('solutionid', [Microsoft.Xrm.Sdk.Query.ConditionOperator]::Equal, $solid.CrmRecords[0].solutionid);
 $responsequerySolutionComponent = $Conn.RetrieveMultiple($querySolutionComponent)
 Write-Host $responsequerySolutionComponent.Count
 Write-Host $responsequerySolutionComponent.Entities.Count
 $cloudFlowCount = 0
 $responsequerySolutionComponent.Entities | 
 ForEach-Object {
  $currentFlowRecord = Get-CrmRecord -conn $Conn -EntityLogicalName workflow -Id $_.Attributes["objectid"] -Fields name,category
   if($currentFlowRecord -ne $null){
   Write-Host $currentFlowRecord.name
   Write-Host $currentFlowRecord
   if($currentFlowRecord.category_Property.Value -eq 5){
   Write-Host "Activating Flow: " $currentFlowRecord.name
   #Flow
   Set-CrmRecordState -conn $conn -EntityLogicalName workflow -Id $currentFlowRecord.workflowid -StateCode 1 -StatusCode 2 
   $cloudFlowCount = $cloudFlowCount+1; 
   Write-Host " Done"
   }
   }
 }
}
