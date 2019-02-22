<#
.Synopsis
    My original intentions was to write a script I could run regularly to 
    add movie series collections into Radarr, since it can't see deeper than 
    the root movie folder where my movie series are a subfolder of the root 
    movies in folders called " Collection" and " Anthology". These folders 
    were auto created when I ran TinyMediaManger (https://www.tinymediamanager.org/) 
    on my movies collections...I soson found out this broke Radarr's inventory 
    and had to remove over 100+ movies. It was a pain. I then decided to write this 
    script to add them back but in the proper folder.

.NOTES
    Author: Richard Tracy

.LINK
    https://api.themoviedb.org/3/movie/550?api_key=798cb1c0648d68fc43ab0c94dac906e9
.LINK
    https://developers.themoviedb.org/3/getting-started/introduction
.LINK
    https://github.com/Radarr/Radarr/wiki/API:Movie
#>
##*===========================================================================
##* FUNCTIONS
##*===========================================================================
function Test-IsISE {
# try...catch accounts for:
# Set-StrictMode -Version latest
    try {    
        return $psISE -ne $null;
    }
    catch {
        return $false;
    }
}

Function Convert-NumberToWord([string]$string){
    $Value = $null
    $string -match '\D+(\d+)' | Out-Null
    
    switch ($Matches[1]){
        "0" {[string]$toWord = 'Zero'}
        "1" {[string]$toWord = 'One'}
        "2" {[string]$toWord = 'Two'}
        "3" {[string]$toWord = 'Three'}
        "4" {[string]$toWord = 'Four'}
        "5" {[string]$toWord = 'Five'}
        "6" {[string]$toWord = 'Six'}
        "7" {[string]$toWord = 'Seven'}
        "8" {[string]$toWord = 'Eight'}
        "9" {[string]$toWord = 'Nine'}
        "10" {[string]$toWord = 'Ten'}
        "13" {[string]$toWord = 'Eleven'}
        "12" {[string]$toWord = 'Twelve'}
    }
    $Value = ($String) -replace $Matches[1],$toWord
    If($Value -ne $String){Return $Value}
}

Function Convert-WordToNumber([string]$string){
    $Value = $null
    switch -regex ("b\$string\b"){
        'zero'  {[string]$toWord = '0'}
        'one'   {[string]$toWord = '1'}
        'two'   {[string]$toWord = '2'}
        'three' {[string]$toWord = '3'}
        'four'  {[string]$toWord = '4'}
        'five'  {[string]$toWord = '5'}
        'six'   {[string]$toWord = '6'}
        'seven' {[string]$toWord = '7'}
        'eight' {[string]$toWord = '8'}
        'nine'  {[string]$toWord = '9'}
        'ten'   {[string]$toWord = '10'}
        'eleven'{[string]$toWord = '11'}
        'twelve'{[string]$toWord = '12'}
    }

    $Value = ($String) -replace $Matches,$toWord
    If($Value -ne $String){Return $Value}
}
##*===============================================
##* VARIABLE DECLARATION
##*===============================================
## Variables: Script Name and Script Paths
[string]$scriptPath = $MyInvocation.MyCommand.Definition
# what ever the working path of the ISE is loaded will be the value. change it to path where script is being written
If(Test-IsISE){[string]$scriptPath = "D:\Data\Automation\Update-RadarrMovies.ps1"}
[string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$invokingScript = (Get-Variable -Name 'MyInvocation').Value.ScriptName

#Get required folder and File paths
[string]$ExtensionPath = Join-Path -Path $scriptRoot -ChildPath 'Extensions'
[string]$ModulesPath = Join-Path -Path $scriptRoot -ChildPath 'Modules'
[string]$ConfigPath = Join-Path -Path $scriptRoot -ChildPath 'Configs'
[string]$LogDir = Join-Path $scriptRoot -ChildPath 'Logs'
[string]$StoredDataDir = Join-Path $scriptRoot -ChildPath 'StoredData'

#Import Script extensions
. "$ExtensionPath\Logging.ps1"
. "$ExtensionPath\ImdbMovieAPI.ps1"
. "$ExtensionPath\TmdbAPI.ps1"
. "$ExtensionPath\RadarrAPI.ps1"
. "$ExtensionPath\VideoParser.ps1"
#. "$ExtensionPath\TauTulliAPI.ps1"


#  Get the invoking script directory
[string]$invokingScript = (Get-Variable -Name 'MyInvocation').Value.ScriptName
If ($invokingScript) {
	#  If this script was invoked by another script
	[string]$scriptParentPath = Split-Path -Path $invokingScript -Parent
}
Else {
	#  If this script was not invoked by another script, fall back to the directory one level above this script
	[string]$scriptParentPath = (Get-Item -LiteralPath $scriptRoot).Parent.FullName
}

## Variables: Datetime and Culture
[datetime]$currentDateTime = Get-Date
[string]$currentTime = Get-Date -Date $currentDateTime -UFormat '%T'
[string]$currentDate = Get-Date -Date $currentDateTime -UFormat '%d-%m-%Y'
[timespan]$currentTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now)


# PARSE CONFIG FILE
[Xml.XmlDocument]$RadarrConfigFile = Get-Content "$ConfigPath\Configs-Radarr.xml"
[Xml.XmlElement]$RadarrConfig = $RadarrConfigFile.RadarrAutomation.RadarrConfig
[Xml.XmlElement]$ScriptSettings = $RadarrConfigFile.RadarrAutomation.GlobalSettings
[string]$radarrURL = $RadarrConfig.InternalURL
[string]$radarrPort = $RadarrConfig.Port
[string]$radarrAPIkey = $RadarrConfig.API
[string]$OMDBAPI = $ScriptSettings.OMDBAPI
[string]$TMDBAPI = $ScriptSettings.TMDBAPI
[string]$MoviesDir = $ScriptSettings.MoviesRootPath

# Update Data Configs
[boolean]$StatsOnly = [boolean]::Parse($ScriptSettings.CheckStatusOnly)
[boolean]$UpdateNfoData = [boolean]::Parse($ScriptSettings.UpdateNfoData)
[boolean]$UpdateJustMovieSeries = [boolean]::Parse($ScriptSettings.UpdateMovieSeriesOnly)
[int32]$UseRecentStoredDataDays = $ScriptSettings.UseRecentStoredDataDays


[datetime]$StoreData = $currentDateTime.AddDays(-$UseRecentStoredData)
If($UseRecentStoredDataDays -gt 0){$UseLocalizedStoredData = $true}Else{$UseLocalizedStoredData = $false}

#Reset variables
$Global:UnmatchedMovieReport = @()
$Global:ExistingMovieReport = @()
$Global:WrongMovieReport = @()
$Global:AddedMovieReport = @()
$Global:NoMovieInfoReport = @()
$Global:FailedMovieReport = @()


#=======================================================
# MAIN
#=======================================================
#generate log file
If($scriptName){
    $FinalLogFileName = ($ScriptName.Trim(" ") + "_" + $currentDate + "_" + $currentTime.replace(':',''))
    [string]$global:LogFilePath = Join-Path $LogDir -ChildPath "$FinalLogFileName.log"
    Write-Log -Message ("Starting Log") -Source ${CmdletName} -Severity 4 -WriteHost -MsgPrefix (Pad-PrefixOutput -Prefix "Starting" -UpperCase)
}


#Basically this part check to see if the $Global:AllMoviesGenres has data already
# good for testings instead of processing folders each time
If( ($Global:AllMoviesGenres.count -eq 0) -or ($Global:RadarrMovies.count -eq 0)  ){
    #build list of movie genres from folder
    Write-Host "Grabbing all movie Genre folders..." -NoNewline
    $Global:AllMoviesGenres = Get-ChildItem $MoviesDir -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $true}
    Write-Host ("Found {0}" -f $AllMoviesGenres.Count)

    #build radarr list
    Write-Host "Grabbing all movies in Radarr..." -NoNewline
    $RadarrGetArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://${radarrURL}:${radarrPort}/api/movie"
                    Method = "Get"
                }
    Try{
        $radarrWebRequest = Invoke-WebRequest @RadarrGetArgs -UseBasicParsing
        $Global:RadarrMovies = $radarrWebRequest.Content | ConvertFrom-Json
        Write-Host ("Found {0}" -f $Global:RadarrMovies.Count)
    }
    Catch{
        Write-Host "Unable to connect to Radarr, error $($_.Exception.ErrorMessage)"
    }
}

