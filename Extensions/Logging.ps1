Function Write-Log {
<#
.SYNOPSIS
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
.DESCRIPTION
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.
.PARAMETER Message
	The message to write to the log file or output to the console.
.PARAMETER Severity
	Defines message type. When writing to console or CMTrace.exe log format, it allows highlighting of message type.
	Options: 0,1,4,5 = Information (default), 2 = Warning (highlighted in yellow), 3 = Error (highlighted in red)
.PARAMETER Source
	The source of the message being logged.
.PARAMETER LogFile
	Set the log and path of the log file.
.PARAMETER WriteHost
	Write the log message to the console.
    The Severity sets the color: 
.PARAMETER ContinueOnError
	Suppress writing log message to console on failure to write message to log file. Default is: $true.
.PARAMETER PassThru
	Return the message that was passed to the function
.EXAMPLE
	Write-Log -Message "Installing patch MS15-031" -Source 'Add-Patch' -LogType 'CMTrace'
.EXAMPLE
	Write-Log -Message "Script is running on Windows 8" -Source 'Test-ValidOS' -LogType 'Legacy'
.NOTES
    Taken from http://psappdeploytoolkit.com
.LINK
	
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyCollection()]
		[Alias('Text')]
		[string[]]$Message,
        [Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
        [Alias('Prefix')]
        [string]$MsgPrefix,
        [Parameter(Mandatory=$false,Position=2)]
		[ValidateRange(0,5)]
		[int16]$Severity = 1,
		[Parameter(Mandatory=$false,Position=3)]
		[ValidateNotNull()]
		[string]$Source = '',
        [Parameter(Mandatory=$false,Position=4)]
		[ValidateNotNullorEmpty()]
		[switch]$WriteHost,
        [Parameter(Mandatory=$false,Position=5)]
		[ValidateNotNullorEmpty()]
        [switch]$NewLine,
        [Parameter(Mandatory=$false,Position=6)]
		[ValidateNotNullorEmpty()]
		[string]$LogFile = $global:LogFilePath,
		[Parameter(Mandatory=$false,Position=7)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true,
		[Parameter(Mandatory=$false,Position=8)]
		[switch]$PassThru = $false
        
    )
    Begin {
		## Get the name of this function
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		
		## Logging Variables
		#  Log file date/time
		[string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
		[string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
		[int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
		[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
		#  Get the file name of the source script
		Try {
			If ($script:MyInvocation.Value.ScriptName) {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
			}
			Else {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
			}
		}
		Catch {
			$ScriptSource = ''
		}

        ## Create script block for generating CMTrace.exe compatible log entry
		[scriptblock]$CMTraceLogString = {
			Param (
				[string]$lMessage,
				[string]$lSource,
				[int16]$lSeverity
			)
			"<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
		}
		
		## Create script block for writing log entry to the console
		[scriptblock]$WriteLogLineToHost = {
			Param (
				[string]$lTextLogLine,
				[int16]$lSeverity
			)
			If ($WriteHost) {
				#  Only output using color options if running in a host which supports colors.
				If ($Host.UI.RawUI.ForegroundColor) {
					Switch ($lSeverity) {
                        5 { Write-Host -Object $lTextLogLine -ForegroundColor 'Gray' -BackgroundColor 'Black'}
                        4 { Write-Host -Object $lTextLogLine -ForegroundColor 'Cyan' -BackgroundColor 'Black'}
						3 { Write-Host -Object $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black'}
						2 { Write-Host -Object $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black'}
						1 { Write-Host -Object $lTextLogLine  -ForegroundColor 'White' -BackgroundColor 'Black'}
                        0 { Write-Host -Object $lTextLogLine -ForegroundColor 'Green' -BackgroundColor 'Black'}
					}
				}
				#  If executing "powershell.exe -File <filename>.ps1 > log.txt", then all the Write-Host calls are converted to Write-Output calls so that they are included in the text log.
				Else {
					Write-Output -InputObject $lTextLogLine
				}
			}
		}

        ## Exit function if logging to file is disabled and logging to console host is disabled
		If (($DisableLogging) -and (-not $WriteHost)) { [boolean]$DisableLogging = $true; Return }
		## Exit Begin block if logging is disabled
		If ($DisableLogging) { Return }

        ## Dis-assemble the Log file argument to get directory and name
		[string]$LogFileDirectory = Split-Path -Path $LogFile -Parent
        [string]$LogFileName = Split-Path -Path $LogFile -Leaf

        ## Create the directory where the log file will be saved
		If (-not (Test-Path -LiteralPath $LogFileDirectory -PathType 'Container')) {
			Try {
				$null = New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop'
			}
			Catch {
				[boolean]$DisableLogging = $true
				#  If error creating directory, write message to console
				If (-not $ContinueOnError) {
					Write-Host -Object "[$LogDate $LogTime] [${CmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `n$(Resolve-Error)" -ForegroundColor 'Red'
				}
				Return
			}
		}
		
		## Assemble the fully qualified path to the log file
		[string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName

    }
	Process {
        ## Exit function if logging is disabled
		If ($DisableLogging) { Return }

        Switch ($lSeverity)
            {
                5 { $Severity = 1 }
                4 { $Severity = 1 }
				3 { $Severity = 3 }
				2 { $Severity = 2 }
				1 { $Severity = 1 }
                0 { $Severity = 1 }
            }
        
        ## If the message is not $null or empty, create the log entry for the different logging methods
		[string]$CMTraceMsg = ''
		[string]$ConsoleLogLine = ''
		[string]$LegacyTextLogLine = ''

		#  Create the CMTrace log message
	
		#  Create a Console and Legacy "text" log entry
		[string]$LegacyMsg = "[$LogDate $LogTime]"
		If ($MsgPrefix) {
			[string]$ConsoleLogLine = "$LegacyMsg [$MsgPrefix] :: $Message"
		}
		Else {
			[string]$ConsoleLogLine = "$LegacyMsg :: $Message"
		}

        ## Execute script block to create the CMTrace.exe compatible log entry
		[string]$CMTraceLogLine = & $CMTraceLogString -lMessage $Message -lSource $Source -lSeverity $Severity
			
		## 
		[string]$LogLine = $CMTraceLogLine
			
        Try {
			$LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
		}
		Catch {
			If (-not $ContinueOnError) {
				Write-Host -Object "[$LogDate $LogTime] [$ScriptSection] [${CmdletName}] :: Failed to write message [$Message] to the log file [$LogFilePath]." -ForegroundColor 'Red'
			}
		}

        ## Execute script block to write the log entry to the console if $WriteHost is $true
		& $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
    }
	End {
        If ($PassThru) { Write-Output -InputObject $Message }
    }
}


Function Pad-PrefixOutput {

    Param (
    [Parameter(Mandatory=$true)]
    [string]$Prefix,
    [switch]$UpperCase,
    [int32]$MaxPad = 20
    )

    If($Prefix.Length -ne $MaxPad){
        $addspace = $MaxPad - $Prefix.Length
        $newPrefix = $Prefix + (' ' * $addspace)
    }Else{
        $newPrefix = $Prefix
    }

    If($UpperCase){
        return $newPrefix.ToUpper()
    }Else{
        return $newPrefix
    }
}


Function Pad-Counter {
    Param (
    [string]$Number,
    [int32]$MaxPad
    )

    return $Number.PadLeft($MaxPad,"0")
    
}