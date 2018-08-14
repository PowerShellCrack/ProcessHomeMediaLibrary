<#
Imdb info

Title      : Red Dragon
Year       : 2002
Rated      : R
Released   : 04 Oct 2002
Runtime    : 124 min
Genre      : Crime, Drama, Thriller
Director   : Brett Ratner
Writer     : Thomas Harris (novel), Ted Tally (screenplay)
Actors     : Anthony Hopkins, Edward Norton, Ralph Fiennes, Harvey Keitel
Plot       : A retired F.B.I. Agent with psychological gifts is assigned to help track down "The Tooth Fairy", a mysterious serial killer. Aiding him is imprisoned forensic psychiatrist Dr. Hannibal "The Cannibal"
             Lecter.
Language   : English, French
Country    : Germany, USA
Awards     : 4 wins & 10 nominations.
Poster     : https://m.media-amazon.com/images/M/MV5BMTQ4MDgzNjM5MF5BMl5BanBnXkFtZTYwMjUwMzY2._V1_SX300.jpg
Ratings    : {@{Source=Internet Movie Database; Value=7.2/10}, @{Source=Rotten Tomatoes; Value=68%}, @{Source=Metacritic; Value=60/100}}
Metascore  : 60
imdbRating : 7.2
imdbVotes  : 222,645
imdbID     : tt0289765
Type       : movie
DVD        : 01 Apr 2003
BoxOffice  : $92,930,005
Production : Universal Pictures
Website    : http://www.reddragonmovie.com/
Response   : True
#>


