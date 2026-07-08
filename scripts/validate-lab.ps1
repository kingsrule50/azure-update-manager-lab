param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$SubscriptionId,
    [string]$TenantId
)

Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId | Out-Null

# Adapted from the AUM Lab SOP: targets the existing Lab 1 VMs.
# NOTE: SOP referenced Get-AzVMPatchAssessmentResult, which does not exist in
# Az.Compute. The supported method is Get-AzVM -Status -> PatchStatus.
$vms = @("DC01", "FS01")
$results = @()
$allPass = $true

Write-Host "`n=== Azure Update Manager Compliance Validation ===" -ForegroundColor Cyan

foreach ($vm in $vms) {
    $assessment = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $vm -Status `
        -ErrorAction SilentlyContinue).PatchStatus.AvailablePatchSummary

    # PASS = assessment ran successfully AND no Critical/Security patches missing.
    $compliant = $assessment.Status -eq "Succeeded" -and $assessment.CriticalAndSecurityPatchCount -eq 0
    $status = if ($compliant) { "PASS" } else { "FAIL" }
    if (-not $compliant) { $allPass = $false }

    Write-Host "[$status] $vm -- Critical missing: $($assessment.CriticalAndSecurityPatchCount) | Other: $($assessment.OtherPatchCount) | Status: $($assessment.Status)"

    $results += [PSCustomObject]@{
        VMName                   = $vm
        AssessmentStatus         = $assessment.Status
        CriticalAndSecurityCount = $assessment.CriticalAndSecurityPatchCount
        OtherPatchCount          = $assessment.OtherPatchCount
        LastAssessmentTime       = $assessment.StartTime
        Compliant                = $compliant
        Result                   = $status
    }
}

Write-Host ""
Write-Host "Overall: $(if ($allPass) {"ALL PASS"} else {"FAILURES DETECTED"})" `
    -ForegroundColor $(if ($allPass) {"Green"} else {"Red"})

# Export JSON -- feeds SIEM, ServiceNow, or compliance dashboard in production
$report = @{
    GeneratedAt   = (Get-Date -Format "o")
    ResourceGroup = $ResourceGroup
    VMs           = $results
}

$report | ConvertTo-Json -Depth 5 | Out-File "./aum-compliance-report.json" -Encoding UTF8
Write-Host "Report exported: aum-compliance-report.json" -ForegroundColor Cyan
