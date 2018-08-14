Function Get-RadarrMovie{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Id,

        [Parameter(Mandatory=$true)]
        [string]$Api
    )
    Begin{
        [string]$URL = "http://localhost:7878"
    }
    Process {
        $Args = @{Headers = @{"X-Api-Key" = $Api}
                    URI = "$URL/api/id/$Id"
                    Method = "Get"
        }
        Write-Verbose $Args.URI

        try {
            Invoke-WebRequest @Args | Out-Null
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}


#Remove all movies
Function Remove-RadarrMovies{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [switch]$AllUnmonitored,

        [Parameter(Mandatory=$true)]
        [string]$Api
    )
    Begin{
        [string]$URL = "http://localhost:7878"
    }
    Process {
        $removeMovies = @()
        If($AllUnmonitored){
            $i=1
            while ($i -le 500) {
                $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                            URI = "http://$URL/api/movie/.$i"
                    }

                try {
                    $movie = Invoke-WebRequest @iwrArgs | Select-Object -ExpandProperty Content | ConvertFrom-Json
                    if ($movie.downloaded -eq $true -or $movie.monitored -eq $false) {
                        Write-Host "Adding $($movie.title) to list of movies to be removed." -ForegroundColor Red
                        $removeMovies += $movie
                    }
                    else {
                        Write-Host "$($movie.title) is monitored. Skipping." -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Verbose "Empty ID#$i or bad request"
                }
                $i++

            }
        }
        Else{

        }
        Write-Host "Proceeding to remove $($removeMovies.count) movies!" -ForegroundColor Cyan

        foreach ($downloadedMovie in $removeMovies){
            $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://$URL/api/movie/.$($downloadedMovie.id)"
                    Method = "Delete"
            }

            Invoke-WebRequest @iwrArgs | Out-Null
            Write-Host "Removed $($downloadedMovie.title)!" -ForegroundColor Green
        }
    }            
}


Function Get-RadarrMovies{
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [string]$URL,

        [Parameter(Mandatory=$true)]
        [string]$Api
    )

    process {
        $Args = @{Headers = @{"X-Api-Key" = $Api}
                    URI = "$URL/api/movie"
                    Method = "Get"
        }

        try {
            $movies = Invoke-WebRequest @Args
            return $movies.Content | ConvertFrom-Json
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}


#Radarr API Commands

<#rescan movies
$movie_id = $env:radarr_movie_id
$params = @{"name"="RescanMovie";"movieId"="$movie_id";} | ConvertTo-Json
Invoke-WebRequest -Uri "$radarrURL:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

#find an movied in drone factory folder
$params = @{"name"="DownloadedMoviesScan"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

#find missing movies
$params = @{"name"="missingMoviesSearch";"filterKey"="status";"filterValue"="released"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

$MovieName = 
    $MovieRootPath = 'E:\Media\Movies\Superhero & Comics\Thor Collection\Thor - Ragnarok (2017)'

    $Body = @{ title="Thor: Ragnarok";
                qualityProfileId="1";
                year=2017;
                tmdbid="284053";
                titleslug="thor: ragnarok-284053";
                monitored="true";
                path=$MovieRootPath;
                images=@( @{
                    covertype="poster";
                    url="https://image.tmdb.org/t/p/w174_and_h261_bestv2/avy7IR8UMlIIyE2BPCI4plW4Csc.jpg"
                } )
             }


    $BodyObj = ConvertTo-Json -InputObject $Body

    $BodyArray = ConvertFrom-Json -InputObject $BodyObj

    $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "http://${radarrURL}:${radarrPort}/api/movie"
                    Method = "POST"
            }

        Invoke-WebRequest @iwrArgs -Body $BodyObj | Out-Null

curl -H "Content-Type: application/json" -X POST -d '{"title":"Thor: Ragnarok","qualityProfileId":"6","tmdbid":"284053","titleslug":"thor: ragnarok-284053", "monitored":"true", "rootFolderPath":"H:/Video/Movies/", "images":[{"covertype":"poster","url":"https://image.tmdb.org/t/p/w174_and_h261_bestv2/avy7IR8UMlIIyE2BPCI4plW4Csc.jpg"}]}' http://192.168.1.111/radarr/api/movie?apikey=xxxxx
curl -H "Content-Type: application/json" -X POST -d '{"title":"Proof","qualityProfileId":"4","apikey":"[MYAPIKEY]", "tmdbid":"14904","titleslug":"proof-14904", "monitored":"true", "rootFolderPath":"/Volume1/Movies/", "images":[{"covertype":"poster","url":"https://image.tmdb.org/t/p/w640/ghPbOsvg8WrJQBSThtNakBGuDi4.jpg"}]}' http://192.168.1.10:8310/api/movie
#>