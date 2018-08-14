
<#
.Synopsis
A quick and easy way to get information on Movies. 
This Script also has the ability to download movies using the Download-Movie function. 
The download function requires Qbittorrent to be installed on your computer.
As always, take care when downloading files from the internet. Please use a VPN service as needed.

.DESCRIPTION
Genre Options:

Action
Adventure
Animation
Biography
Comedy
Crime
Documentary
Drama
Family
Fantasy
History
Horror
Musical
Mystery
Romance
Sci_fi
Short
Sport
Thriller
War
Western

.EXAMPLE
    #####
   Get-Movie -Name Inception
.EXAMPLE
    #####
   Get-Movie Intersteller
.EXAMPLE
    #####
    Movies with a space in the name require the full name to be wrapped in single quotes. Get-Movie 'The Silence of the lambs'
.EXAMPLE
    #####
  Get-Movie -Genre Action
.EXAMPLE
    #####
   Movies with a space in the name require the full name to be wrapped in single quotes. Download-Movie 'Forrest Gump'
.FUNCTIONALITY
   This Cmdlet is used for gathering information about specific movies while also offering the ability to download any movie via bit torrent.
#>
function Get-Movie{
    [CmdletBinding()]
    Param
    (
    [string]$Name,
    [string][ValidateSet("Action",
                    "Adventure",
                    "Animation",
                    "Biography",
                    "Comedy",
                    "Crime",
                    "Documentary",
                    "Drama",
                    "Family",
                    "Fantasy",
                    "History",
                    "Horror",
                    "Musical",
                    "Mystery",
                    "Romance",
                    "Sci_fi",
                    "Short",
                    "Sport",
                    "Thriller",
                    "War",
                    "Western")]$Genre
    )   
 
    $RootWeb = 'http://www.imdb.com'



#Filter for genre param
if($PSBoundParameters.ContainsKey('Genre')){
        $Genre = $Genre.ToLower() 
        $GenreNav = Invoke-WebRequest "http://www.imdb.com/search/title?genres=$($Genre)&title_type=feature&sort=moviemeter,asc"
        
                       
        Start-Sleep -seconds 2    
        $Filter = $GenreNav.links | select title
        Start-Sleep -seconds 1    
 
        Switch($Genre) {
        
               Action {$filter -match '\d{4}'}
               Adventure {$filter -match '\d{4}'}
               Animation {$filter -match '\d{4}'}
               Biography {$filter -match '\d{4}'}
               Comedy {$filter -match '\d{4}'}
               Crime {$filter -match '\d{4}'}
               Documentary {$filter -match '\d{4}'}
               Drama {$filter -match '\d{4}'}
               Family {$filter -match '\d{4}'}
               Fantasy {$filter -match '\d{4}'}
               History {$filter -match '\d{4}'}
               Horror {$filter -match '\d{4}'}
               Musical {$filter -match '\d{4}'}
               Mystery {$filter -match '\d{4}'}
               Romance {$filter -match '\d{4}'}
               Sci_fi {$filter -match '\d{4}'}
               Short {$filter -match '\d{4}'}
               Sport {$filter -match '\d{4}'}
               Thriller {$filter -match '\d{4}'}
               War {$filter -match '\d{4}'}
               Western {$filter -match '\d{4}'}
               Default {Write-Host "No such genre exists"}

            }
        }     
     
#single movie search
if($PSBoundParameters.ContainsKey('Name')){


        $singlesearch = Invoke-WebRequest "http://www.imdb.com/find?ref_=nv_sr_fn&q=$($name)&s=all"
        $SelectMovie = $singlesearch.links.href -match '/title/tt' | select -First 1
        $movieinfo = Invoke-WebRequest "$rootweb$($SelectMovie)"

        $rating = $movieinfo.RawContent -match 'Users rated this \d{1}.+?(?=10)10'
        $ratingmatched = $matches[0]
        $about = $movieinfo.RawContent -match 'Directed by.+?(?=/>)' | select -First 1
        $aboutmatched = $matches[0]

Write-Host "$aboutmatched" -ForegroundColor DarkCyan
Write-Host "$ratingmatched" -ForegroundColor Yellow


        }
}

