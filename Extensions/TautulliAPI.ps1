<#
PlexyPY commands


.links
Tautulli
https://github.com/JonnyWong16/plexpy/blob/master/API.md

.Commands:
     get_apikey
     get_settings
     get_recently_added
     get_notification_log
     get_plays_by_stream_resolution
     get_plays_by_source_resolution
     get_plays_by_top_10_platforms
     get_plays_by_top_10_users
     get_plays_by_stream_type
     get_plays_per_month
     get_library_names
     get_geoip_lookup
     get_libraries_table
     get_plays_by_hourofday
     get_notifier_parameters
     get_activity
     get_pms_token
     get_whois_lookup
     get_synced_items
     get_server_list
     get_plex_log
     get_stream_type_by_top_10_platforms
     get_server_identity
     get_logs
     get_stream_type_by_top_10_users
     get_old_rating_keys
     get_new_rating_keys
     get_library_user_stats
     get_plays_by_dayofweek
     get_library_media_info
     get_date_formats
     get_libraries
     get_user_names
     get_home_stats
     get_server_id
     get_users
     get_user_watch_time_stats
     get_pms_update
     get_server_friendly_name
     get_user_logins
     get_history
     get_server_pref
     get_plays_by_date
     get_library_watch_time_stats
     get_notifiers
     get_servers_info
     get_library
     get_metadata
     get_user
     get_users_table
     get_user_ips
     get_user_player_stats



     set_mobile_device_config
     set_notifier_config







    
     delete_user
     undelete_user
     
     delete_all_library_history
     docs_md
     
     delete_temp_sessions
     
     register_device
     restart
     terminate_session
     download_config
    
     edit_library
     backup_db
     
     delete_media_info_cache
     install_geoip_db
     
     update_metadata_details
     
     update_check
     delete_lookup_info
     
     
     search
     
     delete_mobile_device
     download_database
     
     backup_config
     
     notify
     
     notify_recently_added
     import_database
     pms_image_proxy
     delete_all_user_history
     
     delete_notification_log
     
     refresh_libraries_list
     
     arnold
     delete_imgur_poster
     
     uninstall_geoip_db
     
     delete_login_log
     
     delete_image_cache
     delete_cache
     
     download_plex_log
     add_notifier_config
     
     docs
     delete_library
     update
     download_log
     
     sql
     undelete_library
     
     delete_notifier
     
     edit_user
     
     refresh_users_list

.example
http://ip:port + HTTP_ROOT + /api/v2?apikey=$apikey&cmd=$command

.sample
http://localhost:8181/api/v2?apikey=16545769bf6c4a10b8cbdd5498854ba6&cmd=get_activity
#>
#Import-Module 'D:\Processors\Shutdown\POSHJSON.psm1'

Function Get-ActiveTautulliUsers{
    param(
    [string] $URL = "http://localhost:8181",
    [string] $apiKey
    )
    
    $resource = "$URL/api/v2?apikey=$apiKey"
    $command = "get_activity"

    $dataResult = Invoke-RestMethod -Method Get -Uri ("$resource" + "&cmd=" + "$command")
    #$dataResult.response.data.stream_count
    If ($dataResult.response.data.stream_count -ge 1){
        #return $true
        If ($dataResult.response.data.stream_count -gt 1){
            Write-Log -Message "Multiple users found using Plex" -CustomComponent 'Plex Checker'
        }
        Else{
            Write-Log -Message "A user is found using Plex" -CustomComponent 'Plex Checker'
        }
        Return $True

    }
    Else{
        #return $false
        Write-Log -Message "No users are found using Plex" -CustomComponent 'Plex Checker'
        Return $False
    }
}

Function Get-TautulliAPIKey{
    param(
    [string] $URL = "http://localhost:8181",
    [string] $apiKey
    )
    
    $resource = "$URL/api/v2?"
    $command = "get_apikey"

    $dataResult = Invoke-RestMethod -Method Get -Uri ("$resource" + "&cmd=" + "$command")
    Return $dataResult.response.data
    
}

Function Get-TautulliInfo{
    param(

    [string][ValidateSet("get_apikey",
        "get_settings",
        "get_recently_added",
        "get_notification_log",
        "get_plays_by_stream_resolution",
        "get_plays_by_source_resolution",
        "get_plays_by_top_10_platforms",
        "get_plays_by_top_10_users",
        "get_plays_by_stream_type",
        "get_plays_per_month",
        "get_library_names",
        "get_geoip_lookup",
        "get_libraries_table",
        "get_plays_by_hourofday",
        "get_notifier_parameters",
        "get_activity",
        "get_pms_token",
        "get_whois_lookup",
        "get_synced_items",
        "get_server_list",
        "get_plex_log",
        "get_stream_type_by_top_10_platforms",
        "get_server_identity",
        "get_logs",
        "get_stream_type_by_top_10_users",
        "get_old_rating_keys",
        "get_new_rating_keys",
        "get_library_user_stats",
        "get_plays_by_dayofweek",
        "get_library_media_info",
        "get_date_formats",
        "get_libraries",
        "get_home_stats",
        "get_server_id",
        "get_pms_update",
        "get_server_friendly_name",
        "get_history",
        "get_server_pref",
        "get_plays_by_date",
        "get_library_watch_time_stats",
        "get_notifiers",
        "get_servers_info",
        "get_library",
        "get_metadata",
        "get_users",
        "get_users_table",
        "get_user",
        "get_user_names",
        "get_user_logins",
        "get_user_ips",
        "get_user_watch_time_stats",
        "get_user_player_stats")]
        $command,
    [string] $URL = "http://localhost:8181",
    [string] $apiKey
    )
    
    $resource = "$URL/api/v2?apikey=$apiKey"
    

    $dataResult = Invoke-RestMethod -Method Get -Uri ("$resource" + "&cmd=" + "$command")
    #$dataResult.response.data.stream_count
    $dataResult.response.data
    
}