#get list of movie folders within the genre folders
Write-Host "Grabbing all movie folders..." -NoNewline
$AllMoviesFolders = $Global:AllMoviesGenres | %{Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Where-Object { ($_.PSIsContainer -eq $true)} | Select Name, FullName} 
Write-Host ("Found {0}" -f $AllMoviesFolders.Count)

#update just the series section?
If($UpdateJustMovieSeries){
    Write-Host "Comparing all movie series on disk to what is in Radarr..." -NoNewline -ForegroundColor Cyan
    #only get the movie sets located in collection folders
    $movieFilter = $AllMoviesFolders | Where-Object {$_.FullName -match "Collection" -or $_.FullName -match "Anthology"} 
}
Else{
    Write-Host "Comparing all movies on disk to what is in Radarr..." -NoNewline -ForegroundColor Cyan 
    #get list of movie folders within the genre folders
    #do not include collection folders
    $movieFilter = ($AllMoviesFolders | Where-Object {$_.Name -notlike "*Collection*"} | Where-Object {$_.Name -notlike "*Anthology*"})
}

Write-Host ("Found {0}" -f $movieFilter.Count)
Write-Host "=============================================" -ForegroundColor Cyan

#If nfo file exists, compare nfo with movie to ensure its correct
#build array based on info found
If($UpdateNfoData){
    Write-Host "Checking all movies on disk for nfo files..."
    Foreach ($MoviesFolder in $AllMoviesFolders){
        #if folder is one of the genre folders, ignore
        If(Compare-Object $MoviesFolder.Name $Global:AllMoviesGenres.Name -IncludeEqual -passThru | Where-Object { $_.SideIndicator -eq '==' }){
            Write-Host ("Ignoring movie genre folder: {0}" -f $MoviesFolder.Name) -ForegroundColor Gray
        }
        ElseIf(Compare-Object $MoviesFolder.Name $Global:MovieSeries.Name -IncludeEqual -passThru | Where-Object { $_.SideIndicator -eq '==' }){
            Write-Host ("Ignoring movie series folders: {0}" -f $MoviesFolder.Name) -ForegroundColor Gray
        }Else{
            $NFOfileExist = Get-ChildItem $MoviesFolder.FullName -Filter *.nfo -Force -Recurse
            $yearfound = $MoviesFolder.Name -match ".?\((.*?)\).*"
            $year = $matches[1]
            $MovieTitle = ($MoviesFolder.Name).replace("($year)","").Trim()
            If($NFOfileExist.Count -gt 1){
                Write-Host ("Found multiple Movie NFO files [{0}] for: {1}" -f $NFOfileExist.Count,$MoviesFolder.Name) -ForegroundColor Gray
            }
            ElseIf($NFOfileExist){
                Write-Host ("Movie NFO file exists for: {0}" -f $MoviesFolder.Name) -ForegroundColor Green
                [xml]$NFOxml = Get-Content $NFOfileExist.FullName
                If( !($NFOxml.movie.title -match $MovieTitle) -and !($NFOxml.movie.year -match $year) ){
                    Write-Host ("Movie NFO file exists for: {0} but is invalid: {1} ({2})" -f $MoviesFolder.Name,$NFOxml.movie.title,$NFOxml.movie.year) -ForegroundColor Red
                }
            }Else{
                Write-Host ("No Movie NFO file exists for: {0}" -f $MoviesFolder.Name) -ForegroundColor Yellow
                #If StatsOnly boolean in config is set to true don't process new nfo file
                If(!$StatsOnly){Set-VideoNFO -MovieFolder $MoviesFolder.FullName -imdbAPI $OMDBAPI}
            }
        }
    }
}


