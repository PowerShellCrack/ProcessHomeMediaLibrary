# global for testing
# Example of data to give $options parameter of SetOptions method
# # $options = @"
# # {'language':'en_US',
# #     'sort_by':'popularity.desc'
# # }
# # "@
Function Find-TMDBItem{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("TV","Movie")]
        $Type,

        [Parameter(ParameterSetName='SimpleAction', Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("Discover","TopRated","Popular","Latest","Upcoming","Now")]
        $SimpleAction,

        [Parameter(ParameterSetName='SearchAction', Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("ByTVEpisode","ByTypewithFilter","ByType")]
        $SearchAction,

        [Parameter(ParameterSetName='TypeIDAction', Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("AlternativeTitles","Changes","Recommedend","Simliar","TVRatings","TVSeason","MovieGenre",
                                "Credits","Images","Keywords","ReleaseDates","Videos","Translations","Reviews","Lists" )]
        $TypeIDAction,

        [Parameter(ParameterSetName='PersonIDAction', Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("Person","TypeCredit","CombinedCredits")]
        $PersonIDAction,
        
        [Parameter(ParameterSetName='NetworkIDAction', Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("Nework")]
        $NetworkIDAction,

        
        #$Search,

        [parameter(Mandatory=$true, ParameterSetName="TypeIDAction")]
        [parameter(Mandatory=$true, ParameterSetName="PersonIDAction")]
        [parameter(Mandatory=$true, ParameterSetName="NetworkIDAction")]
        [string]
        $Id,

        [parameter(Mandatory=$true, ParameterSetName="SearchAction")]
        [string]
        $Title,

        [Parameter(Position=3, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string][ValidateSet("Action","Adventure","Animation","Comedy","Crime","Documentary","Drama","Family","Fantasy","History",
                                "Horror","Music","Mystery","Romance","Science Fiction","TV Movie","Thriller","War","Western")]
        $Genre,

        [Parameter(ParameterSetName='SearchAction', Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$SeasonNumber,

        [Parameter(ParameterSetName='SearchAction', Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$EpisodeNumber,

        [Parameter(ParameterSetName='JSONQuery', Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$JsonQuery,

        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Filter,

        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Year,

        [Parameter(Mandatory=$true, Position=6)]
        [string]
        $ApiKey,

        [Parameter(Mandatory=$false, Position=7)]
        [switch]$SelectFirst

    )
    Begin
    {
        If($ApiKey){
            $apiuri = "api_key=$ApiKey" 
        }Else{
            Write-Warning "APi key not found or invalid please try again"
            Break
        }

        $type = $Type.ToLower()

        If(!$Filter){$Filter = 'language=en-US&page=1'}

        If( ($type -eq 'tv') -and $SearchAction){
            If($SeasonNumber -and !$EpisodeNumber){Throw "Sorry, need both Season Number and Episode Number"}
        }

        switch($genres){
            "Action"          {$GenreId=28}
            "Adventure"       {$GenreId=12}
            "Animation"       {$GenreId=16}
            "Comedy"          {$GenreId=35}
            "Crime"           {$GenreId=80}
            "Documentary"     {$GenreId=99}
            "Drama"           {$GenreId=18}
            "Family"          {$GenreId=10751}
            "Fantasy"         {$GenreId=14}
            "History"         {$GenreId=36}
            "Horror"          {$GenreId=27}
            "Music"           {$GenreId=10402}
            "Mystery"         {$GenreId=9648}
            "Romance"         {$GenreId=10749}
            "Science Fiction" {$GenreId=878}
            "TV Movie"        {$GenreId=10770}
            "Thriller"        {$GenreId=53}
            "War"             {$GenreId=10752}
            "Western"         {$GenreId=37}
        }

        switch($SimpleAction){
            "Discover"          {$posturi = '/discover/'+ $type }

            "TopRated"          {$posturi = '/'+ $type + '/top_rated'}

            "Popular"           {$posturi = '/'+ $type + '/popular'}

            "Latest"            {$posturi = '/'+ $type + '/latest'}

            "Upcoming"          {$posturi = '/'+ $type + '/upcoming'}

            "Now"               {
                                If($type -eq 'tv'){$posturi = '/tv/airing_today'}
                                If($type -eq 'movie'){$posturi = '/movie/now_playing'}
                                }
        }
        
        switch($SearchAction){ 
            "ByTVEpisode"       {$posturi = '/tv/' + $Id + '/season/' + $SeasonNumber + '/episode/' + $EpisodeNumber + '?' + $apiuri}
            "ByTypewithFilter"  {$posturi = '/search/' + $type + '?' + $apiuri + '&query=' + $Title + '&' + $Filter}
            "ByType"            {$posturi = '/search/' + $type + '?' + $apiuri + '&query=' + $Title}
        }

        switch($TypeIDAction){        
            "AlternativeTitles" {$posturi = '/'+ $type + '/' + $Id + '/alternative_titles'}

            "Changes"           {$posturi = '/'+ $type + '/' + $Id + '/changes'}

            "Recommedend"       {$posturi = '/'+ $type + '/' + $Id + '/recommendations'}

            "Simliar"           {$posturi = '/'+ $type + '/' + $Id + '/similiar'}
   
            "TVRatings"         {$posturi = '/tv/' + $Id + '/content_ratings'}

            "TVSeason"          {$posturi = '/tv/' + $Id + '/season/'}
                        
            "MovieGenre"        {$posturi = '/genre/' + $GenreId + '/movies'}

            "Credits"           {$posturi = '/movie/' + $Id + '/credits'}       

            "Images"            {$posturi = '/movie/' + $Id + '/images'}

            "Keywords"          {$posturi = '/movie/' + $Id + '/keywords'}

            "ReleaseDates"      {$posturi = '/movie/' + $Id + '/release_dates'}

            "Videos"            {$posturi = '/movie/' + $Id + '/videos'}

            "Translations"      {$posturi = '/movie/' + $Id + '/translations'}

            "Reviews"           {$posturi = '/movie/' + $Id + '/reviews'}

            "Lists"             {$posturi = '/movie/' + $Id + '/lists'}       
        }               

        switch($PersonIDAction){
            "Person"            {$posturi = '/person/' + $Id}
            "TypeCredit"        {$posturi = '/person/' + $Id + '/'+ $type +'_credits'}
            "CombinedCredits"   {$posturi = '/person/' + $Id + '/combined_credits'}
        }
        
        switch($NetworkIDAction){
            "Nework"            {$posturi = '/network/' + $Id}
        }

        If($JsonQuery){
            try {
                $jsonObj = $JsonQuery | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                throw "Please enter a Here-String or json file as input for `$JsonQuery"
            }
        
            $JsonObjQuery = ''
            $Properties = $jsonObj |
            Get-Member |
            Where-Object {$_.MemberType -like "NoteProperty"} |
            Select-Object -ExpandProperty Name
            ForEach($property in $Properties){
                $JsonObjQueryy = $JsonObjQuery + "&" + $property + "=" + $jsonObj.$($property)
            }
            # Remove leadinng & , add in actual function instead
            $JsonObjQuery = $JsonObjQuery.TrimStart("&") 
        }

        If(!$Filter){$Filter = $Null}
    }
    Process
    {
        [String]$BaseUri = "http://api.themoviedb.org/3"

        If($SearchAction){
            Write-Verbose "Search Action triggered"
            $url = $BaseUri + $posturi
        }
        Else{
            $url = $BaseUri + $posturi + '?' + $apiuri

            If($JsonQuery){
                Write-Verbose "Json Query triggered"
                $url = $url + '&query=' + $JsonObjQuery   
            }

            If($Filter) {
                Write-Verbose "Filter Query triggered"
                $url = $url + '&query=' + $Filter       
            }
        }

        If($Year){
            $url = $url + '&year=' + $Year
        }
        
        Write-Verbose "Sending a Url of $url"
        $results = Invoke-RestMethod -Uri $url
        $entrys = @()
        foreach($res in $results.results) { 
            $entrys += $res
        }
    }
    End{
        If($entrys){
            Write-Verbose "Results returned: $($entrys.count)"
            
            $returnObjects = @()
            Foreach($entry in $entrys) {
                Write-Verbose "Found: $($entry.title)"
                If($entrys.genre_ids){
                    [array]$genres = $entrys.genre_ids
                
                    forEach ($genreID in $genres){
                        switch($genreID){
                            28      {$Genre="Action"}
                            12      {$Genre="Adventure"}
                            16      {$Genre="Animation"}
                            35      {$Genre= "Comedy"}
                            80      {$Genre="Crime"}
                            99      {$Genre="Documentary"}
                            18      {$Genre="Drama"}
                            10751   {$Genre="Family"}
                            14      {$Genre="Fantasy"}
                            36      {$Genre="History"}
                            27      {$Genre="Horror"}
                            10402   {$Genre="Music"}
                            9648    {$Genre="Mystery"}
                            10749   {$Genre="Romance"}
                            878     {$Genre="Science Fiction"}
                            10770   {$Genre="TV Movie"}
                            53      {$Genre="Thriller"}
                            10752   {$Genre="War"}
                            37      {$Genre="Western"}
                        }
                        [array]$Allgenres += $genre
                    }
                    [array]$joinGenres = $Allgenres -join ","
                }
            
                $returnObject = New-Object System.Object
                $returnObject | Add-Member -Type NoteProperty -Name TotalVotes -Value $entry.vote_count
                $returnObject | Add-Member -Type NoteProperty -Name tmdbID -Value $entry.id
                $returnObject | Add-Member -Type NoteProperty -Name Video -Value $entry.video
                $returnObject | Add-Member -Type NoteProperty -Name VoteAverage -Value $entry.vote_average
                $returnObject | Add-Member -Type NoteProperty -Name Title -Value $entry.title
                $returnObject | Add-Member -Type NoteProperty -Name Popularity -Value $entry.popularity
                $returnObject | Add-Member -Type NoteProperty -Name Poster -Value ('https://image.tmdb.org/t/p/original' + $entry.poster_path)
                $returnObject | Add-Member -Type NoteProperty -Name Language -Value $entry.original_language
                $returnObject | Add-Member -Type NoteProperty -Name OriginalTitle -Value $entry.original_title
                $returnObject | Add-Member -Type NoteProperty -Name Genres -Value $joinGenres 
                $returnObject | Add-Member -Type NoteProperty -Name Backdrop -Value ('https://image.tmdb.org/t/p/original' + $entry.backdrop_path)
                $returnObject | Add-Member -Type NoteProperty -Name Adult -Value $entry.adult
                $returnObject | Add-Member -Type NoteProperty -Name Overview -Value $entry.overview
                $returnObject | Add-Member -Type NoteProperty -Name ReleaseDate -Value $entry.release_date
                $returnObjects += $returnObject
            }
            
            If($SelectFirst){
                $firstobject = $returnObjects | Select -First 1
                return $firstobject
            }Else{
                return $returnObjects
            }
            #return $results
        }
    }   
}
#endregion Discover endpoint


Function Get-TmdbDefaultSearch{
        [CmdletBinding()]
        param (
            [Parameter(ParameterSetName='Action', Mandatory=$true)]
            [string][ValidateSet("InTheaters","Popular","TopRated",
                                "TopKids","Upcoming","BestByYear","GenreByYear",
                                "GenreByCast","CostByCastGenre","ByCast","PopularByCast",
                                "BestNyGenre","TopCastByRating")]
            $Action,
            
            [string][ValidateSet("Action","Adventure","Animation","Comedy","Crime","Documentary","Drama","Family","Fantasy","History",
                                "Horror","Music","Mystery","Romance","Science Fiction","TV Movie","Thriller","War","Western")]
            $Genre,
           
            [string][ValidateSet( "G","PG-13","R","NC-17","NR","PG","18A","14A","A")]
            $Certification,
            [string]$MonthRange,
            [string]$ReleaseYear,
            [string]$CastID,
            [string]$Country = 'US',
            [Parameter(Mandatory=$true)]
            [string]$ApiKey
        )
        [String]$BaseUri = "http://api.themoviedb.org/3"

        switch($genres){
            "Action"          {$GenreId=28}
            "Adventure"       {$GenreId=12}
            "Animation"       {$GenreId=16}
            "Comedy"          {$GenreId=35}
            "Crime"           {$GenreId=80}
            "Documentary"     {$GenreId=99}
            "Drama"           {$GenreId=18}
            "Family"          {$GenreId=10751}
            "Fantasy"         {$GenreId=14}
            "History"         {$GenreId=36}
            "Horror"          {$GenreId=27}
            "Music"           {$GenreId=10402}
            "Mystery"         {$GenreId=9648}
            "Romance"         {$GenreId=10749}
            "Science Fiction" {$GenreId=878}
            "TV Movie"        {$GenreId=10770}
            "Thriller"        {$GenreId=53}
            "War"             {$GenreId=10752}
            "Western"         {$GenreId=37}
        }
        
        


        $DateNow = (Get-date).ToString("yyyy-MM-dd")
        $dateMonthAgo = ( (Get-date).AddMonths(-$MonthRange) ).ToString("yyyy-MM-dd")
        switch($Action){
           
            "InTheaters"{
                            # What movies are in theatres?    
                            $Posturi = "/discover/movie?primary_release_date.gte=$dateMonthAgo&primary_release_date.lte=$DateNow"
                        }   
                
            "Popular"   {
                            # What are the most popular movies?
                            $Posturi = "/discover/movie?sort_by=popularity.desc"
                        }

            "TopRated"  {
                            # What are the highest rated movies rated R?
                            $Posturi = "/discover/movie/?certification_country=$Country&certification=$Certification&sort_by=vote_average.desc"
                        }
                
            "TopKids"   {
                            #What are the most popular kids movies?
                            $Posturi = "/discover/movie?certification_country=$Country&certification.lte=$Certification&sort_by=popularity.desc"
                        }
            "BestByYear"    {
                            #What is are the best movies from 2010?
                            $Posturi = "/discover/movie?primary_release_year=$ReleaseYear&sort_by=vote_average.desc"
                        }
            "GenreByYear"           {
                            #What are the best dramas that were released this year?
                            $Posturi = "/discover/movie?with_genres=$GenreId&primary_release_year=$ReleaseYear"
                        }

            "GenreByCast" {
                            #What are the highest rated science fiction movies that Tom Cruise has been in?
                            $Posturi = "/discover/movie?with_genres=$GenreId&with_cast=500&sort_by=vote_average.desc"
                        }

            "CostByCastGenre"           {
                            #What are the Will Ferrell's highest grossing comedies?
                            $Posturi = "/discover/movie?with_genres=$GenreId&with_cast=23659&sort_by=revenue.desc"
                        }

            "ByCast"   {
                            #Have Brad Pitt and Edward Norton ever been in a movie together?
                            $Posturi = "/discover/movie?with_people=287,819&sort_by=vote_average.desc"
                        }

            "PopularByCast"   {
                            #Has David Fincher ever worked with Rooney Mara?
                            $Posturi = "/discover/movie?with_people=108916,7467&sort_by=popularity.desc"
                        }

            "BestNyGenre"            {
                            #What are the best drama's?
                            $Posturi = "/discover/movie?with_genres=$GenreId&sort_by=vote_average.desc&vote_count.gte=10"
                        }

            "TopCastByRating"  {
                            #What are Liam Neeson's highest grossing rated 'R' movies?
                            $Posturi = "/discover/movie?certification_country=$Country&certification=$Certification&sort_by=revenue.desc&with_cast=3896"
                        }

        }

        $url = $BaseUri + $Posturi + "&api_key=$ApiKey"  
        $results = Invoke-RestMethod -Uri $url
        return $results.results

}


Function Get-TmdbCastInfo{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]    
        [string]$Cast,
        [string]$Language = 'en-US',
        [string]$Adult = 'true',
        [string]$Region = 'US',
        [Parameter(Mandatory=$true)]
        [string]$ApiKey
    )
    [String]$BaseUri = "http://api.themoviedb.org/3"
    
    $EncodeCast = [uri]::EscapeDataString($Cast)
    $PostURI = '/search/person?api_key=' + $ApiKey + '&language=' + $Language + '&query=' + $EncodeCast + '&page=1&include_adult=' + $Adult+ '&region=' + $Region
    $url = $BaseUri + $PostURI 
    
    Write-Verbose "Invoking-RestMethod: $url"
    $results = Invoke-RestMethod -Uri $url

    $returnObject = New-Object System.Object
    $returnObject | Add-Member -Type NoteProperty -Name Name -Value $results.results.Name
    $returnObject | Add-Member -Type NoteProperty -Name Id -Value $results.results.id
    $returnObject | Add-Member -Type NoteProperty -Name Image -Value ('https://image.tmdb.org/t/p/original' + $results.results.profile_path)
    $returnObject | Add-Member -Type NoteProperty -Name Popularity -Value $results.results.popularity

    return $returnObject
}
