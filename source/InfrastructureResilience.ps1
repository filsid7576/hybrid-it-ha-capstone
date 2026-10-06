# ============================================================
# Infrastructure Resilience Assessment
# MSIT 5910 Capstone Project
#
# Purpose:
# Evaluate service availability and overall resilience in a
# representative hybrid IT infrastructure.
# ============================================================


# ------------------------------------------------------------
# Function: Get-ServiceAvailability
#
# Determines application availability based on the state of
# the primary and secondary application servers.
# ------------------------------------------------------------

function Get-ServiceAvailability {

    param(
        [bool]$PrimaryOnline,
        [bool]$SecondaryOnline
    )

    # The application remains available if at least one
    # application server is operational.
    if ($PrimaryOnline -or $SecondaryOnline) {
        return "AVAILABLE"
    }

    # If both application servers are offline, the service
    # is no longer available.
    return "UNAVAILABLE"
}


# ------------------------------------------------------------
# Function: Get-ResilienceStatus
#
# Determines the overall resilience state of the environment.
#
# HEALTHY:
#   Production services, redundancy, replication, and backup
#   are operating normally.
#
# DEGRADED:
#   Production remains available, but redundancy or recovery
#   capability has been reduced.
#
# CRITICAL:
#   A required production service is unavailable.
# ------------------------------------------------------------

function Get-ResilienceStatus {

    param(
        [string]$ApplicationStatus,
        [string]$DNSStatus,
        [string]$IdentityStatus,
        [string]$ReplicationStatus,
        [string]$BackupStatus,
        [bool]$RedundancyLost = $false
    )

    # A failure of the application or one of its critical
    # dependencies creates a critical condition.
    if (
        $ApplicationStatus -eq "UNAVAILABLE" -or
        $DNSStatus -eq "UNAVAILABLE" -or
        $IdentityStatus -eq "UNAVAILABLE"
    ) {
        return "CRITICAL"
    }

    # Production is still available, but the environment
    # has lost redundancy or part of its recovery capability.
    if (
        $RedundancyLost -or
        $ReplicationStatus -ne "PASS" -or
        $BackupStatus -ne "PASS"
    ) {
        return "DEGRADED"
    }

    # No service, redundancy, or recovery problems detected.
    return "HEALTHY"
}


# ------------------------------------------------------------
# Function: Invoke-ResilienceAssessment
#
# Combines the individual infrastructure states and produces
# a complete service and resilience assessment.
# ------------------------------------------------------------

function Invoke-ResilienceAssessment {

    param(
        [bool]$PrimaryOnline = $true,
        [bool]$SecondaryOnline = $true,
        [string]$DNSStatus = "AVAILABLE",
        [string]$IdentityStatus = "AVAILABLE",
        [string]$ReplicationStatus = "PASS",
        [string]$BackupStatus = "PASS"
    )

    # Determine whether the application is still available.
    $applicationStatus = Get-ServiceAvailability `
        -PrimaryOnline $PrimaryOnline `
        -SecondaryOnline $SecondaryOnline

    # Redundancy is considered lost whenever both application
    # servers are not simultaneously operational.
    $redundancyLost = -not ($PrimaryOnline -and $SecondaryOnline)

    # Calculate the overall resilience status.
    $overallStatus = Get-ResilienceStatus `
        -ApplicationStatus $applicationStatus `
        -DNSStatus $DNSStatus `
        -IdentityStatus $IdentityStatus `
        -ReplicationStatus $ReplicationStatus `
        -BackupStatus $BackupStatus `
        -RedundancyLost $redundancyLost

    # Return the complete assessment as a PowerShell object.
    [PSCustomObject]@{
        PrimaryServer   = if ($PrimaryOnline) {
            "ONLINE"
        }
        else {
            "OFFLINE"
        }

        SecondaryServer = if ($SecondaryOnline) {
            "ONLINE"
        }
        else {
            "OFFLINE"
        }

        Application   = $applicationStatus
        DNS           = $DNSStatus
        Identity      = $IdentityStatus
        Replication   = $ReplicationStatus
        Backup        = $BackupStatus
        OverallStatus = $overallStatus
    }
}