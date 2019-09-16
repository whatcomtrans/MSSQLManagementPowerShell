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

<# -------------------------------------------------------------------------------------------------------
 Marnie Ross Jan 2, 2015

 This script iterates through all the indexes in all the tables of a database and 
 based on the level of fragmentation of an index, performs on of the following:
          If the index fragmentation is less than 5%, it does nothing
          If the index fragmentation is between 5% and 30%, it reorganizes it
          If the index fragmentation is over 30%, it rebuilds it
 -------------------------------------------------------------------------------------------------------
#>

function Optimize-SQLIndex {
	[CmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="example")]
	Param(
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ParameterSetName="example",HelpMessage="The Server instance to check.")]
		[string] $ServerInstance,
        [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$false,ParameterSetName="example",HelpMessage="The database to check")]
        [string] $Database
	)
	Begin {
        #Put beginning stuff here
	}
	Process {
        [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        $server = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance
        $targetDB = $server.Databases[$Database]

        foreach ($table in $targetDB.Tables)
        {
            foreach($index in $table.Indexes)
            {
                    $fragmentation = $index.EnumFragmentation()
                    $averageFragmentation = $fragmentation.Rows[0].AverageFragmentation

                    if ($averageFragmentation -lt .05)
                    {
                            Write-Verbose -Message "No fragmentation...$table"  -Verbose
                            continue
                    }

                    if($averageFragmentation -ge .05 -and $averageFragmentation -lt .3)
                    {
                            Write-Verbose -Message "Reorganization...$table" -Verbose
                            $index.Reorganize()
                            continue
                    }
                     Write-Verbose -Message "Rebuild...$table" -Verbose
                     if ($PSCmdlet.ShouldProcess("Rebuild...$table")) {
                        $index.Rebuild()
                     }
            }
        }
	}
	End {
        #Put end here
	}
}


Export-ModuleMember -Function "Get-SQLLogs", "Get-SQLAgentJobStatus", "Get-SQLAgentJobLogs", "Optimize-SQLIndex"