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

Function Convert-NumberToWord([string]$string,[int]$digit,[switch]$PassTense){
    If($digit){
        $digit -match '(\d+)' | Out-Null
    }
    Else{
        $string -match '\D+(\d+)' | Out-Null
    }

    switch ($Matches[1]){
        "0" {[string]$toWord = 'Zero'}
        "1" {If($PassTense){[string]$toWord = 'First'}Else{[string]$toWord = 'One'}}
        "2" {If($PassTense){[string]$toWord = 'Second'}Else{[string]$toWord = 'Two'}}
        "3" {If($PassTense){[string]$toWord = 'Third'}Else{[string]$toWord = 'Three'}}
        "4" {If($PassTense){[string]$toWord = 'Fouth'}Else{[string]$toWord = 'Four'}}
        "5" {If($PassTense){[string]$toWord = 'Fifth'}Else{[string]$toWord = 'Five'}}
        "6" {If($PassTense){[string]$toWord = 'Sixth'}Else{[string]$toWord = 'Six'}}
        "7" {If($PassTense){[string]$toWord = 'Seventh'}Else{[string]$toWord = 'Seven'}}
        "8" {If($PassTense){[string]$toWord = 'Eighth'}Else{[string]$toWord = 'Eight'}}
        "9" {If($PassTense){[string]$toWord = 'Nineth'}Else{[string]$toWord = 'Nine'}}
        "10" {If($PassTense){[string]$toWord = 'Tenth'}Else{[string]$toWord = 'Ten'}}
        "11" {If($PassTense){[string]$toWord = 'Eleventh'}Else{[string]$toWord = 'Eleven'}}
        "12" {If($PassTense){[string]$toWord = 'Twelveth'}Else{[string]$toWord = 'Twelve'}}
        "13" {If($PassTense){[string]$toWord = 'Thirteenth'}Else{[string]$toWord = 'Thirteen'}}
        default {[string]$toWord = $null}
    }
    If($digit){
        $Value = $toWord
    }
    Else{
        $Value = ($String) -replace $Matches[1],$toWord
    }
    Return $Value
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
        "thirteen" {[string]$toWord = '13'}
        default {[string]$toWord = $null}
    }

    $Value = ($String) -replace $Matches[0],$toWord
    Return $Value
}

