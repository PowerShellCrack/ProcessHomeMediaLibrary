<#
.Synopsis
    My original intentions wwas to write a script I coudl run regularly to 
    add movie series collections into Radarr, since it can't see deeper than 
    the root movie folder where my movie series are a subfolder of the root 
    movies in folders called " Collection" and " Anthology". These folders 
    were auto created when I ran TinyMediaManger (https://www.tinymediamanager.org/) 
    on my movies collections...I sson foudn out this broke Radarr's invnetory 
    and had to remvoe over 100+ movies. It was a pain. I then decided to wrtie this 
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
## Variables: Script Name and Script Paths
#[string]$scriptPath = 'D:\Data\Automation\Get-RadarrMovies.ps1' #TESTONLY
[string]$scriptPath = $MyInvocation.MyCommand.Definition
[string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$MainDir = Split-Path $scriptRoot -Parent

#Get paths
$LogDir = Join-Path $MainDir -ChildPath Logs
$StoredDataDir = Join-Path $MainDir -ChildPath StoredData

#generate log file
$FinalLogFileName = ($ScriptName.Trim(" ") + "_" + $RunningDate)
[string]$Logfile = Join-Path $LogDir -ChildPath "$FinalLogFileName.log"
#===============================================
# DECLARE VARIABLES
#===============================================
$radarrURL = 'localhost'
$radarrPort = "7878"
$radarrAPIkey = '<YOUR API KEY>'

$OMDBAPI = '<YOUR OMDB API KEY>'
$MoviesDir = "E:\Media\Movies" #Root path of movies

$TMDBAPI = "<YOUR TMDB API KEY>"

#Get Todays Date
$RunningDate = Get-Date -Format MMddyyyy

# Update Data Configs
$UpdateNfoData = $false
$UpdateJustMovieSeries = $false

#Import Script extensions
. "$scriptRoot\Extensions\Logging.ps1"
. "$scriptRoot\Extensions\ImdbMovieAPI.ps1"
. "$scriptRoot\Extensions\TmdbAPI.ps1"

#Set variables
$UnmatchedMovieReport = @()
$ExistingMovieReport = @()
$WrongMovieReport = @()
$AddedMovieReport = @()
$NoMovieInfoReport = @()
$FailedMovieReport = @()

#Basically this part check to see if the $AllMoviesGenres has data already
# good for testings instead of processing folders each time
If(!$AllMoviesGenres){
    #build list of movie genres from folder
    Write-Host "Grabbing all movie Genre folders..."
    $AllMoviesGenres =  Get-ChildItem $MoviesDir -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $true}

    #get list of movie folders within the genre folders
    Write-Host "Grabbing all movie folders..."
    $AllMoviesFolders = $AllMoviesGenres | %{Get-ChildItem $MoviesDir -Recurse -ErrorAction SilentlyContinue | Where-Object { ($_.PSIsContainer -eq $true)} | Select Name, FullName} 

    #only get the movie sets located in collection folders
    Write-Host "Grabbing all movie series folders..."
    $MovieSeries = $AllMoviesFolders | Where-Object {$_.FullName -match "Collection" -or $_.FullName -match "Anthology"} 

    #build radarr list
    Write-Host "Grabbing all movies in Radarr..."
    $RadarrGetArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://${radarrURL}:${radarrPort}/api/movie"
                    Method = "Get"
                }
    $radarrWebRequest = Invoke-WebRequest @RadarrGetArgs
    $radarrmovies = $radarrWebRequest.Content | ConvertFrom-Json
}

