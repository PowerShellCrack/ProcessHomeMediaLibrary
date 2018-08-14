<#
.SYNOPSIS
    Plex API to get information and auotmate processes
.DESCRIPTION
    This script uses Plex API to get information
.LINK
    https://github.com/Arcanemagus/plex-api/wiki/Plex.tv
    https://github.com/pkkid/python-plexapi/blob/master/plexapi/library.py
#>
## Variables: Script Name and Script Paths
[string]$scriptPath = $MyInvocation.MyCommand.Definition
[string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$invokingScript = (Get-Variable -Name 'MyInvocation').Value.ScriptName

#Get paths
$LogDir = Join-Path $MainDir -ChildPath Logs
$StoredDataDir = Join-Path $MainDir -ChildPath StoredData

#generate log file
$FinalLogFileName = ($ScriptName.Trim(" ") + "_" + $RunningDate)
[string]$Logfile = Join-Path $LogDir -ChildPath "$FinalLogFileName.log"
##*===============================================
##* FUNCTIONS
##*===============================================

#Import Script extensions
. "$scriptRoot\Extensions\PlexAPI.ps1"
. "$scriptRoot\Extensions\Logging.ps1"

#===============================================
# DECLARE VARIABLES
#===============================================

## Variables: Toolkit Name
[string]$Global:PlexScriptName = 'PSPlexAPIScript'
[string]$Global:PlexScriptFriendlyName = 'PowerShell Plex API Script'

## Variables: Script Info
[version]$Global:PlexScriptVersion = [version]'1.0.8'
#generate new guid if version change: new-guid
[guid]$Global:PlexScriptGUID = '<GUID>'
[string]$plexScriptDate = '05/28/2018'
[hashtable]$plexScriptParameters = $PSBoundParameters

[string]$PlexExternalURL = 'https://plex.tv'
[string]$PlexInternalURL = '127.0.0.1'
[string]$PlexPort = '32400'

[string]$GmailUser='<username>@gmail.com'
[string]$GmailPassword='<gmail app password>'
[string]$GmailServer='smtp.gmail.com'
[int32]$GmailPort=587
[bool]$GmailUseSSL=$True

$Name = '<Plex Server Name>'
$SupportURL = '<YOUR URL>'
$IgnoreEmailDNS = '<INGNORED EMAILS>'

#===============================================
# MAIN
#===============================================
$PlexAuthToken = Get-PlexAuthToken

$sections = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken
$tvarchives = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken -CustomAddr 'library/sections/59/all'
$tvarchives | select title, studio, viewcount | Sort-Object @{e={$_.viewcount -as [int]}} -Descending

$tvkids = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken -CustomAddr 'library/sections/62/all'
$tvkids | select title, studio, viewcount | Sort-Object @{e={$_.viewcount -as [int]}} -Descending

$tvshows = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken -CustomAddr 'library/sections/47/all'
$tvshows | select title, studio, viewcount | Sort-Object @{e={$_.viewcount -as [int]}} -Descending

$tvpremium = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken -CustomAddr 'library/sections/30/all'
$tvpremium | select title, studio, viewcount | Sort-Object @{e={$_.viewcount -as [int]}} -Descending

$RecentlyAdded = Get-PlexLibraries -localPlexAddr $PlexInternalURL -PlexToken $PlexAuthToken -Section New
/library/sections/%s/all
$PlexAdmin = Invoke-WebRequest "$PlexExternalURL/users/account" -Headers @{'accept'='application/json';'X-Plex-Token'=$PlexAuthToken}

$PlexFriends = Invoke-WebRequest "$PlexExternalURL/pms/friends/all" -Headers @{'accept'='application/json';'X-Plex-Token'=$PlexAuthToken}
$PlexFriendsContent = [xml]$PlexFriends.Content
[array]$PlexUsersArray = $PlexFriendsContent.MediaContainer.User

#build email list
#filter emails that are empty or in ignored dns list
$EmailList = @()
ForEach ($User in $PlexUsersArray){
    If($User.email -and ($User.email -notmatch $IgnoreEmailDNS)){
        Write-Host $User.email
        $EmailList += $User.username + " <" + $User.email + ">"

    }
}
#build authentication credentials
$secstr = convertto-securestring -String $GmailPassword -AsPlainText -Force
$GmailAuthCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $GmailUser, $secstr

<#build html body
$body = "Dear Plex Users,<br /><br />"
$body += "<p>Recently <i>Plex on Demand</i> lost its TV content due to hardware malfunction. Movie content may also be affected.</p>"
$body += "<p>Technicians are working hard to resolve the issue. Please be patient.</p>"
$body += "<p>Sorry for any inconvience.</p><br />"
$body += "<hr/>"
$body += "<p>This is an automated message from <a href="$SupportURL">$Name</a></p>"
#>
#build html body example
$body = "To my Plex customers,<br /><br />"
$body += "<p>A few days ago, My Plex server lost the hard drive for TV content due to a device malfunction. Movie's are avaliable but with limited functionality.</p>"
$body += "<p>My new harddrive should be in today and I will begin to recover what I can. This can take some time.</p>"
$body += "<p>Dick</p><br />"
$body += "I will send an email once services has been restored. Sorry for any inconvience."

Send-MailMessage -To $EmailList -From $Gmailuser -Subject "ATTENTION: Users of [$Name]" -Body $body -BodyAsHtml -SmtpServer $GmailServer -Port $GmailPort -UseSsl -Credential $GmailAuthCreds