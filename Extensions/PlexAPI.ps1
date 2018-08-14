Function Get-PlexVideo {
    [CmdletBinding(DefaultParameterSetName="VideoMeta")]
    Param(
    [Parameter(Mandatory=$True,Position=1)]
        [string]$PlexServer,

    [Parameter(Mandatory=$False)]
    [ValidateSet('Watched','Unwatched','All')]
    [string]$ViewedStatus = 'All',

    [Parameter(Mandatory=$False)]
    [string]$VideoName,

    [Parameter(Mandatory=$False)]
    [string]$ShowName,

    [Parameter(Mandatory=$False, ParameterSetName="VideoMeta")]
    [ValidateSet('TV','Movies')]
    [string]$VideoType,

    [Parameter(Mandatory=$False, ParameterSetName="TVMeta")]
    [int]$SeriesNumber,

    [Parameter(Mandatory=$False, ParameterSetName="TVMeta")]
    [int]$EpisodeNumber
    )

    If($PlexServer) #User specified their Plex Server
        {
        $SearchResult = @()
    
    
        Switch ($ViewedStatus.ToLower())
            {
                'all' {$moviesearchtrail = '/search?type=1&sort=titleSort:asc' ; $episodesearchtrail = '/all?type=4&sort=index:asc'}
                'watched' {$moviesearchtrail = '/search?type=1unwatched=0&sort=titleSort:asc' ; $episodesearchtrail = '/all?type=4&unwatched=0&sort=index:asc'}
                'unwatched' {$moviesearchtrail = '/all?type=1&unwatched=1&sort=titleSort:asc' ; $episodesearchtrail = '/all?type=4&unwatched=1&sort=index:asc'}
            }


        If ($EpisodeNumber) {$episodesearchtrail =$episodesearchtrail + "&index=" + $EpisodeNumber}


        If ($VideoName -and (!$EpisodeNumber -or !$SeriesNumber -or !$ShowName)) #Video Name specified as a parameter, no TVMeta parameters defined
            {$moviesearchtrail = $moviesearchtrail + "&title=" + ($VideoName -replace " ","%20"); $episodesearchtrail = $episodesearchtrail + "&title=" + ($VideoName -replace " ","%20")}


            $SectionsBaseURL = "http://" + $PlexServer + ":32400/library/sections"
            $Sections = New-Object System.Xml.XmlDocument
            $Sections.Load($SectionsBaseURL)
            $SectionsDirectories = $Sections.MediaContainer.Directory
        

            If (!$VideoType)
                {#No VideoType or VideoName specified - Global Search
              
              

                  ForEach ($Directory in $SectionsDirectories) #Each directory in section listing...
                    {
                    If ($Directory.Type -eq 'movie') #... where it's a movie
                        {
                        $ChosenLibraryURL = $SectionsBaseURL+ "/" + $Directory.key + $moviesearchtrail #List 'movies' against the section
                        $ChosenLibrary = New-Object System.Xml.XmlDocument
                        $ChosenLibrary.Load($ChosenLibraryURL)
                        ForEach ($Video in ($ChosenLibrary.MediaContainer.Video)) {$SearchResult += $Video}
                        }#Close section type -eq Movie check if block

                    ElseIf ($Directory.Type -eq 'show') #... where it's a show
                        {
                        $ChosenLibraryURL = $SectionsBaseURL+ "/" + $Directory.key + $episodesearchtrail #Perform an 'show' search against the section
                        $ChosenLibrary = New-Object System.Xml.XmlDocument
                        $ChosenLibrary.Load($ChosenLibraryURL)
                        ForEach ($Video in ($ChosenLibrary.MediaContainer.Video)) {$SearchResult += $Video}
                        } #Close section type -eq show check if block
                    } #Close directory in section loop

        


            
                }#Close ElseIf No VideoType or VideoName specified 

            Else #VideoType initialised
                    {
            

                    If ($VideoType.ToLower() -eq "movies") #No VideoName, VideoType -eq movie
                         {
                         ForEach ($Directory in $SectionsDirectories) #Each directory in section listing...
                            {
                            If ($Directory.Type -eq 'movie') #... where it's a movie
                                {
                                $ChosenLibraryURL = $SectionsBaseURL+ "/" + $Directory.key + $moviesearchtrail #List 'movies' against the section
                                $ChosenLibrary = New-Object System.Xml.XmlDocument
                                $ChosenLibrary.Load($ChosenLibraryURL)
                                ForEach ($Video in ($ChosenLibrary.MediaContainer.Video)) {$SearchResult += $Video}
                                }#Close section type -eq Movie check if block
                            } #Close directory in section loop
            
                        }# Close No VideoName, VideoType -eq Movie ElseIf block
        
                     ElseIf ($VideoType.ToLower() -eq "tv") #No VideoName, VideoType -eq tv
                        {
                        ForEach ($Directory in $SectionsDirectories) #Each directory in section listing...
                            {
                            If ($Directory.Type -eq 'show') #... where it's a show
                                {
                                $ChosenLibraryURL = $SectionsBaseURL+ "/" + $Directory.key + $episodesearchtrail #Perform an 'show' search against the section
                                $ChosenLibrary = New-Object System.Xml.XmlDocument
                                $ChosenLibrary.Load($ChosenLibraryURL)
                                ForEach ($Video in ($ChosenLibrary.MediaContainer.Video)) {$SearchResult += $Video}
                                } #Close section type -eq show check if block
                            } #Close directory in section loop
           
                        } # Close No VideoName, VideoType -eq TV If block


                    }#Close loop where VideoType initialised


        
        If ($SeriesNumber) {$SearchResult = $SearchResult | Where {$_.parentIndex -eq $SeriesNumber}}
        If ($VideoName -and ($EpisodeNumber -or $SeriesNumber -or $ShowName)){$SearchResult = $SearchResult | Where {$_.title -match $VideoName} }
        If ($ShowName) {$SearchResult = $SearchResult | Where {($_.grandparentTitle -match $ShowName) -and ($_.Type -eq 'episode')}}
   

        Return $SearchResult
        }

    Else {Write-Error -Message "No Plex Server specified"} #User did not specify their Plex Server
}


