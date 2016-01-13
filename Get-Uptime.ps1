
<#	
	.NOTES
	===========================================================================
	 Created on:   	2016-01-11 08:28
	 Created by:   	Arash Nabi
	 Mail:          arash@nabi.nu 	
	===========================================================================
	.SYNOPSIS
		A brief description of the Get-UpTime function.
	
	.DESCRIPTION
		Get uptime of the remote server. This is 2016-January Scripting Games Puzzle
	    For more info please visist: http://powershell.org/wp/2016/01/02/january-2016-scripting-games-puzzle/
	.EXAMPLE
		PS C:\> Get-UpTime -ComputerName 
	    PS C:\> $value1 | Get-UpTime
#>

function Get-UpTime
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true)]
		$ComputerName = $env:COMPUTERNAME
	)
	
	Process
	{
		try
		{
            $AllObj = @()
			foreach ($PC in $ComputerName)
			{
				$params = @{
					'ComputerName' = "$PC"
				}
                $PingComputer = Test-Connection -ComputerName $PC -ErrorAction SilentlyContinue
				if (-not ($PingComputer))
				{
					$params.Add("Status", "Offline")
					Write-Warning "$PC is Offline"
				}
				# 
				if ($PingComputer)
				{
					$objOption = New-CimSessionOption -Protocol Dcom -ErrorAction SilentlyContinue
					$objSession = New-CimSession -ComputerName $PC -SessionOption $objOption -ErrorAction SilentlyContinue
					if ($objSession)
					{
						$LastBootUpTime = Get-CimInstance -CimSession $objSession -Namespace ROOT/cimv2 -ClassName Win32_OperatingSystem | select LastBootUpTime
						if ($LastBootUpTime)
						{
							$upTime = New-TimeSpan -Start $($LastBootUpTime.LastBootUpTime) -End (get-date)
							$params.add("StartTime", "$($LastBootUpTime.LastBootUpTime)")
							$params.Add("Status", "OK")
							$params.Add("UpTime (Days)", "$($upTime.Days)")
						}
						
						if ($upTime -gt 30)
						{
							$params.add("MightNeedPatched", "Yes")
						}
						else
						{
							$params.add("MightNeedPatched", "No")
						}
					}
					else
					{
						$params.Add("Status", "Error")
					}
				}
				
				$objresult = New-Object psobject -Property $params
				$AllObj += $objresult
			}
			
		}
		
		catch [System.Net.WebException], [System.Exception]
		{
			$errorMessage = $_.Exception.Message
            Write-Warning -Message $errorMessage

		}
		finally
		{
			$AllObj | Select-Object ComputerName, StartTime, 'Uptime (Days)', Status, MightNeedPatched | Format-Table -AutoSize
		}
	}
	
}


	