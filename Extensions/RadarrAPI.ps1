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