Function Get-PlexShow{
    Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PlexServer,

    [Parameter(Mandatory=$False)]
    [string]$ShowName,

    [Parameter(Mandatory=$False)]
    [ValidateSet('Part-Watched','Watched','Unwatched','All')]
    [string]$ViewedStatus = 'All'
    )

    If($PlexServer) #User specified their Plex Server
        {
        $SearchResult = @()
    

        Switch ($ViewedStatus.ToLower())
            {
                'all' {$showsearchtrail = '/all?type=2&sort=titleSort:asc'}
                'watched' {$showsearchtrail = '/all?type=2&sort=titleSort:asc'}
                'part-watched' {$showsearchtrail = '/all?type=2&sort=titleSort:asc'}
                'unwatched' {$showsearchtrail = '/all?type=2&unwatchedLeaves=1&sort=titleSort:asc'}
            }

    If ($ShowName) {$showsearchtrail = $showsearchtrail + "&title=" + ($ShowName -replace " ","%20")}

            $SectionsBaseURL = "http://" + $PlexServer + ":32400/library/sections"
            $Sections = New-Object System.Xml.XmlDocument
            $Sections.Load($SectionsBaseURL)
            $SectionsDirectories = $Sections.MediaContainer.Directory

                    ForEach ($Directory in $SectionsDirectories) #Each directory in section listing...
                        {


                        If ($Directory.Type -eq 'show') #... where it's of type show
                            {
                            $ChosenLibraryURL = $SectionsBaseURL+ "/" + $Directory.key + $showsearchtrail #Perform an 'show' search against the section
                            $ChosenLibrary = New-Object System.Xml.XmlDocument
                            $ChosenLibrary.Load($ChosenLibraryURL)
                            ForEach ($Show in ($ChosenLibrary.MediaContainer.Directory)) {$SearchResult += $Show}
                            } #Close section type -eq show check if block
                        } #Close directory in section loop
            

    If ($ViewedStatus.ToLower() -eq 'part-watched'){$SearchResult = $SearchResult | Where {($_.viewedLeafCount -ne 0) -and ($_.leafCount -ne $_.viewedLeafCount)} }     
    ElseIf ($ViewedStatus.ToLower() -eq 'watched'){$SearchResult = $SearchResult | Where {$_.leafCount -eq $_.viewedLeafCount} }            
    Return $SearchResult
    }

    Else {Write-Error -Message "No Plex Server specified"} #User did not specify their Plex Server
}