Function Set-VideoNFO{
    [CmdletBinding()]
    Param
    (
    [string]$MovieFolder,
    [string]$imdbAPI,
    [string]$tmdbAPI,
    [string]$FFProbePath = 'D:\Data\Plex\DVRPostProcessingScript\ffmpeg\bin\ffprobe.exe'
    )

    $date = get-date -Format "yyy-MM-dd hh:mm:ss"

    $movie = Split-Path $MovieFolder -Leaf
    $yearfound = $MovieFolder -match ".?\((.*?)\).*"
    $MovieYear = $matches[1]
    $SearchMovieName = ($movie).replace("($MovieYear)","").Trim()
    $MovieFound = Get-ChildItem $MovieFolder -Include ('*.mp4','*.mkv','*.mpeg','*.mpg','*.avi','*.wmv') -Recurse
    If($MovieFound){
        [string]$NfoMovieName = [IO.Path]::GetFileNameWithoutExtension($MovieFound.Name)
        $MovieInfoFullPath = $MovieFolder + "\" + $NfoMovieName + ".nfo"
        $inCollection = $MovieFolder | Where-Object {$_.FullName -match "Collection" -or $_.FullName -match "Anthology"} 
        $matches.Values

        $IMDB = Get-ImdbTitle -Title $SearchMovieName -Api $OMDBAPI -Year $MovieYear
        If($IMDB){
            $IMDBItem = Get-IMDBItem $IMDB.imdbID
            $IMDBMovie = Get-ImdbMovie -Title $SearchMovieName -Year $MovieYear
            $TMDBMovie = Find-TMDBItem -Type Movie -SearchAction ByType -ApiKey $TMDBAPI -Title $SearchMovieName -Year $MovieYear
            If($TMDBMovie){$tmdbid = $TMDBMovie.id}
        }Else{
            Return
        }
    }
    Else{
        return
    }

    

    $xml = $null
    $xml += "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>";$xml += "`r`n"
    $xml += "<!-- created on $date - powershell videoparser -->";$xml += "`r`n"
    $xml += "<movie>";$xml += "`r`n"
    $xml += "   <title>$($IMDB.Title)</title>";$xml += "`r`n"
    $xml += "   <originaltitle>$($IMDB.Title)</originaltitle>";$xml += "`r`n"
    If($inCollection){
        $xml += "   <set>";$xml += "`r`n"
        $xml += "       <name>$($matches.Values)</name>";$xml += "`r`n"
        $xml += "       <overview>$SetOverview</overview>";$xml += "`r`n"
        $xml += "   </set>";$xml += "`r`n"
    }
    $xml += "   <sorttitle></sorttitle>";$xml += "`r`n"
    $xml += "   <rating>$($IMDB.imdbRating)</rating>";$xml += "`r`n"
    $xml += "   <year>$($IMDB.Year)</year>";$xml += "`r`n"
    $xml += "   <top250>$top250</top250>";$xml += "`r`n"
    $xml += "   <votes>$($IMDB.imdbVotes)</votes>";$xml += "`r`n"
    $xml += "   <outline>$($IMDB.Plot)</outline>";$xml += "`r`n"
    $xml += "   <plot>$($IMDB.Plot)</plot>";$xml += "`r`n"
    $xml += "   <tagline>$($IMDBMovie.Taglines)</tagline>";$xml += "`r`n"
    $xml += "   <runtime>$($IMDB.Runtime)</runtime>";$xml += "`r`n"
    $xml += "   <thumb>$($TMDBMovie.Poster)</thumb>";$xml += "`r`n"
    $xml += "   <fanart>$($TMDBMovie.Backdrop)</fanart>";$xml += "`r`n"
    $xml += "   <mpaa>$($IMDB.Rated)</mpaa>";$xml += "`r`n"
    $xml += "   <certification>$certification</certification>";$xml += "`r`n"
    $xml += "   <id>$($IMDBItem.MPAARating)</id>";$xml += "`r`n"
    $xml += "   <ids>";$xml += "`r`n"
    $xml += "       <entry>";$xml += "`r`n"
    $xml += "           <key>imdb</key>";$xml += "`r`n"
    $xml += "           <value xsi:type='xs:string' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>$($IMDB.imdbid)</value>";$xml += "`r`n"
    $xml += "       </entry>";$xml += "`r`n"
    If($tmdbid){
        $xml += "       <entry>";$xml += "`r`n"
        $xml += "           <key>tmdb</key>";$xml += "`r`n"
        $xml += "           <value xsi:type='xs:int' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>$($TMDBMovie.id)</value>";$xml += "`r`n"
        $xml += "       </entry>";$xml += "`r`n"
        If($inCollection){
            $xml += "       <entry>";$xml += "`r`n"
            $xml += "           <key>tmdbSet</key>";$xml += "`r`n"
            $xml += "           <value xsi:type='xs:int' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>$tmdbsetid</value>";$xml += "`r`n"
            $xml += "       </entry>";$xml += "`r`n"
        }
    }
    $xml += "   </ids>";$xml += "`r`n"
    $xml += "   <tmdbId>$($TMDBMovie.id)</tmdbId>";$xml += "`r`n"
    $xml += "   <trailer>$($IMDBMovie.Link)</trailer>";$xml += "`r`n"
    $xml += "   <country>$($IMDB.country)</country>";$xml += "`r`n"
    $xml += "   <premiered>>$($IMDB.Released)</premiered>";$xml += "`r`n"
    If($fileinfo){
        $xml += "   <fileinfo>";$xml += "`r`n"
        $xml += "       <streamdetails>";$xml += "`r`n"
        $xml += "           <video>";$xml += "`r`n"
        $xml += "               <codec>$vidcodec</codec>";$xml += "`r`n"
        $xml += "               <aspect>$sapect</aspect>";$xml += "`r`n"
        $xml += "               <width>$width</width>";$xml += "`r`n"
        $xml += "               <height>$height</height>";$xml += "`r`n"
        $xml += "               <durationinseconds>5546</durationinseconds>";$xml += "`r`n"
        $xml += "           </video>";$xml += "`r`n"
        Foreach($audio in $audiochanels){
            $xml += "           <audio>";$xml += "`r`n"
            $xml += "               <codec>$($audio.codec)</codec>";$xml += "`r`n"
            $xml += "               <language>$($audio.language)</language>";$xml += "`r`n"
            $xml += "               <channels>$($audio.channel)</channels>";$xml += "`r`n"
            $xml += "           </audio>";$xml += "`r`n"
        }
        $xml += "           <subtitle>";$xml += "`r`n"
        $xml += "               <language>$fileinfolang</language>";$xml += "`r`n"
        $xml += "           </subtitle>";$xml += "`r`n"
        $xml += "       </streamdetails>";$xml += "`r`n"
        $xml += "   </fileinfo>";$xml += "`r`n"
    }
    $xml += "   <watched>$watched</watched>";$xml += "`r`n"
    $xml += "   <playcount>$playcount</playcount>";$xml += "`r`n"
    Foreach($genre in $IMDB.Genre){
        $xml += "   <genre>$genre</genre>";$xml += "`r`n"
    }
    Foreach($studio in ($IMDBMovie.Production -split ",").Trim()){
        $xml += "   <studio>$studio</studio>";$xml += "`r`n"
    }
    Foreach($credit in $credits){
        $xml += "   <credits>$credit</credits>";$xml += "`r`n"
    }
    $xml += "   <director>$($IMDB.Director)</director>";$xml += "`r`n"
    Foreach($actor in $IMDB.actors){
        $xml += "   <actor>";$xml += "`r`n"
        $xml += "       <name>$actor</name>";$xml += "`r`n"
        $xml += "       <thumb>$($actor.thumb)</thumb>";$xml += "`r`n"
        $xml += "   </actor>";$xml += "`r`n"
    }
    Foreach($writer in ($IMDB.Writer -split ",").Trim()){
        $xml += "   <writer>";$xml += "`r`n"
        $xml += "       <name>$writer</name>";$xml += "`r`n"
        $xml += "   </writer>";$xml += "`r`n"
    }
    Foreach($producer in $IMDB.producer){
        $xml += "   <producer>";$xml += "`r`n"
        $xml += "       <name>$producer</name>";$xml += "`r`n"
        $xml += "   </producer>";$xml += "`r`n"
    }
    $xml += "   <languages>$($IMDB.language)</languages>";$xml += "`r`n"
    $xml += "</movie>";$xml += "`r`n"
    $xml | Out-File -FilePath $MovieInfoFullPath -Force
}