foreach ($Movie in $movieFilter)
{
    Write-Host "---------------------------------------" -ForegroundColor Gray
    Write-Host ("Processing Movie [{0}]" -f $Movie.Name) -ForegroundColor Gray
    #$yearfound = $Movie.Name -match ".?\((.*?)\).*"
    If($Movie.Name -match ".?\((.*?)\).*"){
        #is the year numeric?
        If($matches[1] -match "^[\d\.]+$"){
            $year = $matches[0]
            #remvoe the year to get the name
            $MovieTitle = ($Movie.Name).replace("($year)","").Trim()
            $yearfound = $true
        }
        Else{
            $MovieTitle = $Movie.Name
            $yearfound = $false
        }
    }
    Else{
        $MovieTitle = $Movie.Name
        $yearfound = $false
    }

    #rename variable to use later
    $MovieTitleCleaned = $MovieTitle

    #remove unsupported characters for easier search results
    #normailze any special characters such as: å,ä,ö,Ã,Å,Ä,Ö,é
    $MovieTitleCleaned = $MovieTitleCleaned.Normalize("FormD") -replace '\p{M}'
    
    #replace the Ã© with e (pokemon titles)
    $MovieTitleCleaned = $MovieTitleCleaned.replace('Ã©','e')

    #remove double spaces
    $MovieTitleCleaned = $MovieTitleCleaned -replace'\s+', ' '

    #replace & with and
    $MovieTitleCleaned = $MovieTitleCleaned.replace('&','and')

    #remove any special characters but keep apstraphe '
    $MovieTitleNoSpecialChar = $MovieTitle -replace "[^{\p{L}\p{Nd}\'}]+", " "

    #does the title have a number in it like: Daddy's Home 2
    $MovieTitleConvertedToNum = Convert-WordToNumber $MovieTitleCleaned

    #does the title have a number in it like: Daddy's Home 2
    $MovieTitleConvertedToChar = Convert-NumberToWord $MovieTitleCleaned

    #if a year was found within the name, query IMDB and TMDB for name and year for a better match
    If($yearfound)
    {
        #IMDB SEARCH....
        #====================================
        Write-Host ("Searching for movie [{0}] with year [{1}] in IMDB..." -f $MovieTitleCleaned,$year) -ForegroundColor Gray

        #first check normal title against IMDB
        $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitle -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue

        #If no results try the title with no special charaters search against IMDB
        If(!$IMDBMovieInfo){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleCleaned -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the title with no special charaters search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleNoSpecialChar){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleNoSpecialChar -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the converted title search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleConvertedToNum){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleConvertedToNum -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the converted title search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleConvertedToChar){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleConvertedToChar -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #Has a match been found on IMDB?
        If($IMDBMovieInfo){
            $NoSpaceIMDBTitle = ($IMDBMovieInfo.Title -replace '[\W]', '').ToLower()
            Write-Host ("...IMDB movie titled [{0}] with year [{1}] was found" -f $IMDBMovieInfo.Title,[string](Get-Date $IMDBMovieInfo.Released -Format yyyy -ErrorAction SilentlyContinue)) -ForegroundColor DarkGray
        }
        Else{
            Write-Host ("...IMDB movie titled [{0}] with year [{1}] was not found" -f $MovieTitleCleaned,$year) -ForegroundColor DarkGray
        }
        
        #TMDB SEARCH....
        #====================================
        Write-Host ("   Searching for movie [{0}] with year [{1}] in TMDB..." -f $MovieTitleCleaned,$year) -ForegroundColor Gray
        
        #first check normal title against TMDB
        $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitle -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue

        #If no results try the title with no special charaters search against TMDB
        If(!$TMDBMovieInfo){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleCleaned -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }

        #If no results try the title with no special charaters search against TMDB
        If(!$TMDBMovieInfo -and $MovieTitleNoSpecialChar){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleNoSpecialChar -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }

        #If  no results try the converted title search against TMDB
        If(!$TMDBMovieInfo -and $MovieTitleConvertedToChar){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleConvertedToChar -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }
        
        #If no results try the converted title search against TMDB
        If(!$TMDBMovieInfo -and $MovieTitleConvertedToNum){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleConvertedToNum -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }
        
        #Has a match been found on TMDB?
        If($TMDBMovieInfo){
            $NoSpaceTMDBTitle = ($TMDBMovieInfo.Title -replace '[\W]', '').ToLower()
            Write-Host ("...TMDB movie titled [{0}] with year [{1}] was found" -f $TMDBMovieInfo.Title,[string](Get-Date $TMDBMovieInfo.ReleaseDate -Format yyyy -ErrorAction SilentlyContinue)) -ForegroundColor DarkGray
        }
        Else{
            Write-Host ("...TMDB movie titled [{0}] with year [{1}] was not found" -f $MovieTitleCleaned,$year) -ForegroundColor DarkGray
        }

        $SearchYear = $year
    }
    Else
    {      

        #IMDB SEARCH....
        #====================================
        Write-Host ("   Searching for movie [{0}] with year [{1}] in IMDB..." -f $MovieTitleCleaned,$year) -ForegroundColor Gray

        #first check normal title against TMDB
        $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleCleaned -Api $OMDBAPI -ErrorAction SilentlyContinue
        
        #If no results try the title with no special charaters search against IMDB
        If(!$IMDBMovieInfo){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleCleaned -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the title with no special charaters search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleNoSpecialChar){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleNoSpecialChar -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the converted title search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleConvertedToNum){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleConvertedToNum -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #If no results try the converted title search against IMDB
        If(!$IMDBMovieInfo -and $MovieTitleConvertedToChar){
            $IMDBMovieInfo = Get-ImdbTitle -Title $MovieTitleConvertedToChar -Api $OMDBAPI -ErrorAction SilentlyContinue
        }

        #Has a match been found on IMDB?
        If($IMDBMovieInfo){
            $NoSpaceIMDBTitle = ($IMDBMovieInfo.Title -replace '[\W]', '').ToLower()
            Write-Host ("...IMDB movie titled [{0}] was found" -f $IMDBMovieInfo.Title) -ForegroundColor DarkGray
        }
        Else{
            Write-Host ("...IMDB movie titled [{0}] was not found" -f $MovieTitleCleaned) -ForegroundColor DarkGray
        }
        
        #TMDB SEARCH....
        #====================================
        Write-Host ("   Searching for movie [{0}] with year [{1}] in TMDB..." -f $MovieTitleCleaned,$year) -ForegroundColor Gray
        #first check normal title against TMDB
        $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleCleaned -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue

        #If no results try the title with no special charaters search against TMDB
        If(!$TMDBMovieInfo){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleCleaned -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }

        #If no results try the title with no special charaters search against IMDB
        If(!$TMDBMovieInfo -and $MovieTitleNoSpecialChar){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleNoSpecialChar -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }

        #If no results try the title with converted numbers to words search against TMDB
        If(!$TMDBMovieInfo -and $MovieTitleConvertedToChar){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleConvertedToChar -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }
        
        #If no results try the title to spelled numbers converted to number digits search against TMDB
        If(!$TMDBMovieInfo -and $MovieTitleConvertedToNum){
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieTitleConvertedToNum -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
        }
        
        #Has a match been found on TMDB?
        If($TMDBMovieInfo){
            $NoSpaceTMDBTitle = ($TMDBMovieInfo.Title -replace '[\W]', '').ToLower()
            Write-Host ("...TMDB movie titled [{0}] was found" -f $TMDBMovieInfo.Title) -ForegroundColor DarkGray
        }
        Else{
            Write-Host ("...TMDB movie titled [{0}] was not found" -f $MovieTitleCleaned) -ForegroundColor DarkGray
        }

        If($TMDBMovieInfo.ReleaseDate -or $IMDBMovieInfo.Released){$SearchYear = [string](Get-Date $TMDBMovieInfo.ReleaseDate -Format yyyy -ErrorAction SilentlyContinue)}Else{$SearchYear = $null}
    }

    #was there a movie in IMDB and TMDB?
    If($IMDBMovieInfo -and $TMDBMovieInfo){
        #format the titles so that there are no special characters or spaces to ensure it a good match
        #$NoSpaceIMDBTitle = ($IMDBMovieInfo.Title -replace '[\W]', '').ToLower()
        #$NoSpaceTMDBTitle = ($TMDBMovieInfo.Title -replace '[\W]', '').ToLower()

        #if both IMDB and TMDB information are different log it and go to next
        If($NoSpaceIMDBTitle -ne $NoSpaceTMDBTitle){

            Write-Host ("Movie information does not match from IMDB [{0}] and TMDB [{1}]. Unable to add to Radarr, skipping..." -f $IMDBMovieInfo.Title,$TMDBMovieInfo.Title) -ForegroundColor Red
            $UnmatchedMovie = New-Object System.Object
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name SearchName -Value $MovieTitleCleaned
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name SearchYear -Value $SearchYear
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbID -Value $IMDBMovieInfo.imdbID
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbTitle -Value $IMDBMovieInfo.title
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbYear -Value $IMDBMovieInfo.year
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name TmdbID -Value $TMDBMovieInfo.tmdbID
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name TmdbTitle -Value $TMDBMovieInfo.Title
            
            #add to another array for reporting
            $Global:UnmatchedMovieReport += $UnmatchedMovie
            $AddMovietoRadarr = $false

            Start-Sleep 1
            Continue
            #break
        }
        Else{
            Write-Host ("Movie information for [{0}] was matched from both TMDB and IMDB." -f $IMDBMovieInfo.Title) -ForegroundColor Green
            $AddMovietoRadarr = $true
        }
    }
    Else{
        #if no IMDB and TMDB information was found log it and go to next
        Write-Host ("Not enough information was found for [{0}]. Unable to add to Radarr." -f $MovieTitleCleaned) -ForegroundColor Red
        $NoMovieInfo = New-Object System.Object
        $NoMovieInfo | Add-Member -Type NoteProperty -Name SearchName -Value $MovieTitleCleaned
        $NoMovieInfo | Add-Member -Type NoteProperty -Name SearchYear -Value $SearchYear
        $NoMovieInfo | Add-Member -Type NoteProperty -Name ImdbID -Value $IMDBMovieInfo.imdbID
        $NoMovieInfo | Add-Member -Type NoteProperty -Name TmdbID -Value $TMDBMovieInfo.tmdbID
        #add to another array for reporting
        $Global:NoMovieInfoReport += $NoMovieInfo
        $AddMovietoRadarr = $false

        Start-Sleep 1
        Continue
        #break
    }

    #replace movie titles that have a - with :
    #$RealMovieName = $MovieTitle.replace(" -",":")
    $RealMovieName = $MovieTitleCleaned

    #now determine if radarr has a matching movie based on IMDB and its path
    $ImdbInRadarr = $Global:RadarrMovies | Where {($_.imdbId -eq $IMDBMovieInfo.imdbID) -and ($_.tmdbId -eq $TMDBMovieInfo.tmdbID)}
    $PathInRadarr = $Global:RadarrMovies | Where {$_.path -eq $Movie.FullName}
    
    If($ImdbInRadarr -or $PathInRadarr){
        $AddMovietoRadarr = $false
        
        #Compare imdb in search vs Radarr imdb is path exists in Radarr
        #if its the wrong imdb add it the report. FUTURE is to fix it
        If($PathInRadarr -and ($PathInRadarr.imdbID -ne $IMDBMovieInfo.imdbID) ){
            Write-Host ("Movie [{0}] name is incorrect; removing from Radarr to reprocess..." -f $RealMovieName) -ForegroundColor Red
            Write-Host ("   Actual Name: {0}" -f $IMDBMovieInfo.Title)
            Write-Host ("   Actual Imdb: {0}" -f $IMDBMovieInfo.imdbId)
            Write-Host ("   Radarr Name: {0}" -f $PathInRadarr.title)
            Write-Host ("   Radarr Imdb: {0}" -f $PathInRadarr.imdbId)

            $deleteMovieArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://${radarrURL}:${radarrPort}/api/movie/$($PathInRadarr.ID)"
                    Method = "Delete"
            }

            If(!$StatsOnly){Invoke-WebRequest @deleteMovieArgs | Out-Null}
            Start-sleep 3
            $AddMovietoRadarr = $true
        }
        #since both IMDB matched, check its video path to ensure its that right video
        #if its the wrong path add it the report. FUTURE is to fix it
        ElseIf("$($ImdbInRadarr.Path)" -ne "$($Movie.FullName)"){
            Write-Host ("Movie [{0}] path is incorrect; updating Radarr's path..." -f $RealMovieName) -ForegroundColor Red
            Write-Host ("   Actual Path: {0}" -f $Movie.FullName) -ForegroundColor Gray
            Write-Host ("   Radarr Path: {0}" -f $ImdbInRadarr.Path) -ForegroundColor Gray

            $WrongMovie = New-Object System.Object
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrTitle -Value $ImdbInRadarr.title 
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrYear -Value $ImdbInRadarr.year
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrPath -Value $ImdbInRadarr.Path
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrfolderName -Value $ImdbInRadarr.folderName
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrID -Value $ImdbInRadarr.ID
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrIMDB -Value $ImdbInRadarr.imdbId
            $WrongMovie | Add-Member -Type NoteProperty -Name RadarrURL -Value ('http://'+ $radarrURL + ':' + $radarrPort +'/movie/' + $ImdbInRadarr.titleSlug)
            $WrongMovie | Add-Member -Type NoteProperty -Name ActualPath -Value $Movie.FullName
            #add to another array for reporting
            $Global:WrongMovieReport += $WrongMovie

            Write-Host ("Grabbing {0} from Radarr, using ID [{1}]..." -f $ImdbInRadarr.title,$ImdbInRadarr.ID) -ForegroundColor Gray
            $RadarrGetMovieID = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                            URI = "http://${radarrURL}:${radarrPort}/api/movie/$($ImdbInRadarr.ID)"
                            Method = "Get"
                        }
                        $radarrGetIDRequest = Invoke-WebRequest @RadarrGetMovieID
                        $radarrMovieID = $radarrGetIDRequest.Content | ConvertFrom-Json
            
            #replace the value
            $radarrMovieID.folderName=$Movie.FullName
            $radarrMovieID.path=$Movie.FullName 
            $radarrMovieID.PSObject.Properties.Remove('movieFile')  
            #convert PSObject back into JSON format
            $body = $radarrMovieID | ConvertTo-Json #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }

            $RadarrUpdateMovieID = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                        URI = "http://${radarrURL}:${radarrPort}/api/movie/$($ImdbInRadarr.ID)"
                        Method = "Put"
                    }
                    If(!$StatsOnly){Invoke-WebRequest @RadarrUpdateMovieID -Body $body | Out-Null}

            Start-Sleep 1
            #Break
        }
        Else{
            Write-Host ("Movie [{0}] was already found in Radarr's database" -f $RealMovieName) -ForegroundColor Green
            $ExistingMovie = New-Object System.Object
            $ExistingMovie | Add-Member -Type NoteProperty -Name id -Value $ImdbInRadarr.id
            $ExistingMovie | Add-Member -Type NoteProperty -Name Title -Value $ImdbInRadarr.title 
            $ExistingMovie | Add-Member -Type NoteProperty -Name year -Value $ImdbInRadarr.year
            $ExistingMovie | Add-Member -Type NoteProperty -Name RadarrURL -Value ('http://'+ $radarrURL + ':' + $radarrPort +'/movie/' + $ImdbInRadarr.titleSlug)
            #add to another array for reporting
            $Global:ExistingMovieReport += $ExistingMovie
        }
    }
    Else{
        Write-Host ("Movie [{0}] was not found in Radarr's database, adding to Radarr..." -f $RealMovieName) -ForegroundColor Yellow
        $AddMovietoRadarr = $true
    }


    If($AddMovietoRadarr)
    {
        Write-Host ("Processing details for movie title [{0}]..." -f $IMDBMovieInfo.Title)
        $Regex = "[^{\p{L}\p{Nd}\'}]+"
        [string]$actualName = $IMDBMovieInfo.Title
        [string]$sortName = ($IMDBMovieInfo.Title).ToLower()
        [string]$cleanName = (($IMDBMovieInfo.Title) -replace $Regex,"").Trim().ToLower()
        [string]$ActualYear = $IMDBMovieInfo.Year
        [string]$imdbID = $IMDBMovieInfo.imdbID
        #[string]$imdbID = ($IMDBMovieInfo.imdbID).substring(2,($IMDBMovieInfo.imdbID).length-2)
        [int32]$tmdbID = $TMDBMovieInfo.tmdbID
        [string]$Image = $TMDBMovieInfo.Poster
        [string]$simpleTitle = (($IMDBMovieInfo.Title).replace("'","") -replace $Regex,"-").Trim().ToLower()
        [string]$titleSlug = $simpleTitle + "-" + $TMDBMovieInfo.tmdbID
        $MovieRootPath = $Movie.FullName

        #Write-Host ("Adding movie [{0}] to Radarr database..." -f $actualName) -ForegroundColor Gray
        Write-Host ("   Path: {0}" -f $MovieRootPath) -ForegroundColor Gray
        Write-Host ("   Imdb: {0}" -f $imdbID) -ForegroundColor Gray
        Write-Host ("   Tmdb: {0}" -f $tmdbID) -ForegroundColor Gray
        Write-Host ("   Slug: {0}" -f $titleSlug) -ForegroundColor Gray
        Write-Host ("   Year: {0}" -f $ActualYear) -ForegroundColor Gray

        $Body = @{ title=$actualName;
            sortTitle=$sortName;
            cleanTitle=$cleanName;
            qualityProfileId="1";
            year=$ActualYear;
            tmdbid=$tmdbID;
            imdbid=$imdbID;
            titleslug=$titleSlug;
            monitored="true";
            path=$MovieRootPath;
            addOptions=@{
                searchForMovie="true"
            };
            images=@( @{
                covertype="poster";
                url=$Image
            } );
        }
        $BodyObj = ConvertTo-Json -InputObject $Body #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        #$BodyArray = ConvertFrom-Json -InputObject $BodyObj

        $RadarrPostArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                        URI = "http://${radarrURL}:${radarrPort}/api/movie"
                        Method = "Post"
                }
        try
        {
            If(!$StatsOnly){Invoke-WebRequest @RadarrPostArgs -Body $BodyObj | Out-Null}

            $AddedMovie = New-Object System.Object
            $AddedMovie | Add-Member -Type NoteProperty -Name Title -Value $actualName
            $AddedMovie | Add-Member -Type NoteProperty -Name Year -Value $ActualYear
            $AddedMovie | Add-Member -Type NoteProperty -Name IMDB -Value $imdbID
            $AddedMovie | Add-Member -Type NoteProperty -Name TMDB -Value $tmdbID
            $AddedMovie | Add-Member -Type NoteProperty -Name TitleSlug -Value $titleslug
            $AddedMovie | Add-Member -Type NoteProperty -Name FolderPath -Value $MovieRootPath
            $AddedMovie | Add-Member -Type NoteProperty -Name RadarrPath -Value ('http://' + $radarrURL + ':' + $radarrPort + '/movie/' + $titleslug)
            #add to another array for reporting
            $Global:AddedMovieReport += $AddedMovie
        }
        catch {
            Write-Error -ErrorRecord $_
            $FailedMovie = New-Object System.Object
            $FailedMovie | Add-Member -Type NoteProperty -Name Title -Value $actualName
            $FailedMovie | Add-Member -Type NoteProperty -Name Year -Value $ActualYear
            $FailedMovie | Add-Member -Type NoteProperty -Name IMDB -Value $imdbID
            $FailedMovie | Add-Member -Type NoteProperty -Name TMDB -Value $tmdbID
            $FailedMovie | Add-Member -Type NoteProperty -Name TitleSlug -Value $titleslug
            $FailedMovie | Add-Member -Type NoteProperty -Name FolderPath -Value $MovieRootPath
            $FailedMovie | Add-Member -Type NoteProperty -Name RadarrPath -Value ('http://' + $radarrURL + ':' + $radarrPort + '/movie/' + $titleslug)
            #add to another array for reporting
            $Global:FailedMovieReport += $FailedMovie
            Break
        }

        start-sleep 3
    }
}

#build radarr list
Write-Host "Grabbing all movies in Radarr again..."
$RadarrGetArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                URI = "http://${radarrURL}:${radarrPort}/api/movie"
                Method = "Get"
            }
$radarrWebRequest = Invoke-WebRequest @RadarrGetArgs
$Global:RadarrMovies = $radarrWebRequest.Content | ConvertFrom-Json

Write-Host ("Existing Movies   : {0}" -f $Global:ExistingMovieReport.Count)
Write-Host ("Unmatched Movies  : {0}" -f $Global:UnmatchedMovieReport.Count)
Write-Host ("Wrong Movies      : {0}" -f $Global:WrongMovieReport.Count)
Write-Host ("Added Movies      : {0}" -f $Global:AddedMovieReport.Count)
Write-Host ("Failed Movies     : {0}" -f $Global:FailedMovieReport.Count)
Write-Host ("No Info for Movie : {0}" -f $Global:NoMovieInfoReport.Count)