Function Set-PlexViewedStatus{
    Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PlexServer,

    [Parameter(Mandatory=$True,ValueFromPipeline=$true,Position=0)]
    [PSobject[]]$Key,

    [Parameter(Mandatory=$True)]
    [ValidateSet('Watched','Unwatched')]
    [string]$ViewedStatus
    )

    BEGIN {
    If ($ViewedStatus.ToLower() -eq "watched") {$ScrobbleAction = "scrobble"}
    Else {$ScrobbleAction = "unscrobble"}
    }

    PROCESS {
    ForEach ($ObjectKey in $Key)
    {
    If ($ObjectKey.GetType().Name -eq 'XmlElement') 
        {
        If ($ObjectKey.ratingKey){$ResolvedObjectKey = $ObjectKey.ratingKey}
        }

    ElseIf ($ObjectKey.GetType().Name -eq 'String')
        {
        $ResolvedObjectKey = $ObjectKey
        }

    $ScrobbleURL = "http://"+ $PlexServer + ":32400/:/" + $ScrobbleAction + "?key=" + $ResolvedObjectKey + "&identifier=com.plexapp.plugins.library"
    $InvokeScrobbleAction = Invoke-WebRequest($ScrobbleURL)
    }


    }
    END {}
}



Function Get-PlexAuthToken {
    <#
    .SYNOPSIS
    Retuens Authentication token from Plex

    .DESCRIPTION
    This script will login into https://plex.tv/users/sign_in.xml and return the user authentication token
    Your Plex user account and password is used either by credential variable of direct

    .parameter credential
    Use these credentials. 
    NOTE: If this parameter is null, or if EITHER the username OR password in the credential is an empty string, use a trusted connection / integrated security instead
    
    .parameter username
    Use this username.
    NOTE: If EITHER the username OR password is null or an empty string, use a trusted connection / integrated security instead
    
    .parameter password
    Use this password.
    NOTE: If EITHER the username OR password is null or an empty string, use a trusted connection / integrated security instead

    .EXAMPLE
    Get-PlexAuthToken -PlexCreds {Get-Credential}

    .EXAMPLE
    $StoredCredentials = Get-Credential
    Get-PlexAuthToken -PlexCreds $StoredCredentials

    .EXAMPLE
    $StoredCredentials = Get-Credential
    Get-PlexAuthToken -PlexUsername 'plexuser' -PlexPassword 'mypassword'

    .NOTES
    https://github.com/sup3rmark/PlexCheck/blob/master/PlexCheck.ps1
    To find your token, check here: https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token

    #>
    [cmdletbinding(DefaultParameterSetName="NoCredential")] param(
        [parameter(Position=0 , Mandatory=$false)]        
        [string]$PlexUrl = 'https://plex.tv/users/sign_in.xml',

        # Do not give a type, so that this may be $null or a PSCredential object
        # NOTE that there is no such thing as a null PSCredential object - the closest thing is [PSCredential]::Empty
        [Parameter(Mandatory=$true, ParameterSetName="Credential")]
        # [System.Management.Automation.PSCredential]
        [AllowNull()] $PlexCreds,

        [Parameter(Mandatory=$true, ParameterSetName="UserPass")]
        [AllowEmptyString()] [string] $PlexUsername,

        # Do not give a type, so that this might be a string or a SecureString
        [Parameter(Mandatory=$true, ParameterSetName="UserPass")]
        [AllowNull()] $PlexPassword
    )

    Begin {
        If ($PlexCreds.UserName) {
            # Note that we assume this is a PSCredential object, but it could be anything with a string UserName property and a string or SecureString Password property
            $tmpPass = $PlexCreds.Password
            if ($tmpPass.GetType().FullName -ne "System.Security.SecureString") {
                $GetCreds = Get-Credential
            }Else{
                 $GetCreds = $PlexCred
            }
        }
        ElseIf ($PlexUsername -and $PlexPassword) {
            $secstr = New-Object -TypeName System.Security.SecureString
            $PlexPassword.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
            $GetCreds = New-Object -typename System.Management.Automation.PSCredential -ArgumentList $PlexUsername, $secstr
        }
        Else{
            $GetCreds = Get-Credential
        }
        $tmpUser = $GetCreds.UserName
    }
    Process{

        #'Get Credentials, convert to Base64 for basic HTML Authentication
        Try
        {
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $GetCreds.GetNetworkCredential().UserName,$GetCreds.GetNetworkCredential().Password)))
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Log ("Failed to convert credentials. Error message {1}" -f $ErrorMessage) -Severity 3 -Source ${CmdletName} -WriteHost
            break;
        }

        #'Get Auth Token
        Try
        {
            [array]$data =  Invoke-RestMethod `
                            -Uri $PlexUrl `
                            -Method POST `
                            -headers   @{
                                            'Authorization'=("Basic {0}" -f $base64AuthInfo);
                                            'X-Plex-Client-Identifier'=$Global:PlexScriptGUID.Guid;
                                            'X-Plex-Product'=$Global:PlexScriptFriendlyName;
                                            'X-Plex-Platform'='Windows';
                                            'X-Plex-Platform-Version'=(Get-Host).Version.ToString();
                                            'X-Plex-Device'=$env:COMPUTERNAME
                                            'X-Plex-Version'=$Global:PlexScriptVersion.ToString();
                                            'X-Plex-Username'=$GetCreds.GetNetworkCredential().UserName;
                                        }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Log ("Failed to authenticated to [{0}] using [{1}]. Error message [{2}]" -f $PlexUrl,$GetCreds.GetNetworkCredential().UserName,$ErrorMessage) -Severity 3 -Source ${CmdletName} -WriteHost
            break;
        }
    }
    End {
        return $data.user.authenticationToken
    }
}

Function Get-PlexRecentlyAddedMovies {
    <#
    .SYNOPSIS
    Pull a list of recently-added movies from Plex and send a listing via email

    .DESCRIPTION
    This script will send to a specified recipient a list of movies added to Plex in the past 7 days (or as specified).
    This list will include information pulled dynamically from OMDBapi.com, the Open Movie Database.

    .PARAMETERS
    See param block for descriptions of available parameters

    .EXAMPLE
    PS C:\>PlexCheck.ps1 -Token xx11xx11xx1100xx0x01

    .EXAMPLE
    PS C:\>PlexCheck.ps1 -Token xx11xx11xx1100xx0x01 -Url 10.0.0.100 -Port 12345 -Days 14 -EmailTo test@test.com -Cred StoredCredential

    .NOTES
    https://github.com/sup3rmark/PlexCheck/blob/master/PlexCheck.ps1

    To add credentials open up Control Panel>User Accounts>Credential Manager and click "Add a gereric credential". 
    The "Internet or network address" field will be the Name required by the Cred param (default: "PlexCheck").

    Requires StoredCredential.psm1 from https://gist.github.com/toburger/2947424, which in turn was adapted from
    http://stackoverflow.com/questions/7162604/get-cached-credentials-in-powershell-from-windows-7-credential-manager

    #>
    param(
        # Required: specify your Plex Token
        #   To find your token, check here: https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
        [Parameter(Mandatory = $true)]
        [string]$Token,

        # Optionally specify IP of the server we want to connect to
        [string]$Url = 'http://127.0.0.1',

        # Optionally define a custom port
        [int]$Port = '32400',

        # Optionally specify a number of days back to report
        [int]$Days = 7,

        # Specify whether to send email or just return list
        [switch]$SendEmail,

        # Optionally define the address to send the report to
        # If not otherwise specified, send to the From address
        [string]$EmailTo = 'default',

        # Specify the SMTP server address (if not gmail)
        # Assumes SSL, because security!
        [string]$SMTPserver = 'smtp.gmail.com',

        # Specify the SMTP server's SSL port
        [int]$SMTPport = '587',

        # Specify the name used for the Credential Manager entry
        [string]$Cred = 'PlexCheck',

        # Specify the Library ID of any libraries you'd like to exclude
        [int[]]$ExcludeLib = 0,

        # Specify whether to prevent sending email if there are no additions
        [switch]$PreventSendingEmptyList,

        # Specify whether to omit the Plex Server version number from the email
        [switch]$OmitVersionNumber


    )

    #region Declarations
    $epoch = Get-Date '1/1/1970'
    $imgPlex = "http://i.imgur.com/RyX9y3A.jpg"
    #endregion

    $response = Invoke-WebRequest "$url`:$port/library/recentlyAdded/?X-Plex-Token=$Token" -Headers @{"accept"="application/json"}
    $jsonlibrary = ConvertFrom-JSON $response.Content

    # Grab those libraries!
    $movies = $jsonLibrary.MediaContainer.Metadata |
        Where-Object {$_.type -eq 'movie' -AND $_.addedAt -gt (Get-Date (Get-Date).AddDays(-$days) -UFormat "%s")} |
        Select-Object * |
        Sort-Object addedAt

    $tvShows = $jsonLibrary.MediaContainer.Metadata |
        Where-Object {$_.type -eq 'season' -AND $_.addedAt -gt (Get-Date (Get-Date).AddDays(-$days) -UFormat "%s")} |
        Group-Object parentTitle

    # Initialize the counters and lists
    $movieCount = 0
    $movieList = "<h1>Movies:</h1><br/><br/>"
    $movieList += "<table style=`"width:100%`">"
    $tvCount = 0
    $tvList = "<h1>TV Seasons:</h1><br/><br/>"
    $tvList += "<table style=`"width:100%`">"

    if ($($movies | Measure-Object).count -gt 0) {
        foreach ($movie in $movies) {
            # Make sure the movie's not in an excluded library
            if ($movie.librarySectionID -notin $ExcludeLib){
                $movieCount++

                # Retrieve movie info from the Open Movie Database
                $omdbURL = "omdbapi.com/?t=$($movie.title)&y=$($movie.year)&r=JSON"
                $omdbResponse = ConvertFrom-JSON (Invoke-WebRequest $omdbURL).content

                # If there was no result, try searching for the previous year (OMDB/The Movie Database quirkiness)
                if ($omdbResponse.Response -eq "False") {
                    $omdbURL = "omdbapi.com/?t=$($movie.title)&y=$($($movie.year)-1)&r=JSON"
                    $omdbResponse = ConvertFrom-JSON (Invoke-WebRequest $omdbURL).content
                }

                # If there was STILL no result, try searching for the *next* year
                if ($omdbResponse.Response -eq "False") {
                    $omdbURL = "omdbapi.com/?t=$($movie.title)&y=$($($movie.year)+1)&r=JSON"
                    $omdbResponse = ConvertFrom-JSON (Invoke-WebRequest $omdbURL).content
                }

                if ($omdbResponse.Response -eq "True") {
                    if ($omdbResponse.Poster -eq "N/A") {
                        # If the poster was unavailable, substitute a Plex logo
                        $imgURL = $imgPlex
                        $imgHeight = "150"
                    } else {
                        $imgURL = $omdbResponse.Poster
                        $imgHeight = "234"
                    }
                    $movieList += "<tr><td><img src=`"$imgURL`" height=$($imgHeight)px width=150px></td>"
                    $movieList += "<td><li><a href=`"http://www.imdb.com/title/$($omdbResponse.imdbID)/`">$($movie.title)</a> ($($movie.year))</li>"
                    $movieList += "<ul><li><i>Genre:</i> $($omdbResponse.Genre)</li>"
                    $movieList += "<li><i>Rating:</i> $($omdbResponse.Rated)</li>"
                    $movieList += "<li><i>Runtime:</i> $($omdbResponse.Runtime)</li>"
                    $movieList += "<li><i>Director:</i> $($omdbResponse.Director)</li>"
                    $movieList += "<li><i>Plot:</i> $($omdbResponse.Plot)</li>"
                    $movieList += "<li><i>IMDB rating:</i> $($omdbResponse.imdbRating)/10</li>"
                    $movieList += "<li><i>Added:</i> $(Get-Date $epoch.AddSeconds($movie.addedAt) -Format 'MMMM d')</li></ul></td>"
                }
                else {
                    # If the movie couldn't be found in the DB even with the one-year buffer, fail gracefully
                    $movieList += "<td><img src=`"$imgPlex`" height=150px width=150px></td><td><li>$($movie.title)</a> ($($movie.year)) - no additional information</li></td>"
                }
                $movieList += "</tr>"
            }
        }
        $movieList += "</table><br/><br/>"
    }

    if ($($tvShows | Measure-Object).Count -gt 0) {
        foreach ($show in $tvShows) {
            # Due to how shows are nested, gotta dig deep to get the librarySectionID
            if ($($show.group) -is [array]) {
                [int]$section = $($show.Group)[0].librarySectionID
            } else {
                [int]$section = $($show.Group).librarySectionID
            }

            # Make sure the media we're parsing isn't in an excluded library
            if (-not($ExcludeLib.Contains($section))){
                 # Count it!
                 $tvCount++

                 # Retrieve show info from the Open Movie Database
                 $omdbURL = "omdbapi.com/?t=$($show.name)&r=JSON"
                 $omdbResponse = ConvertFrom-JSON (Invoke-WebRequest $omdbURL).content

                 # Build the HTML
                 if ($omdbResponse.Response -eq "True") {
                    if ($omdbResponse.Poster -eq "N/A") {
                        # If the poster was unavailable, substitute a Plex logo
                        $imgURL = $imgPlex
                        $imgHeight = "150"
                    } else {
                        $imgURL = $omdbResponse.Poster
                        $imgHeight = "234"
                    }
                    $tvList += "<tr><td><img src=`"$imgURL`" height=$($imgHeight)px width=150px></td>"
                    $tvList += "<td><li><a href=`"http://www.imdb.com/title/$($omdbResponse.imdbID)/`">$($show.name)</a></li>"
                    $tvList += "<ul><li><i>Genre:</i> $($omdbResponse.Genre)</li>"
                    $tvList += "<li><i>Rating:</i> $($omdbResponse.Rated)</li>"
                    $tvList += "<li><i>Plot:</i> $($omdbResponse.Plot)</li>"
                    $tvList += "<li><i>Now in library:</i><br/></li><ul>"
                    foreach ($season in ($show.Group | Sort-Object @{e={$_.index -as [int]}})){
                        if ($($season.leafCount) -gt 1) {
                            $plural = 's'
                        } else {
                            $plural = ''
                        }
                        $tvList += "<li>$($season.title) - $($season.leafCount) episode$($plural)</li>"
                    }
                    #$tvList += "<li><i>Added:</i> $(Get-Date $epoch.AddSeconds($movie.addedAt) -Format 'MMMM d')</li></ul></td>"
                }
                else {
                    # If the series couldn't be found in the DB, fail gracefully
                    $tvList += "<tr><td><img src=`"$imgPlex`" height=150px width=150px></td><td><li>$($show.name)</a></li>"
                                $tvList += "<td><li><a href=`"http://www.imdb.com/title/$($omdbResponse.imdbID)/`">$($show.name)</a></li>"
                    $tvList += "<li><i>Season:</i><br/></li><ul>"
                    foreach ($season in $show.Group){
                        $tvList += "<li>$($season.title) ($($season.leafCount) episode(s))</li>"
                    }
                }
                $tvList += "</ul></ul></td></tr>"
            }
        }
        $tvList += "</table><br/>"
    }



    if (($movieCount -eq 0) -AND ($tvCount -eq 0)) {
        $body = "No movies or TV shows have been added to the Plex library in the past $days days. Sorry!"
    } else {
        $body = "<h1>Hey there!</h1><br/>Here's the list of additions to my Plex library in the past $days days.<br/>"

        if ($movieCount -gt 0) {
            $body += $movieList
        }

        if ($tvCount -gt 0) {
            $body += $tvList
        }
        $body += "Enjoy!"
    }

    if (-not $OmitVersionNumber) {
        $body += "<br><br><br><br><p align = right><font size = 1 color = Gray>Plex Version: $((Invoke-RestMethod "$url`:$port/?X-Plex-Token=$Token" -Headers @{"accept"="application/json"}).mediaContainer.version)</p></font>"
    }

    $startDate = Get-Date (Get-Date).AddDays(-$days) -Format 'MMM d'
    $endDate = Get-Date -Format 'MMM d'
    
    $credentials = Get-Credential
        
    # If not otherwise specified, set the To address the same as the From
    if ($EmailTo -eq 'default') {
        $EmailTo = $credentials.UserName
    }
    $subject = "Plex Additions from $startDate-$endDate"
    
    if (-not($PreventSendingEmptyList -and (($movieCount+$tvCount) -eq 0)) -and $SendEmail) {
        Send-MailMessage -From $($credentials.UserName) -to $EmailTo -SmtpServer $SMTPserver -Port $SMTPport -UseSsl -Credential $credentials -Subject $subject -Body $body -BodyAsHtml
    }
}

Function Get-PlexLibraries{
    [cmdletbinding()] 
    param(    
        [string]$localPlexAddr,
        
        [ValidateSet('preferences','playing','history','library','New','OnDeck','RecentAdds','Channels','Views','transcodeQueue','Queues')]
        [string]$Section  = "library",
        
        [Parameter(Mandatory=$true, ParameterSetName="Credential")]
        [string] $PlexToken,
        [string]$Search,
        [string]$CustomAddr,
        [switch]$outJSON
    )

    
    Begin {
        If ($Search){
            $plexRESTAddr = "Search/$Search"
        }
        Else{
            switch($Section){
                'preferences'     {$plexRESTAddr = ':/prefs'}
                'playing'         {$plexRESTAddr = 'status/sessions'}
                'history'         {$plexRESTAddr = 'status/sessions/history/all'}
                'library'         {$plexRESTAddr = 'library/sections'}
                'meta'            {$plexRESTAddr = 'library/metadata'}
                'New'             {$plexRESTAddr = 'library/recentlyAdded'}
                'OnDeck'          {$plexRESTAddr = 'library/onDeck'}
                'Channels'        {$plexRESTAddr = 'channels/all'}
                'Views'           {$plexRESTAddr = 'channels/recentlyViewed'}
                'transcodeQueue'  {$plexRESTAddr = 'sync/transcodeQueue'}
                'Queues'          {$plexRESTAddr = 'playQueues'}
                default           {}
            }
        }
        If ($CustomAddr){$plexRESTAddr = $CustomAddr}
        [string]$command = "Invoke-RestMethod -Uri ""http://$localPlexAddr`:32400/$plexRESTAddr"" -Method GET -headers @{'X-Plex-Client-Identifier'='$($Global:PlexScriptGUID.Guid)';'X-Plex-Product'='$Global:PlexScriptFriendlyName';'X-Plex-Platform'='Windows';'X-Plex-Platform-Version'='$((Get-Host).Version.ToString())';'X-Plex-Device'='$env:COMPUTERNAME';'X-Plex-Version'='$($Global:PlexScriptVersion.ToString())';'X-Plex-Token'='$PlexToken'}"   
    }
    Process{
        Try
        {
            [array]$data =  Invoke-WebRequest `
                            -Uri "http://$localPlexAddr`:32400/$plexRESTAddr" `
                            -Method GET `
                            -Headers   @{
                                        'X-Plex-Client-Identifier'=$Global:PlexScriptGUID.Guid;
                                        'X-Plex-Product'=$Global:PlexScriptFriendlyName;
                                        'X-Plex-Platform'='Windows';
                                        'X-Plex-Platform-Version'=(Get-Host).Version.ToString();
                                        'X-Plex-Device'=$env:COMPUTERNAME
                                        'X-Plex-Version'=$Global:PlexScriptVersion.ToString();
                                        'X-Plex-Token'=$PlexToken
                                        }

            
            [xml]$apiContent         = $data.Content
            If($apiContent){
                switch($Section){
                    'preferences'     {[array]$plexRESTContainer = $apiContent.MediaContainer.setting}
                    'playing'         {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    'history'         {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    'library'         {[array]$plexRESTContainer = $apiContent.MediaContainer.Directory}
                    'meta'            {[array]$plexRESTContainer = $apiContent.MediaContainer}
                    'New'             {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    'OnDeck'          {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    'Channels'        {[array]$plexRESTContainer = $apiContent.MediaContainer.Directory}
                    'Views'           {[array]$plexRESTContainer = $apiContent.MediaContainer.Directory}
                    'transcodeQueue'  {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    'Queues'          {[array]$plexRESTContainer = $apiContent.MediaContainer.video}
                    default           {[array]$plexRESTContainer = $apiContent.MediaContainer}
                }
            }
            Write-host "Executing: $command" -ForegroundColor Cyan
        }
        catch
        {
            Write-host "Error: Executing: $command" -ForegroundColor Red
            break;
        }

    }
    End {
        return $plexRESTContainer
    }
}