#If nfo file exists, compare nfo with movie to ensure its correct
#build array based on info found
If($UpdateNfoData){
    Write-Host "Checking all movies on disk for nfo files..."
    Foreach ($MoviesFolder in $AllMoviesFolders){
        #if folder is one of the genre folders, ignore
        If(Compare-Object $MoviesFolder.Name $AllMoviesGenres.Name -IncludeEqual -passThru | Where-Object { $_.SideIndicator -eq '==' }){
            Write-Host ("Ignoring movie genre folder: {0}" -f $MoviesFolder.Name) -ForegroundColor Gray
        }
        ElseIf(Compare-Object $MoviesFolder.Name $MovieSeries.Name -IncludeEqual -passThru | Where-Object { $_.SideIndicator -eq '==' }){
            Write-Host ("Ignoring movie series folders: {0}" -f $MoviesFolder.Name) -ForegroundColor Gray
        }Else{
            $NFOfileExist = Get-ChildItem $MoviesFolder.FullName -Filter *.nfo -Force -Recurse
            $yearfound = $MoviesFolder.Name -match ".?\((.*?)\).*"
            $year = $matches[1]
            $movieName = ($MoviesFolder.Name).replace("($year)","").Trim()
            If($NFOfileExist.Count -gt 1){
                Write-Host ("Found multiple Movie NFO files [{0}] for: {1}" -f $NFOfileExist.Count,$MoviesFolder.Name) -ForegroundColor Gray
            }
            ElseIf($NFOfileExist){
                Write-Host ("Movie NFO file exists for: {0}" -f $MoviesFolder.Name) -ForegroundColor Green
                [xml]$NFOxml = Get-Content $NFOfileExist.FullName
                If( !($NFOxml.movie.title -match $movieName) -and !($NFOxml.movie.year -match $year) ){
                    Write-Host ("Movie NFO file exists for: {0} but is invalid: {1} ({2})" -f $MoviesFolder.Name,$NFOxml.movie.title,$NFOxml.movie.year) -ForegroundColor Red
                }
            }Else{
                Write-Host ("No Movie NFO file exists for: {0}" -f $MoviesFolder.Name) -ForegroundColor Yellow
                Set-VideoNFO -MovieFolder $MoviesFolder.FullName -imdbAPI $OMDBAPI
            }
        }
    }
}


#testing only
#$Movie = $MovieSeries | Where-Object {$_.Name -notmatch "Collection" -and $_.Name -notmatch "Anthology"} | select -First 1
If($UpdateJustMovieSeries){
    $movieFilter = ($MovieSeries | Where-Object {$_.Name -notmatch "Collection" -and $_.Name -notmatch "Anthology"})
    Write-Host "Comparing all movie series on disk to what is in Radarr..."
}Else{
    $movieFilter = $AllMoviesFolders
    Write-Host "Comparing all movies on disk to what is in Radarr..."
}

