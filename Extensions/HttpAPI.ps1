function Get-FileFromUri {  
    param(  
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]
        [Alias('Uri')]
        $Url,
        [parameter(Mandatory=$false, Position=1)]
        [string]
        [Alias('Folder')]
        $FolderPath
    )
    process {
        try {
            # resolve short URLs
            $req = [System.Net.HttpWebRequest]::Create($Url)
            $req.Method = "HEAD"
            $response = $req.GetResponse()
            $fUri = $response.ResponseUri
            $filename = [System.IO.Path]::GetFileName($fUri.LocalPath);
            $response.Close()
            # download file
            $DownloadTorrentPath = (Get-Item -Path ".\" -Verbose).FullName
            if ($FolderPath) { $DownloadTorrentPath = $FolderPath }
            if ($DownloadTorrentPath.EndsWith('\')) {
                $DownloadTorrentPath += $filename
            } else {
                $DownloadTorrentPath += '\' + $filename
            }
            $webclient = New-Object System.Net.webclient
            $webclient.UseDefaultCredentials = $true
            $UserAgent = "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0"
            $webclient.Headers.Add([System.Net.HttpRequestHeader]::UserAgent, $UserAgent);
            $webclient.downloadfile($fUri.AbsoluteUri, $DownloadTorrentPath)
            write-host -ForegroundColor DarkGreen "downloaded '$($fUri.AbsoluteUri)' to '$($DownloadTorrentPath)'"
        } catch {
            write-host -ForegroundColor DarkRed $_.Exception.Message
        }  
    }  
}

function Execute-HTTPPostCommand()
{
  param(
    [string] $url = $null,
    [string] $data = $null,
    [System.Net.NetworkCredential]$credentials = $null,
    [string] $contentType = "application/x-www-form-urlencoded",
    [string] $codePageName = "UTF-8",
    [string] $userAgent = $null
  );

  if ( $url -and $data )
  {
    [System.Net.WebRequest]$webRequest = [System.Net.WebRequest]::Create($url);
    $webRequest.ServicePoint.Expect100Continue = $false;
    if ( $credentials )
    {
      $webRequest.Credentials = $credentials;
      $webRequest.PreAuthenticate = $true;
    }
    $webRequest.ContentType = $contentType;
    $webRequest.Method = "POST";
    if ( $userAgent )
    {
      $webRequest.UserAgent = $userAgent;
    }

    $enc = [System.Text.Encoding]::GetEncoding($codePageName);
    [byte[]]$bytes = $enc.GetBytes($data);
    $webRequest.ContentLength = $bytes.Length;
    [System.IO.Stream]$reqStream = $webRequest.GetRequestStream();
    $reqStream.Write($bytes, 0, $bytes.Length);
    $reqStream.Flush();

    $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader]$sr = New-Object System.IO.StreamReader -argumentList $rs;
    $sr.ReadToEnd();
  }
}


function Get-HrefMatches{
    param(
    ## The filename to parse
    [Parameter(Mandatory = $true)]
    [string] $content,
    
    ## The Regular Expression pattern with which to filter
    ## the returned URLs
    [string] $Pattern = "<\s*a\s*[^>]*?href\s*=\s*[`"']*([^`"'>]+)[^>]*?>"
)

    $returnMatches = new-object System.Collections.ArrayList

    ## Match the regular expression against the content, and
    ## add all trimmed matches to our return list
    $resultingMatches = [Regex]::Matches($content, $Pattern, "IgnoreCase")
    foreach($match in $resultingMatches)
    {
        $cleanedMatch = $match.Groups[1].Value.Trim()
        [void] $returnMatches.Add($cleanedMatch)
    }

    $returnMatches
}

Function Get-Hyperlinks {
    param(
    [Parameter(Mandatory = $true)]
    [string] $content,
    [string] $Pattern = "<A[^>]*?HREF\s*=\s*""([^""]+)""[^>]*?>([\s\S]*?)<\/A>"
    )
    $resultingMatches = [Regex]::Matches($content, $Pattern, "IgnoreCase")
    
    $returnMatches = @()
    foreach($match in $resultingMatches){
        $LinkObjects = New-Object -TypeName PSObject
        $LinkObjects | Add-Member -Type NoteProperty `
            -Name Text -Value $match.Groups[2].Value.Trim()
        $LinkObjects | Add-Member -Type NoteProperty `
            -Name Href -Value $match.Groups[1].Value.Trim()
        
        $returnMatches += $LinkObjects
    }
}

function Create-Url {
    [CmdletBinding()]
    param (
        #using parameter sets even though only one since we'll likely beef up this method to take other input types in future
        [Parameter(ParameterSetName='UriFormAction', Mandatory = $true)]
        [System.Uri]$Uri
        ,
        [Parameter(ParameterSetName='UriFormAction', Mandatory = $true)]
        [Microsoft.PowerShell.Commands.FormObject]$Form
    )
    process {  
        $builder = New-Object System.UriBuilder
        $builder.Scheme = $url.Scheme
        $builder.Host = $url.Host
        $builder.Port = $url.Port
        $builder.Path = $form.Action
        write-output $builder.ToString()
    }
}