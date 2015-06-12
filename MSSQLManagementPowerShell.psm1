<#
.SYNOPSIS
A simple cmdlet to retrieve SQL Agent Job logs

#>
function Get-SQLAgentJobLogs {
	[CmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="ByServerInstance")]
	Param(
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="Name of server instance to connect to")]
		[String]$ServerInstance,
        [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="How many days back to display")]
		[Int32]$DaysBack = 1,
        [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="ErrorLevel less then to display")]
		[Int32]$ErrorLevel = 3
	)
	Begin {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
        $DaysBackNegative = -1 * $DaysBack
	}
	Process {
        $sqlServer = new-object ("Microsoft.SqlServer.Management.Smo.Server") $ServerInstance
        $jobServer = $sqlServer.JobServer;
        return $jobServer.ReadErrorLog() | where { ($_.ErrorLevel -lt $ErrorLevel) -and ($_.LogDate -ge $(Get-Date).AddDays($DaysBackNegative))  }
	}
	End {
        #Put end here
	}
}

<#
.SYNOPSIS
A simple cmdlet to retrieve SQL Agent Job logs

#>
function Get-SQLAgentJobStatus {
	[CmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="ByServerInstance")]
	Param(
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="Name of server instance to connect to")]
		[String]$ServerInstance,
    [Parameter(Mandatory=$false,HelpMessage="Show disabled jobs too, defaults to only showing enabled jobs")]
    [Switch] $ShowDisabledJobs,
		[Parameter(Mandatory=$false,HelpMessage="Show only failed")]
    [Switch] $ShowOnlyFailed
	)
	Begin {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
	}
	Process {
        $sqlServer = new-object ("Microsoft.SqlServer.Management.Smo.Server") $ServerInstance
        $jobServer = $sqlServer.JobServer;
        $resutls = $jobServer.Jobs | Select-Object -Property Name,IsEnabled,CurrentRunStatus,LastRunOutcome,LastRunDate,NextRunDate,Category,HasSchedule # | ft
				if ($ShowOnlyFailed) {
					$resutls = $resutls | Where-Object -Property LastRunOutcome -EQ -Value "Failed"
				}
        if ($ShowDisabledJobs) {
            return $results
        } else {
            return $results | Where-Object -Property IsEnabled -EQ -Value "True"
        }
	}
	End {
        #Put end here
	}
}

<#
.SYNOPSIS
A simple cmdlet to retrieve SQL Agent Job logs

#>
function Get-SQLLogs {
	[CmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="ByServerInstance")]
	Param(
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="Name of server instance to connect to.")]
		[String]$ServerInstance,
        [Parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true,ParameterSetName="ByServerInstance",HelpMessage="How many days back to display, defaults to 1.")]
		[Int32]$DaysBack = 1
	)
	Begin {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
        $DaysBackNegative = -1 * $DaysBack
	}
	Process {
        $sqlServer = new-object ("Microsoft.SqlServer.Management.Smo.Server") $ServerInstance
        $logs = $sqlserver.ReadErrorLog()
        return $logs | Where-Object -Property LogDate -GE -Value $((Get-Date -Hour 0 -Minute 0 -Second 0).AddDays($DaysBackNegative))
	}
	End {
        #Put end here
	}
}

Export-ModuleMember -Function "Get-SQLLogs", "Get-SQLAgentJobStatus", "Get-SQLAgentJobLogs"