Function Get-VideoNFO{
    Param(
    [string]$MovieFolder
    )

    $MovieNfoFound = Get-ChildItem $MovieFolder -Include '*.nfo' -Recurse | Select -First 1
    If($MovieNfoFound){
        [xml]$NfoFile = Get-Content $MovieNfoFound
        [array]$Genres = ($NfoFile.movie.genre) -join ", "
        [string]$Languages = ($NfoFile.movie.languages) -join ", "
        [string]$Actors = ($NfoFile.movie.actor.Name | Select -First 4) -join ", "
        [string]$Writers = ($NfoFile.movie.writers.Name.writers | Select -First 4) -join ", "
        [string]$Producers = ($NfoFile.movie.producer.Name) -join ", "
        [string]$Countries = ($NfoFile.movie.country) -join ", "
        [string]$Studios = ($NfoFile.movie.studio) -join ", "
        If($NfoFile.movie.durationminutes){$duration = ($NfoFile.movie.durationminutes + ' min')}
        Else{$duration = ($NfoFile.movie.runtime + ' min')}
        If($NfoFile.movie.cover.name){
            $cover = $NfoFile.movie.cover.name | Select -First 1
        }
        $formattedDate = Get-Date($NfoFile.movie.premiered) -Format 'dd MMM yyyy'
        [string]$ReleaseDate = [DateTime]::ParseExact(($NfoFile.movie.releasedate.'#text').replace('.','/'), 'dd\/MM\/yyyy',[Globalization.CultureInfo]::InvariantCulture)
        $formattedReleasedDate = Get-Date($ReleaseDate) -Format 'dd MMM yyyy'

        $returnObject = New-Object System.Object
        $returnObject | Add-Member -Type NoteProperty -Name Title -Value $NfoFile.movie.title
        $returnObject | Add-Member -Type NoteProperty -Name Year -Value $NfoFile.movie.year
        $returnObject | Add-Member -Type NoteProperty -Name MPAARating -Value $NfoFile.movie.mpaa
        $returnObject | Add-Member -Type NoteProperty -Name Released -Value $formattedDate
        $returnObject | Add-Member -Type NoteProperty -Name RuntimeMinutes -Value $duration
        $returnObject | Add-Member -Type NoteProperty -Name Director -Value $NfoFile.movie.director
        $returnObject | Add-Member -Type NoteProperty -Name Writers -Value $Writers
        $returnObject | Add-Member -Type NoteProperty -Name Producers -Value $Producers
        $returnObject | Add-Member -Type NoteProperty -Name Actors -Value $Actors
        $returnObject | Add-Member -Type NoteProperty -Name Plot -Value $NfoFile.movie.plot
        $returnObject | Add-Member -Type NoteProperty -Name Language -Value $Languages
        $returnObject | Add-Member -Type NoteProperty -Name Country -Value $Countries
        $returnObject | Add-Member -Type NoteProperty -Name Poster -Value $cover
        $returnObject | Add-Member -Type NoteProperty -Name imdbRating -Value $NfoFile.movie.rating
        $returnObject | Add-Member -Type NoteProperty -Name imdbVotes -Value $NfoFile.movie.votes
        $returnObject | Add-Member -Type NoteProperty -Name imdbID -Value $NfoFile.movie.id
        $returnObject | Add-Member -Type NoteProperty -Name tmdbID -Value $NfoFile.movie.tmdbId
        $returnObject | Add-Member -Type NoteProperty -Name Type -Value 'movie'
        $returnObject | Add-Member -Type NoteProperty -Name Genre -Value $Genres
        $returnObject | Add-Member -Type NoteProperty -Name ReleaseDate -Value $formattedReleasedDate
        $returnObject | Add-Member -Type NoteProperty -Name Production -Value $Studios
        If($NfoFile.movie.set.name){$returnObject | Add-Member -Type NoteProperty -Name Set -Value $NfoFile.movie.set.name}

        Write-Output $returnObject
    }
}