function Get-IMDBItem
{
    <#
    .Synopsis
       Retrieves information about a movie/tv show etc. from IMDB.
    .DESCRIPTION
       This cmdlet fetches information about the movie/tv show matching the specified ID from IMDB.
       The ID is often seen at the end of the URL at IMDB.
    .EXAMPLE
        Get-IMDBItem -ID tt0848228
    .EXAMPLE
       Get-IMDBMatch -Title 'American Dad!' | Get-IMDBItem

       This will fetch information about the item(s) piped from the Get-IMDBMatch cmdlet.
    .PARAMETER ID
       Specify the ID of the tv show/movie you want get. The ID has the format of tt0123456
    #>

    [cmdletbinding()]
    param([Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
          [string[]] $ID)

    BEGIN { }

    PROCESS {
        foreach ($ImdbID in $ID) {

            $IMDBItem = Invoke-WebRequest -Uri "http://www.imdb.com/title/$ImdbID" -UseBasicParsing

            $ItemInfo = (($IMDBItem.Content -split "<div id=`"title-overview-widget`" class=`"heroic-overview`">")[1] -split "<div id=`"sidebar`">")[0]

            $ItemTitle = (($ItemInfo -split "<h1 itemprop=`"name`" class=`"`">")[1] -split "&nbsp;")[0]

            If (($ItemInfo -split "itemprop=`"datePublished`" content=`"").Length -gt 1) {
                $Type = "Movie"
                [DateTime]$Released = (($ItemInfo -split "<meta itemprop=`"datePublished`" content=`"")[1] -split "`" />")[0]
            } Else {
                $Type = "TV Series"
                $Released = $null
            }

            $Description = ((($ItemInfo -split "<div class=`"summary_text`" itemprop=`"description`">")[1] -split "</div>")[0]).Trim()

            $Rating = (($ItemInfo -split "<span itemprop=`"ratingValue`">")[1] -split "</span>")[0]

            $GenreSplit = $ItemInfo -split "itemprop=`"genre`">"
            $NumGenres = ($GenreSplit.Length)-1
            $Genres = foreach ($Genre in $GenreSplit[1..$NumGenres]) {
                ($Genre -split "</span>")[0]
            }

            $MPAARating = (($ItemInfo -split "<meta itemprop=`"contentRating`" content=`"")[1] -split "`">")[0]

            try {
                $RuntimeMinutes = New-TimeSpan -Minutes (($ItemInfo -split "<time itemprop=`"duration`" datetime=`"PT")[1] -split "M`">")[0]
            }
            catch {
                $RuntimeMinutes = $null
            }

            if ($Description -like '*Add a plot*') {
                $Description = $null
            }

            $returnObject = New-Object System.Object
            $returnObject | Add-Member -Type NoteProperty -Name ID -Value $ImdbID
            $returnObject | Add-Member -Type NoteProperty -Name Type -Value $Type
            $returnObject | Add-Member -Type NoteProperty -Name Title -Value $ItemTitle
            $returnObject | Add-Member -Type NoteProperty -Name Genre -Value $Genres
            $returnObject | Add-Member -Type NoteProperty -Name Description -Value $Description
            $returnObject | Add-Member -Type NoteProperty -Name Released -Value $Released
            $returnObject | Add-Member -Type NoteProperty -Name RuntimeMinutes -Value $RuntimeMinutes
            $returnObject | Add-Member -Type NoteProperty -Name Rating -Value $Rating
            $returnObject | Add-Member -Type NoteProperty -Name MPAARating -Value $MPAARating

            Write-Output $returnObject

            Remove-Variable IMDBItem, ItemInfo, ItemTitle, Genres, Description, Released, Type, Rating, RuntimeMinutes, MPAARating -ErrorAction SilentlyContinue
        }
    }

    END { }
}

function Resolve-ImdbId {
<#
    .Synopsis
        Converts an integer, string of numbers, or an object with the property "imdbID" to an IMDb (Internet Movie Database) formatted identifier in the form of "tt#######".
        If the input cannot be resolved, it is returned as is.

    .Parameter Id
        An integer, string of numbers, or an object with the property "imdbID".
        No characters are interpreted as wildcards.

    .NOTES
        Author: Benjamin Lemmond
        Email : benlemmond@codeglue.org

    .EXAMPLE
        Resolve-ImdbId 1234

        This example accepts an integer for the Id and returns a string value of "tt0001234".

    .EXAMPLE
        12, '345', '6879', 'BadId' | Resolve-ImdbId

        This example accepts four piped inputs, an integer and three strings, and returns the following string values:
        tt0000012
        tt0000345
        tt0006879
        BadId

    .EXAMPLE
        Get-ImdbTitle 'The Office' | imdbid

        This example uses Get-ImdbTitle to retrieve a PSCustomObject which has a property named 'imdbID'.
        This object is piped to imdbid (Resolve-ImdbId) and returns a string value of "tt0386676".
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [object[]]
        $Id
    )

    process {
        $Id | foreach {
            try {
                if ($_) {
                    if ($_ -is [int] -or $_ -match '^\s*\d+\s*$') {
                        return 'tt{0:0000000}'-f [int]$_
                    }

                    if ($_.psobject.Properties['imdbID']) {
                        return $_.imdbID
                    }
                }
                $_
            }
            catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
}


function Get-ImdbTitle {
<#
    .Synopsis
        Retrieves IMDb (Internet Movie Database) information using the OMDb (Open Movie Database) API by Brian Fritz.
        Changes to the OMDb API may break the functionality of this command.

    .Parameter Title
        If no wildcards are present, the first matching title is returned.
        If wildcards are present, the first 10 matching titles are returned.

    .Parameter Year
        The year of the title to retrieve (optional).

    .Parameter Id
        An integer, string of numbers, or an object with the property "imdbID" that represents the IMDb ID of the title to retrieve.
        No characters are interpreted as wildcards.

    .NOTES
        Author: Benjamin Lemmond
        Email : benlemmond@codeglue.org

    .EXAMPLE
        Get-ImdbTitle 'True Grit'

        This example returns a PSCustomObject respresenting the 2010 movie "True Grit".

    .EXAMPLE
        Get-ImdbTitle 'True Grit' 1969

        This example returns a PSCustomObject respresenting the 1969 movie "True Grit".

    .EXAMPLE
        'True Grit' | Get-ImdbTitle -Year 1969

        Similar to the previous example except the title is piped.

    .EXAMPLE
        65126 | imdb

        This example also returns a PSCustomObject respresenting the 1969 movie "True Grit".
#>

    [CmdletBinding(DefaultParameterSetName='Title')]
    param (
        [Parameter(ParameterSetName='Title', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Title,

        [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
        [int]
        $Year,

        [Parameter(ParameterSetName='Id', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [object[]]
        $Id,

        [Parameter(Mandatory=$true, Position=2)]
        [string]
        $Api
    )

    process {
        try {
            if ($PSBoundParameters.ContainsKey('Id')) {
                $queryStrings = $Id | Resolve-ImdbId | foreach { "i=$_" }
            }
            else {
                $yearParam = ''

                if ($Year) {
                    $yearParam = "&y=$Year"
                }

                $queryStrings = $Title | foreach {
                    $key = 't'
                    if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Title)) {
                        $key = 's'
                    }
                    "$key=$_$yearParam"
                }
            }

            $uriRoot ="http://www.omdbapi.com/?apikey=$Api&"
            
            $webClient = New-Object System.Net.WebClient

            $queryStrings | foreach {
                try {
                    Write-Verbose $uriRoot$_
                    $result = $webClient.DownloadString("$uriRoot$_") | ConvertFrom-Json

                    if ($result.psobject.Properties['Error']) {
                        throw [System.Management.Automation.ItemNotFoundException]$result.Error
                    }

                    if (-not $result.psobject.Properties['Search']) {
                        return $result
                    }

                    $result.Search | Resolve-ImdbId | foreach { $webClient.DownloadString("${uriRoot}i=$_") } | ConvertFrom-Json
                }
                catch {
                    Write-Error -ErrorRecord $_
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}

function Get-TmdbTitle {
    <#
        .Synopsis
            Retrieves IMDb (Internet Movie Database) information using the OMDb (Open Movie Database) API by Brian Fritz.
            Changes to the OMDb API may break the functionality of this command.
    
        .Parameter Title
            If no wildcards are present, the first matching title is returned.
            If wildcards are present, the first 10 matching titles are returned.
    
        .Parameter Year
            The year of the title to retrieve (optional).
    
        .Parameter Id
            An integer, string of numbers, or an object with the property "imdbID" that represents the IMDb ID of the title to retrieve.
            No characters are interpreted as wildcards.
    
        .NOTES
            Author: Benjamin Lemmond
            Email : benlemmond@codeglue.org
    
        .EXAMPLE
            Get-ImdbTitle 'True Grit'
    
            This example returns a PSCustomObject respresenting the 2010 movie "True Grit".
    
        .EXAMPLE
            Get-ImdbTitle 'True Grit' 1969
    
            This example returns a PSCustomObject respresenting the 1969 movie "True Grit".
    
        .EXAMPLE
            'True Grit' | Get-ImdbTitle -Year 1969
    
            Similar to the previous example except the title is piped.
    
        .EXAMPLE
            65126 | imdb
    
            This example also returns a PSCustomObject respresenting the 1969 movie "True Grit".
    #>
    
        [CmdletBinding(DefaultParameterSetName='Title')]
        param (
            [Parameter(ParameterSetName='Title', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [string[]]
            $Title,
    
            [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
            [int]
            $Year,
    
            [Parameter(ParameterSetName='Id', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [object[]]
            $Id,
    
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Api
        )
    
        process {
            try {
                if ($PSBoundParameters.ContainsKey('Id')) {
                    $queryStrings = $Id | Resolve-ImdbId | foreach { "i=$_" }
                }
                else {
                    $yearParam = ''
    
                    if ($Year) {
                        $yearParam = "&y=$Year"
                    }
    
                    $queryStrings = $Title | foreach {
                        $key = 't'
                        if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Title)) {
                            $key = 's'
                        }
                        "$key=$_$yearParam"
                    }
                }
    
                $uriRoot ="https://api.themoviedb.org/3/movie/550?api_key=$Api&"
                
                $webClient = New-Object System.Net.WebClient
    
                $queryStrings | foreach {
                    try {
                        Write-Verbose $uriRoot$_
                        $result = $webClient.DownloadString("$uriRoot$_") | ConvertFrom-Json
    
                        if ($result.psobject.Properties['Error']) {
                            throw [System.Management.Automation.ItemNotFoundException]$result.Error
                        }
    
                        if (-not $result.psobject.Properties['Search']) {
                            return $result
                        }
    
                        $result.Search | Resolve-ImdbId | foreach { $webClient.DownloadString("${uriRoot}i=$_") } | ConvertFrom-Json
                    }
                    catch {
                        Write-Error -ErrorRecord $_
                    }
                }
            }
            catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
    
function Open-ImdbTitle {
<#
    .Synopsis
        Opens the IMDb (Internet Movie Database) web site to the specified title using the default web browser.
        Some features of this command are achieved via the OMDb (Open Movie Database) API by Brian Fritz.
        Changes to the OMDb API may break the functionality of this command.

    .Parameter Title
        If no wildcards are present, the first matching title is opened.
        If wildcards are present, the first 10 matching titles are opened.

    .Parameter Year
        The year of the title to open (optional).

    .Parameter Id
        An integer, string of numbers, or an object with the property "imdbID" that represents the IMDb ID of the title to open.
        No characters are interpreted as wildcards.

    .NOTES
        Author: Benjamin Lemmond
        Email : benlemmond@codeglue.org

    .EXAMPLE
        Open-ImdbTitle 'True Grit'

        This example opens the IMDb page for the 2010 movie "True Grit".

    .EXAMPLE
        Open-ImdbTitle 'True Grit' 1969

        This example opens the IMDb page for the 1969 movie "True Grit".

    .EXAMPLE
        'True Grit' | Open-ImdbTitle -Year 1969

        Similar to the previous example except the title is piped.

    .EXAMPLE
        65126 | imdb.com

        This example also opens the IMDb page for the 1969 movie "True Grit".
#>

    [CmdletBinding(DefaultParameterSetName='Title')]
    param (
        [Parameter(ParameterSetName='Title', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Title,

        [Parameter(ParameterSetName='Title', Position=1, ValueFromPipelineByPropertyName=$true)]
        [int]
        $Year,

        [Parameter(ParameterSetName='Id', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [object[]]
        $Id
    )

    process {
        try {
            if ($PSBoundParameters.ContainsKey('Id')) {
                $imdbId = $Id | Resolve-ImdbId
            }
            else {
                $imdbResult = Get-ImdbTitle @PSBoundParameters
                if (-not $imdbResult) { return $imdbResult }
                $imdbId = $imdbResult | foreach { $_.imdbID }
            }

            $imdbId | foreach { Start-Process "http://imdb.com/title/$_" }
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}


<#
.Synopsis
   This scripts will get some basic information from IMDB about a movie by parcing the html code on the website.
.DESCRIPTION
   This scripts will get some basic information from IMDB about a movie by parcing the html code on the website.
.EXAMPLE
   Get-ImdbMovie -Title 'star trek'
.EXAMPLE
   Get-ImdbMovie -Title 'star trek' -verbose
.NOTES
   Created by John Roos
   http://blog.roostech.se
#>
function Get-ImdbMovie
{
    [CmdletBinding()]
    Param
    (
        # Enter the title of the movie you want to get information about
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullorEmpty()]
        [string]$Title,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateNotNullorEmpty()]
        [string]$Year,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string][ValidateSet("Action",
                    "Adventure",
                    "Animation",
                    "Biography",
                    "Comedy",
                    "Crime",
                    "Documentary",
                    "Drama",
                    "Family",
                    "Fantasy",
                    "History",
                    "Horror",
                    "Musical",
                    "Mystery",
                    "Romance",
                    "Sci_fi",
                    "Short",
                    "Sport",
                    "Thriller",
                    "War",
                    "Western")]$Genre
    )
 
    Process
    {
               
        #Replace any spaces or dash with %20
        #$searchTitle = $Title -Replace '(?:\s*-\s*)+|\s{1,}','%20'
        $EncodeTitle = [System.Web.HttpUtility]::UrlEncode($Title)
        $URLPrefix = "https://www.imdb.com/search/title?title=$EncodeTitle"

        if ($Year) {$URLPrefix += "&release_date=$Year"}
        if ($Genre) {$URLPrefix += "&genre=$Genre"}

        Write-Verbose "Fetching search results"
        #$moviesearch = Invoke-WebRequest "http://www.imdb.com/search/title?title=$searchTitle&title_type=feature"
        $moviesearch = Invoke-WebRequest $URLPrefix

        Write-Verbose "Moving html elements into variable"
        $titleclassarray = $moviesearch.AllElements | where id -like 'main' | select -First 1

        Write-Verbose "Checking if result contains movies"
        try {
            $titleclass = $titleclassarray[0]
        }
        catch {
            Write-Warning $URLPrefix
            break
        }
         
        if (!($titleclass)){
            Write-Warning $titleclass
            break
        }
         
        Write-Verbose "Result contains movies."
         
        Write-Verbose "Parcing HTML for movie link."
        $regex = "<\s*a\s*[^>]*?href\s*=\s*[`"']*([^`"'>]+)[^>]*?>"
        $linksFound = [Regex]::Matches($titleclass.innerHTML, $regex, "IgnoreCase")
         
        $titlelink = New-Object System.Collections.ArrayList
        foreach($link in $linksFound)
        {
            $trimmedlink = $link.Groups[1].Value.Trim()
            if ($trimmedlink.Contains('/title/')) {
                [void] $titlelink.Add($trimmedlink)
            }
        }
        Write-Verbose "Movie link found."
 
        $movieURL = "http://www.imdb.com$($titlelink[0])"
        Write-Verbose "Fetching movie page."
        $moviehtml = Invoke-WebRequest $movieURL -Headers @{"Accept-Language"="en-US,en;"}
        Write-Verbose "Movie page fetched."
 
        $movie = New-Object -TypeName psobject
 
        Write-Verbose "Parcing for title."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Title" -Value ($moviehtml.AllElements | where itemprop -eq 'name' | select -First 1).innerText.Trim() -Force
        
        Write-Verbose "Parcing for plot."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Plot" -Value ($moviehtml.AllElements | where class -eq 'summary_text' | select -First 1).innerText.Trim() -Force
 

        Write-Verbose "Parcing for writers."
        foreach ($line in ($moviehtml.AllElements | where Class -eq 'credit_summary_item').InnerText -split "`n"){
            if ($line -like 'Writers:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Writers" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Trim() -Force
            }
        }

        foreach ($line in ($moviehtml.AllElements | where Class -eq 'txt-block').InnerText -split "`n"){
            if ($line -like 'Language:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Language" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Trim() -Force
            }
            if ($line -like 'Country:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Country" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Replace(' See more »','').Trim() -Force
            }
            if ($line -like 'Released Date:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Released" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Replace(' See more »','').Trim() -Force
            }

            if ($line -like 'Runtime:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Runtime" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Trim() -Force
            }

            if ($line -like '*Production Co:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Production" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Replace(' See more »','').Trim() -Force
            }

            if ($line -like 'Taglines:*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Taglines" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Replace(' See more »','').Trim() -Force
            }

            if ($line -like 'Opening*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Premiered" -Value $line.Remove(0,$line.LastIndexOf(',')+1).Trim() -Force
            }

            if ($line -like '*WorldWide Gross*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "GrossInt" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Trim() -Force
            }

            if ($line -like 'Gross USA*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "GrossUSA" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Trim() -Force
            }

            if ($line -like '*Locations*'){
                Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Locations" -Value $line.Remove(0,$line.LastIndexOf(':')+1).Replace(' See more »','').Trim() -Force
            }
        }
        
        Write-Verbose "Parcing for director."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Director" -Value ($moviehtml.AllElements | where itemprop -eq 'director').InnerText.Trim() -Force

        Write-Verbose "Parcing for year."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Year" -Value (($moviehtml.AllElements | where id -eq 'titleYear' | select -First 1).innerText).Replace('(','').Replace(')','').Trim() -Force
 
        Write-Verbose "Parcing for rating."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Rating" -Value ($moviehtml.AllElements | where Class -eq 'rating' | select -First 1).innerText.Trim() -Force
 
        Write-Verbose "Parcing for description."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Description" -Value ($moviehtml.AllElements | where itemprop -eq 'description' | select -first 1).InnerText.Trim() -Force
 
        Write-Verbose "Parcing for stars."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Stars" -Value ($moviehtml.AllElements | where itemprop -eq 'actors').InnerText.Replace('Stars:','').Replace(' | See full cast and crew »','').Trim() -Force

        Write-Verbose "Adding the link."
        Add-Member -InputObject $movie -MemberType 'NoteProperty' -Name "Link" -Value $movieURL -Force
 
        Write-Verbose "Returning object."
        return $movie
    }
}