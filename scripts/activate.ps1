[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Install-Module Microsoft.Xrm.Data.Powershell -Force -Verbose
Set-ExecutionPolicy unrestricted -Scope CurrentUser

 

#Connection
#$Conn = Connect-CrmOnline -ConnectionString "AuthType=ClientSecret;Url=${url};Timeout=02:00:00; Domain=; ClientId=${clientId};ClientSecret=${clientSecret}"
$conn = Connect-CrmOnline -ConnectionString "RequireNewInstance=True;Url=https://dharmicrm3-dev.crm8.dynamics.com;AuthType=ClientSecret;ClientId=c64ceadb-a365-4fdc-9d8b-a01ec7164dda;SkipDiscovery=True;ClientSecret=KjB7Q~llzl4NPyPRlPmVAwKabaT~VX4uTd6ya" -ConnectionTimeoutInSeconds 500 -LogWriteDirectory "C:\temp\";

if($Conn -eq $null){

 Write-Warning 'You need to Connect to CRM Organization. Use Get-CrmConnection to create it.'
 break

}

$solid = Get-CrmRecords -conn $conn -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator "eq" -FilterValue poc1 -Fields solutionid, friendlyname
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