foreach ($Movie in $movieFilter)
{
    Write-Host "---------------------------------------" -ForegroundColor Cyan
    Write-Host ("Processing Movie [{0}]" -f $Movie.Name) -ForegroundColor Cyan
    $yearfound = $Movie.Name -match ".?\((.*?)\).*"
    If($yearfound)
    {
        $year = $matches[1]
        $movieName = ($Movie.Name).replace("($year)","").Trim()
    }
    Else{
        $movieName = $Movie.Name
    }

    #remove unsupported characters for easier search results
    #normailze any special characters such as: å,ä,ö,Ã,Å,Ä,Ö,é
    $movieName = $movieName.Normalize("FormD") -replace '\p{M}'
    
    #replace the Ã© with e (pokemon titles)
    $movieName = $movieName.replace('Ã©','e')

    #remove any special characters but keep apstraphe '
    $Regex = "[^{\p{L}\p{Nd}\'}]+"
    If($movieName -match $Regex)
    {
        $MovieValue = $movieName -replace $Regex, " "
    }
    Else{
        $MovieValue = $movieName
    }

    #remove double spaces
    $MovieValue = $MovieValue -replace'\s+', ' '

    #replace & with and
    $MovieValue = $MovieValue.replace('&','and')
    
    #get TMDB and IMDB information
    Write-Host ("Searching for movie [{0}] in IMDB and TMDB" -f $MovieValue) -ForegroundColor Yellow
    If($yearfound)
    {
        $IMDBMovieInfo = Get-ImdbTitle -Title $MovieValue -Year $year -Api $OMDBAPI -ErrorAction SilentlyContinue
        $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieValue -Year $year -ApiKey $TMDBAPI -SelectFirst -ErrorAction SilentlyContinue
    }
    Else{
        $IMDBMovieInfo = Get-ImdbTitle -Title $MovieValue -Api $OMDBAPI -ErrorAction SilentlyContinue
        $TMDBMovieInfo = Find-TMDBItem -Type Movie -SearchAction ByType -Title $MovieValue -ApiKey $TMDBAPI  -SelectFirst -ErrorAction SilentlyContinue
    }
    If($IMDBMovieInfo){Write-Host ("   IMDB movie found was [{0}]" -f $IMDBMovieInfo.Title) -ForegroundColor DarkYellow}Else{Write-Host "   IMDB movie was not found" -ForegroundColor DarkRed}
    If($TMDBMovieInfo){Write-Host ("   TMDB movie found was [{0}]" -f $TMDBMovieInfo.Title) -ForegroundColor DarkYellow}Else{Write-Host "   TMDB movie was not found" -ForegroundColor DarkRed}

    If($IMDBMovieInfo -and $TMDBMovieInfo){
        #if both IMDB and TMDB has the same title continue, if not stop that one and go to next
        #format the titles so that there are no special characters to spaces to ensure it a good match
        $CleanIMDBTitle = ($IMDBMovieInfo.Title -replace '[\W]', '').ToLower()
        $CleanTMDBTitle = ($TMDBMovieInfo.Title -replace '[\W]', '').ToLower()
        
        If($CleanIMDBTitle -ne $CleanTMDBTitle){
            Write-Host ("Movie information does not match from TMDB and IMDB. Unable to parse correctly, skipping..." -f $IMDBMovieInfo.Title) -ForegroundColor Red
            $UnmatchedMovie = New-Object System.Object
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name SearchName -Value $MovieValue
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name SearchYear -Value $year
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbID -Value $IMDBMovieInfo.imdbID
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbTitle -Value $IMDBMovieInfo.title
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name ImdbYear -Value $IMDBMovieInfo.year
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name TmdbID -Value $TMDBMovieInfo.tmdbID
            $UnmatchedMovie | Add-Member -Type NoteProperty -Name TmdbTitle -Value $TMDBMovieInfo.Title
            #add to another array for reporting
            $UnmatchedMovieReport += $UnmatchedMovie
            $AddMovietoRadarr = $false
            Continue
            #break
        }Else{
            Write-Host ("Found matching movie information for [{0}] from both TMDB and IMDB." -f $IMDBMovieInfo.Title) -ForegroundColor Green
        }
    }
    Else{
        Write-Host ("Not enough information was found for [{0}]. Unable to add to Radarr." -f $MovieValue) -ForegroundColor Red
        $NoMovieInfo = New-Object System.Object
        $NoMovieInfo | Add-Member -Type NoteProperty -Name SearchName -Value $MovieValue
        $NoMovieInfo | Add-Member -Type NoteProperty -Name SearchYear -Value $year
        $NoMovieInfo | Add-Member -Type NoteProperty -Name ImdbID -Value $IMDBMovieInfo.imdbID
        $NoMovieInfo | Add-Member -Type NoteProperty -Name TmdbID -Value $TMDBMovieInfo.tmdbID
        #add to another array for reporting
        $NoMovieInfoReport += $NoMovieInfo
        $AddMovietoRadarr = $false
        Continue
        #break
    }

    #replace movie titles that have a - with :
    #$RealMovieName = $movieName.replace(" -",":")
    $RealMovieName = $MovieValue

    #now determine if radarr has a matching movie based on IMDB and its path
    $ImdbInRadarr = $radarrmovies | Where {($_.imdbId -eq $IMDBMovieInfo.imdbID) -and ($_.tmdbId -eq $TMDBMovieInfo.tmdbID)}
    $PathInRadarr = $radarrmovies | Where {$_.path -eq $Movie.FullName}
    If($ImdbInRadarr -or $PathInRadarr){
        $AddMovietoRadarr = $false
        #Compare imdb in search vs Radarr imdb is path exists in Radarr
        #if its the wrong imdb add it the report. FUTURE is to fix it
        If($PathInRadarr -and ($PathInRadarr.imdbID -ne $IMDBMovieInfo.imdbID) ){
            Write-Host ("Movie [{0}] name is incorrect, remove from Radarr to reprocess" -f $RealMovieName) -ForegroundColor Red
            Write-Host ("   Actual Name: {0}" -f $IMDBMovieInfo.Title)
            Write-Host ("   Actual Imdb: {0}" -f $IMDBMovieInfo.imdbId)
            Write-Host ("   Radarr Name: {0}" -f $PathInRadarr.title)
            Write-Host ("   Radarr Imdb: {0}" -f $PathInRadarr.imdbId)

            $deleteMovieArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://${radarrURL}:${radarrPort}/api/movie/$($PathInRadarr.ID)"
                    Method = "Delete"
            }

            Invoke-WebRequest @deleteMovieArgs | Out-Null
            Start-sleep 3
            $AddMovietoRadarr = $true
        }
        #since both IMDB matched, check its video path to ensure its that right video
        #if its the wrong path add it the report. FUTURE is to fix it
        ElseIf("$($ImdbInRadarr.Path)" -ne "$($Movie.FullName)"){
            Write-Host ("Movie [{0}] path is incorrect, updating Radarr's path" -f $RealMovieName) -ForegroundColor Red
            Write-Host ("   Actual Path: {0}" -f $Movie.FullName)
            Write-Host ("   Radarr Path: {0}" -f $ImdbInRadarr.Path)

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
            $WrongMovieReport += $WrongMovie

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
                    Invoke-WebRequest @RadarrUpdateMovieID -Body $body | Out-Null
            #Break
        }
        Else{
            Write-Host ("Movie [{0}] was found in Radarr's database, ignoring" -f $RealMovieName) -ForegroundColor Green
            $ExistingMovie = New-Object System.Object
            $ExistingMovie | Add-Member -Type NoteProperty -Name id -Value $ImdbInRadarr.id
            $ExistingMovie | Add-Member -Type NoteProperty -Name Title -Value $ImdbInRadarr.title 
            $ExistingMovie | Add-Member -Type NoteProperty -Name year -Value $ImdbInRadarr.year
            $ExistingMovie | Add-Member -Type NoteProperty -Name RadarrURL -Value ('http://'+ $radarrURL + ':' + $radarrPort +'/movie/' + $ImdbInRadarr.titleSlug)
            #add to another array for reporting
            $ExistingMovieReport += $ExistingMovie
        }
    }
    Else{
        Write-Host ("Movie [{0}] was not found in Radarr's database, adding to Radarr..." -f $RealMovieName) -ForegroundColor DarkBlue
        $AddMovietoRadarr = $true
    }


    If($AddMovietoRadarr)
    {
        Write-Host ("Found Movie Information for {0}" -f $IMDBMovieInfo.Title)
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

        Write-Host ("Adding movie to Radarr: {0}" -f $actualName) -ForegroundColor Gray
        Write-Host ("   Path: {0}" -f $MovieRootPath)
        Write-Host ("   Imdb: {0}" -f $imdbID)
        Write-Host ("   Tmdb: {0}" -f $tmdbID)
        Write-Host ("   Slug: {0}" -f $titleSlug)
        Write-Host ("   Year: {0}" -f $ActualYear)

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
            images=@( @{
                covertype="poster";
                url=$Image
            } )
        }
        $BodyObj = ConvertTo-Json -InputObject $Body #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        #$BodyArray = ConvertFrom-Json -InputObject $BodyObj

        $RadarrPostArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                        URI = "http://${radarrURL}:${radarrPort}/api/movie"
                        Method = "Post"
                }
        try
        {
            Invoke-WebRequest @RadarrPostArgs -Body $BodyObj | Out-Null

            $AddedMovie = New-Object System.Object
            $AddedMovie | Add-Member -Type NoteProperty -Name Title -Value $actualName
            $AddedMovie | Add-Member -Type NoteProperty -Name Year -Value $ActualYear
            $AddedMovie | Add-Member -Type NoteProperty -Name IMDB -Value $imdbID
            $AddedMovie | Add-Member -Type NoteProperty -Name TMDB -Value $tmdbID
            $AddedMovie | Add-Member -Type NoteProperty -Name TitleSlug -Value $titleslug
            $AddedMovie | Add-Member -Type NoteProperty -Name FolderPath -Value $MovieRootPath
            $AddedMovie | Add-Member -Type NoteProperty -Name RadarrPath -Value ('http://' + $radarrURL + ':' + $radarrPort + '/movie/' + $titleslug)
            #add to another array for reporting
            $AddedMovieReport += $AddedMovie
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
            $FailedMovieReport += $FailedMovie
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
$radarrmovies = $radarrWebRequest.Content | ConvertFrom-Json

Write-Host ("Existing Movies   : {0}" -f $ExistingMovieReport.Count)
Write-Host ("Unmatched Movies  : {0}" -f $UnmatchedMovieReport.Count)
Write-Host ("Wrong Movies      : {0}" -f $WrongMovieReport.Count)
Write-Host ("Added Movies      : {0}" -f $AddedMovieReport.Count)
Write-Host ("Failed Movies     : {0}" -f $FailedMovieReport.Count)
Write-Host ("No Info for Movie : {0}" -f $NoMovieInfoReport.Count)