Function Search-MovieTitle{
    [CmdletBinding(DefaultParameterSetName='Title')]
    param (
        [Parameter(ParameterSetName='Title', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        [Parameter(ParameterSetName='Title', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $AlternateTitles,

        [Parameter(ParameterSetName='Title', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]
        $Year,

        [Parameter(Mandatory=$true)]
        [string]
        $IMDBApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $TMDBApiKey,

        [Parameter(Mandatory=$false)]
        [switch]
        $ReturnBoolean

    )
    Begin{
        $IMDBMovieTitles = @()
        $TMDBMovieTitles = @()
        $IMDBMovieInfo = $null
        $TMDBMovieInfo = $null
        $NoSpecialIMDBTitles = $null
        $NoSpecialTMDBTitles = $null

        $ContinueToSearch = $true
    }
    Process{
        #if a year was found within the name, query IMDB and TMDB for name and year for a better match
        If($Year){
            $ParamHash = @{Year = $Year}
            $YearLabel = " with year [$Year]"
        }

        If($AlternateTitles){
            $AlternateTitles = $AlternateTitles | Select -Unique
        }

        [int]$Count = 1

        If($ContinueToSearch -and $Title){

            Write-Host ("Search for movie title [{1}]{2} in IMDB..." -f $SearchCountlabel,$Title,$YearLabel) -ForegroundColor Gray -NoNewline
            $IMDBMovieInfo = Get-ImdbTitle -Title $Title @ParamHash -Api $IMDBApiKey -ErrorAction SilentlyContinue
            If($IMDBMovieInfo){Write-Host ("Found {0}" -f $IMDBMovieInfo.Count)}Else{Write-Host "Found 0"}
        
            Write-Host ("Search for movie title [{1}]{2} in TMDB..." -f $SearchCountlabel,$Title,$YearLabel) -ForegroundColor Gray -NoNewline
            $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $Title @ParamHash -ApiKey $TMDBApiKey -SelectFirst -ErrorAction SilentlyContinue
            If($TMDBMovieInfo){Write-Host ("Found {0}" -f $TMDBMovieInfo.Count)}Else{Write-Host "Found 0"}
        
            $NoSpecialIMDBTitles = ($IMDBMovieInfo.Title -replace 'Ã©','e' -replace "[^{\p{L}\p{Nd}\'}]+", " ").Normalize("FormD") -replace '\p{M}'
            $NoSpecialTMDBTitles = ($TMDBMovieInfo.Title -replace 'Ã©','e' -replace "[^{\p{L}\p{Nd}\'}]+", " ").Normalize("FormD") -replace '\p{M}'

            If(!$NoSpecialIMDBTitles -or !$NoSpecialTMDBTitles){
                Write-Host ("Movie information for [{0}]{1} is not available from IMDB or TMDB" -f $Title,$YearLabel) -ForegroundColor Red
                $ContinueToSearch = $true
                #$AddMovietoRadarr = $false
            }
            ElseIf($NoSpecialIMDBTitles -ne $NoSpecialTMDBTitles){
                If(( (Convert-WordToNumber $NoSpecialIMDBTitles) -eq (Convert-WordToNumber $NoSpecialTMDBTitles) ) -or ( (Convert-NumberToWord $NoSpecialIMDBTitles) -eq (Convert-NumberToWord $NoSpecialTMDBTitles) )){
                    Write-Host ("Movie information was matched from both IMDB [{0}] and TMDB [{1}]{2}" -f $NoSpecialIMDBTitles,$NoSpecialTMDBTitles,$YearLabel) -ForegroundColor Green
                    $MatchedMovieTitle = $IMDBMovieInfo.Title
                    $ContinueToSearch = $false
                }
                Else{
                    Write-Host ("Movie information does not match from IMDB [{0}] and TMDB [{1}]{2}" -f $IMDBMovieInfo.Title,$TMDBMovieInfo.Title,$YearLabel) -ForegroundColor Red
                    $ContinueToSearch = $true
                }
            }
            Else{
                Write-Host ("Movie information was matched from both IMDB [{0}] and TMDB [{1}]{2}" -f $NoSpecialIMDBTitles,$NoSpecialTMDBTitles,$YearLabel) -ForegroundColor Green
                $MatchedMovieTitle = $IMDBMovieInfo.Title
                $ContinueToSearch = $false
            }
        }

        If($AlternateTitles){
            Foreach ($AlternateTitle in $AlternateTitles){
                
                $SearchCountlabel = Convert-NumberToWord -digit $Count -PassTense

                If($ContinueToSearch -and ($AlternateTitle -ne $Title) ){
                    Write-Host ("{0} search for alternate movie title [{1}]{2} in IMDB..." -f $SearchCountlabel,$AlternateTitle,$YearLabel) -ForegroundColor Gray -NoNewline
                    $IMDBMovieInfo = Get-ImdbTitle -Title $AlternateTitle @ParamHash -Api $IMDBApiKey -ErrorAction SilentlyContinue
                    If($IMDBMovieInfo){Write-Host ("Found {0}" -f $IMDBMovieInfo.Count)}Else{Write-Host "Found 0"}
                    If(!$Year){$Year = $IMDBMovieInfo.Year}

                    Write-Host ("{0} search for alternate movie title [{1}]{2} in TMDB..." -f $SearchCountlabel,$AlternateTitle,$YearLabel) -ForegroundColor Gray -NoNewline
                    $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $AlternateTitle @ParamHash -ApiKey $TMDBApiKey -SelectFirst -ErrorAction SilentlyContinue
                    If($TMDBMovieInfo){Write-Host ("Found {0}" -f $TMDBMovieInfo.Count)}Else{Write-Host "Found 0"}
                    If(!$Year){$Year = (Get-Date $TMDBMovieInfo.ReleaseDate -Format yyyy -ErrorAction SilentlyContinue)}

                    $NoSpecialIMDBTitles = ($IMDBMovieInfo.Title -replace 'Ã©','e' -replace "[^{\p{L}\p{Nd}\'}]+", " ").Normalize("FormD") -replace '\p{M}'
                    $NoSpecialTMDBTitles = ($TMDBMovieInfo.Title -replace 'Ã©','e' -replace "[^{\p{L}\p{Nd}\'}]+", " ").Normalize("FormD") -replace '\p{M}'

                    If(!$NoSpecialIMDBTitles -or !$NoSpecialTMDBTitles){
                        Write-Host ("Movie information for [{0}]{1} is not available from IMDB or TMDB" -f $AlternateTitle,$YearLabel) -ForegroundColor Red
                        $ContinueToSearch = $true
                    }
                    ElseIf($NoSpecialIMDBTitles -ne $NoSpecialTMDBTitles){
                        If(( (Convert-WordToNumber $NoSpecialIMDBTitles) -eq (Convert-WordToNumber $NoSpecialTMDBTitles) ) -or ( (Convert-NumberToWord $NoSpecialIMDBTitles) -eq (Convert-NumberToWord $NoSpecialTMDBTitles) )){
                            Write-Host ("Movie information was matched from both IMDB [{0}] and TMDB [{1}]{2}" -f $NoSpecialIMDBTitles,$NoSpecialTMDBTitles,$YearLabel) -ForegroundColor Green
                            $MatchedMovieTitle = $IMDBMovieInfo.Title
                            $ContinueToSearch = $false
                            Continue
                        }
                        Else{
                            Write-Host ("Movie information does not match from IMDB [{0}] and TMDB [{1}]{2}" -f $IMDBMovieInfo.Title,$TMDBMovieInfo.Title,$YearLabel) -ForegroundColor Red
                            $ContinueToSearch = $true
                        }
                    }
                    Else{
                        Write-Host ("Movie information was matched from both IMDB [{0}] and TMDB [{1}]{2}" -f $NoSpecialIMDBTitles,$NoSpecialTMDBTitles,$YearLabel) -ForegroundColor Green
                        $MatchedMovieTitle = $IMDBMovieInfo.Title
                        $ContinueToSearch = $false
                        Continue
                    }
                }
            }

            $Count = $Count + 1
        } #end alternate title search

    }
    End{
        #if a title was found and boolean return not specified
        If(!$ReturnBoolean -and $MatchedMovieTitle){
            $returnObjects = @()

            $returnObject = New-Object System.Object
            $returnObject | Add-Member -Type NoteProperty -Name Title -Value $IMDBMovieInfo.title
            $returnObject | Add-Member -Type NoteProperty -Name Year -Value $IMDBMovieInfo.year
            $returnObject | Add-Member -Type NoteProperty -Name Rated -Value $IMDBMovieInfo.Rated
            $returnObject | Add-Member -Type NoteProperty -Name Released -Value $IMDBMovieInfo.Released
            $returnObject | Add-Member -Type NoteProperty -Name Runtime -Value $IMDBMovieInfo.Runtime
            $returnObject | Add-Member -Type NoteProperty -Name Genre -Value $IMDBMovieInfo.Genre
            $returnObject | Add-Member -Type NoteProperty -Name Director -Value $IMDBMovieInfo.Director
            $returnObject | Add-Member -Type NoteProperty -Name Writer  -Value $IMDBMovieInfo.Writer
            $returnObject | Add-Member -Type NoteProperty -Name Actors -Value $IMDBMovieInfo.Actors
            $returnObject | Add-Member -Type NoteProperty -Name Plot -Value $IMDBMovieInfo.Plot
            $returnObject | Add-Member -Type NoteProperty -Name Language -Value $IMDBMovieInfo.Language
            $returnObject | Add-Member -Type NoteProperty -Name Country -Value $IMDBMovieInfo.Country 
            $returnObject | Add-Member -Type NoteProperty -Name Awards -Value $IMDBMovieInfo.Awards
            $returnObject | Add-Member -Type NoteProperty -Name Poster  -Value $IMDBMovieInfo.Poster
            $returnObject | Add-Member -Type NoteProperty -Name Ratings  -Value $IMDBMovieInfo.Ratings
            $returnObject | Add-Member -Type NoteProperty -Name Metascore -Value $IMDBMovieInfo.Metascore
            $returnObject | Add-Member -Type NoteProperty -Name imdbRating -Value $IMDBMovieInfo.imdbRating 
            $returnObject | Add-Member -Type NoteProperty -Name imdbVotes  -Value $IMDBMovieInfo.imdbVotes
            $returnObject | Add-Member -Type NoteProperty -Name imdbID  -Value $IMDBMovieInfo.imdbID
            $returnObject | Add-Member -Type NoteProperty -Name Type  -Value $IMDBMovieInfo.Type
            $returnObject | Add-Member -Type NoteProperty -Name DVD  -Value $IMDBMovieInfo.DVD
            $returnObject | Add-Member -Type NoteProperty -Name BoxOffice  -Value $IMDBMovieInfo.BoxOffice
            $returnObject | Add-Member -Type NoteProperty -Name Production -Value $IMDBMovieInfo.Production
            $returnObject | Add-Member -Type NoteProperty -Name Website  -Value $IMDBMovieInfo.Website
            
            $returnObject | Add-Member -Type NoteProperty -Name TotalVotes -Value $TMDBMovieInfo.TotalVotes
            $returnObject | Add-Member -Type NoteProperty -Name tmdbID -Value $TMDBMovieInfo.tmdbID
            $returnObject | Add-Member -Type NoteProperty -Name Video -Value $TMDBMovieInfo.Video
            $returnObject | Add-Member -Type NoteProperty -Name VoteAverage -Value $TMDBMovieInfo.VoteAverage
            #$returnObject | Add-Member -Type NoteProperty -Name Title -Value $TMDBMovieInfo.title
            $returnObject | Add-Member -Type NoteProperty -Name Popularity -Value $TMDBMovieInfo.popularity
            #$returnObject | Add-Member -Type NoteProperty -Name Poster -Value $TMDBMovieInfo.Poster
            #$returnObject | Add-Member -Type NoteProperty -Name Language -Value $TMDBMovieInfo.Language
            $returnObject | Add-Member -Type NoteProperty -Name OriginalTitle -Value $TMDBMovieInfo.OriginalTitle
            $returnObject | Add-Member -Type NoteProperty -Name Genres -Value $TMDBMovieInfo.Genres
            $returnObject | Add-Member -Type NoteProperty -Name Backdrop -Value $TMDBMovieInfo.Backdrop
            $returnObject | Add-Member -Type NoteProperty -Name Adult -Value $TMDBMovieInfo.Adult
            $returnObject | Add-Member -Type NoteProperty -Name Overview -Value $TMDBMovieInfo.overview
            $returnObject | Add-Member -Type NoteProperty -Name ReleaseDate -Value $TMDBMovieInfo.ReleaseDate
            $returnObjects += $returnObject

            return $returnObjects
        }

        #if a title was found and boolean return WAS specified
        ElseIf($ReturnBoolean -and $MatchedMovieTitle){
            return $true
        }

        #if a title was NOT found and boolean return WAS specified
        ElseIf($ReturnBoolean -and !$MatchedMovieTitle){
            return $false
        }

        #all else return null
        Else{
            return $null
        }
    }
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
. "$ExtensionPath\SupportFunctions.ps1"
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
[boolean]$FindMissingOnly = [boolean]::Parse($ScriptSettings.FindMissingOnly)
[boolean]$UpdateNfoData = [boolean]::Parse($ScriptSettings.UpdateNfoData)
[boolean]$UpdateJustMovieSeries = [boolean]::Parse($ScriptSettings.UpdateMovieSeriesOnly)
[int32]$UseRecentStoredDataDays = $ScriptSettings.UseRecentStoredDataDays


[datetime]$StoreData = $currentDateTime.AddDays(-$UseRecentStoredData)
If($UseRecentStoredDataDays -gt 0){$UseLocalizedStoredData = $true}Else{$UseLocalizedStoredData = $false}

#Reset variables
$Global:UnmatchedMovieReport = @()
$Global:ExistingMovieReport = @()
$Global:WrongMovieReport = @()
$Global:NoMovieInfoReport = @()
$Global:FailedMovieReport = @()

$Global:UpdatedMovieReport = @()
$Global:RemovedMovieReport = @()
$Global:AddedMovieReport = @()

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
    Write-Host "Grabbing all movie Genre folders" -NoNewline
    $Global:AllMoviesGenres = Get-ChildItem $MoviesDir -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $true}
    Write-Host ("...Found {0}" -f $AllMoviesGenres.Count) -ForegroundColor Cyan

    #build radarr list
    Write-Host "Grabbing all movies in Radarr..." -NoNewline
    $Global:RadarrMovies = Get-AllRadarrMovies -Api $radarrAPIkey -AsObject
}

#get list of movie folders within the genre folders
Write-Host "Grabbing all movie folders..." -NoNewline
$AllMoviesFolders = $Global:AllMoviesGenres | %{Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Where-Object { ($_.PSIsContainer -eq $true)} | Select Name, FullName} 
Write-Host ("Found {0}" -f $AllMoviesFolders.Count)

#update just the series section?
If($UpdateJustMovieSeries){
    Write-Host "Comparing all movie series on disk to what is in Radarr" -NoNewline
    #only get the movie sets located in collection folders
    $movieFilter = $AllMoviesFolders | Where-Object {$_.FullName -match "Collection" -or $_.FullName -match "Anthology" -or $_.FullName -match "Screeners"} 
}
Else{
    Write-Host "Comparing all movies on disk to what is in Radarr" -NoNewline
    #get list of movie folders within the genre folders
    #do not include collection folders
    $movieFilter = ($AllMoviesFolders | Where-Object {$_.Name -notlike "*Collection*"} | Where-Object {$_.Name -notlike "*Anthology*"} | Where {$_.Name -notlike "*Screeners"} )
}

Write-Host ("...Found {0}" -f $movieFilter.Count) -ForegroundColor Cyan
Write-Host "============================================="

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
        }
        Else{
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

#test movie
#$movie = $movieFilter[1364]

foreach ($Movie in $movieFilter)
{
    #clear values after each loop
    $MovieInfo = @()
    $SearchForMovie = $true
    $AddMovietoRadarr = $false
    $UpdateMovieinRadarr = $false
    $UpdateMoviePathinRadarr = $false
    $UpdateMovieTitleinRadarr = $false

    Write-Host "---------------------------------------" -ForegroundColor Gray
    Write-Host ("Processing Movie [{0}]" -f $Movie.Name) -ForegroundColor Cyan
    
    # BUILD SEARCHABLE TITLES
    # ==============================
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

    #remove unsupported characters for easier search results
    #replace the Ã© with e (pokemon titles)
    $MovieTitleCleaned = $MovieTitle.replace('Ã©','e')
    
    #normailze any special characters such as: å,ä,ö,Ã,Å,Ä,Ö,é
    $MovieTitleCleaned = $MovieTitleCleaned.Normalize("FormD") -replace '\p{M}'
    
    #remove double spaces
    $MovieTitleCleaned = $MovieTitleCleaned -replace'\s+', ' '

    #replace & with and
    $MovieTitleCleaned = $MovieTitleCleaned.replace('&','and')

    #remove any special characters but keep apostraphe
    $MovieTitleNoSpecialChar = $MovieTitleCleaned -replace "[^{\p{L}\p{Nd}\'}]+", " "

    #remove all special characters even apostraphe
    $MovieTitleAllSpecialChar = $MovieTitleNoSpecialChar -replace "'", ""

    #remove all special characters and spaces
    $MovieTitleNoSpecialSpaces = $MovieTitleCleaned -replace '[^\p{L}\p{Nd}]', ''

    #does the title have a number in it like: Daddy's Home 2
    $MovieTitleConvertedToNum = Convert-WordToNumber $MovieTitleCleaned

    #does the title have a number in it like: Two men
    $MovieTitleConvertedToChar = Convert-NumberToWord $MovieTitleCleaned

    If($yearfound){
        $SearchYear = $Year
        $ParamHash = @{Year = $Year}
    }

    #Does the movie already exist in Radarr?
    $FoundRadarrMovieByTitle = $Global:RadarrMovies | Where {($_.title -eq $MovieTitle)} 

    #or is ther a movie path in Radarr with that name
    $FoundRadarrMovieByPath = $Global:RadarrMovies | Where {$_.path -eq $Movie.FullName}

    # DETERMINE ONLINE SEARCH NEEDED
    # ==============================
    # If set to true, validate the movie exists in radar and that everything is valid
    # If set to false, search IMDB / TMDB and compare it to Radarr's movie
    If($FindMissingOnly){
        
        #If title and path doesn't exist; do a search and add to Radarr
        If(!$FoundRadarrMovieByTitle -and !$FoundRadarrMovieByPath){
            Write-Host ("No Movie title and path [{0}] was found in Radarr..." -f $Movie.Name) -ForegroundColor Gray
            $AddMovietoRadarr = $true
        }

        #If title or path not found; do a search and update radarr
        ElseIf(!$FoundRadarrMovieByTitle -or !$FoundRadarrMovieByPath){
            Write-Host ("No Movie title or path [{0}] was found in Radarr..." -f $Movie.Name) -ForegroundColor Gray
            $UpdateMovieTitleinRadarr = $true
        }

        #or if Title results are not equal; do a search and update radarr
        ElseIf($FoundRadarrMovieByTitle.title -ne $FoundRadarrMovieByPath.title){
            Write-Host ("Movie TITLE when search by title [{0}] does not match movie TITLE when searched by path [{1}] was found in Radarr..." -f $FoundRadarrMovieByTitle.title,$FoundRadarrMovieByPath.title) -ForegroundColor Gray
            $UpdateMovieTitleinRadarr = $true
        }

        #or if path results are not equal; do a search and update radarr
        ElseIf($FoundRadarrMovieByTitle.Path -ne $FoundRadarrMovieByPath.Path){
            Write-Host ("Movie PATH when search by title [{0}] does not match movie PATH when searched by path [{1}] was found in Radarr..." -f $FoundRadarrMovieByTitle.Path,$FoundRadarrMovieByPath.Path) -ForegroundColor Gray
            $UpdateMoviePathinRadarr = $true
        }

        # After all checks, title and path are the same then there is no need to search online (or use up a OMDB api request)
        Else{
            $SearchForMovie = $false
        }
    }
    Else{
        #since we are forcing a search for all before 
        $SearchForMovie = $true
    }

    # DO SEARCH IF REQUIRED
    # =====================
    # if we need to search for a movie online
    If($SearchForMovie){
        #search for movie on imdb and tmdb
        $MovieInfo = Search-MovieTitle -Title $MovieTitle -AlternateTitles ($MovieTitleCleaned,$MovieTitleNoSpecialChar,$MovieTitleAllSpecialChar,$MovieTitleNoSpecialSpaces,$MovieTitleConvertedToNum,$MovieTitleConvertedToChar) @ParamHash -IMDBApiKey $OMDBAPI -TMDBApiKey $TMDBAPI
        
        #did we fins a movie online that matches the title
        If($MovieInfo){
            # Now search Radarr for a matching movie based on IMDB and TMDB
            $FoundRadarrMovieByIMDB = $Global:RadarrMovies | Where {($_.imdbId -eq $MovieInfo.imdbID) -and ($_.tmdbId -eq $MovieInfo.tmdbID)}

            #If IMDB title and radarr title found, determine a match
            If($FoundRadarrMovieByIMDB -and $FoundRadarrMovieByTitle){

                # if both titles don'y match, update radarr
                If($MovieInfo.Title -notmatch $FoundRadarrMovieByIMDB.Title){
                    $UpdateMovieinRadarr = $true
                }
                Else{
                    $AddMovietoRadarr = $false
                }
            }
        }
        Else{
            Write-Host ("Movie title [{0}] was not found online unable to add to Radarr..." -f $MovieTitle) -ForegroundColor Yellow
            $AddMovietoRadarr = $false
        }
    }
    Else{
        Write-Host ("No search is required for movie title [{0}], skipping..." -f $MovieTitle) -ForegroundColor Yellow
        $AddMovietoRadarr = $false
    }



    # ADD TO RADAAR IF SET
    # =====================
    If($UpdateMoviePathinRadarr){
        $Global:UpdatedMovieReport += $FoundRadarrMovieByTitle | Update-RadarrMoviePath -ActualPath $Movie.FullName -Api $radarrAPIkey -Report
       
    }

    If($UpdateMovieTitleinRadarr){
        $Global:RemovedMovieReport += $FoundRadarrMovieByTitle | Remove-RadarrMovie -Api $radarrAPIkey -Report
        $Global:RemovedMovieReport += $FoundRadarrMovieByPath | Remove-RadarrMovie -Api $radarrAPIkey -Report
        $AddMovietoRadarr = $true
    }

    If($UpdateMovieinRadarr){
        $Global:RemovedMovieReport += $FoundRadarrMovieByTitle | Remove-RadarrMovie -Api $radarrAPIkey -Report
        $AddMovietoRadarr = $true
    }

    If($MovieInfo -and $AddMovietoRadarr){
        $Global:AddedMovieReport += $MovieInfo | Add-RadarrMovie -Path $Movie.FullName -Api $radarrAPIkey -SearchAfterImport -Report
    }
    start-sleep 3
}

<#build radarr list
Write-Host "Grabbing all movies in Radarr again..."
$RadarrGetArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                URI = "http://${radarrURL}:${radarrPort}/api/movie"
                Method = "Get"
            }
$radarrWebRequest = Invoke-WebRequest @RadarrGetArgs
$Global:RadarrMovies = $radarrWebRequest.Content | ConvertFrom-Json
#>
Write-Host ("Updated Movies   :") -ForegroundColor Gray -NoNewline
    Write-Host (" {0}" -f $Global:UpdatedMovieReport.Count)
Write-Host ("Removed Movies   :") -ForegroundColor Gray -NoNewline
    Write-Host (" {0}" -f $Global:RemovedMovieReport.Count)
Write-Host ("Added Movies      :") -ForegroundColor Gray -NoNewline
            Write-Host (" {0}" -f $Global:AddedMovieReport.Count)

