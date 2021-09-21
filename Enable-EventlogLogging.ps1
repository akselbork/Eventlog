clear-host
FUNCTION Enable-UDFEventLog {
<#    
.SYNOPSIS    
    Enable and set Size on Eventlog
.DESCRIPTION  
    Finding the eventlog by first look for the ListProvider, and then seeing if a logname basen on ListProvider and LogType exists
    If doing so, the log can be enabled and the MaximumSizeInBytes changed in MB, by using the ENABLE switch
    
    Not using the switch will show the current setting on the LogName without setting either "isEnabled" or "MaximumSizeInBytes"

.PARAMETER ListProvider  
    Eventlog ListProvider name.
    Accepts Wildcard, if multiple entries apears, a more precise value has to be used
.PARAMETER ComputerNames
    Which computers should the LogName be enabled on 
    Accepts list of computernames
.PARAMETER LogType
    Admin, Operational, or Debug
.PARAMETER Enable
    Change the current stat of the logName to "IsEnabled"
.PARAMETER SizingMB
    Change the MaximumSizeInBytes for the log. 
    But only in the "Enable" switch is used
.PARAMETER Show
    Show the log output
    
    LogName                                    IsEnabled MaximumSizeInBytes  LogMode
    -------                                    --------- ------------------  -------
    Microsoft-Windows-PrintService/Operational      True           20971520 Circular

.NOTES    
    Name: Enable-UDFEventlog
    Author: Aksel Bork
    DateCreated:   10-11-2020

    To Do:  

.LINK    

.EXAMPLE    
Enable-UDFEventLog  "Microsoft-windows-printservice" -Logtype "operational" -show

.EXAMPLE 
Enable-UDFEventLog  "Microsoft-windows-printservice" -Logtype "operational" -Enable -SizingMB 20
#>  

    [cmdletbinding()]
    param (        
        [SupportsWildcards()]
        [string]$listProvider, # = "Microsoft-Windows-AAD", #"Microsoft-windows-printservice/operational",

        [array]$computernames, # = "server01",

        [ValidateSet("admin","operational","debug")]
        [parameter(Mandatory=$true)]
        [string]$Logtype,

        [switch]$Enable,

        [int]$SizingMB, # = 10,

        [switch]$show
    )
    BEGIN {
        IF ($PSBoundParameters.ContainsKey('computernames') -eq $false) {
            $computernames = $env:COMPUTERNAME
        }
        
      #  $local_Logtype = $null
    } # END BEGIN
    PROCESS {
        $computernames | ForEach-Object {
            $computername = $null
            $computername = $_

            ## TESTING IF EVENTLOG CONTAINS ANY LISTPROVIDER NAMED LISTLOG
            TRY {
                $test_listProvider = get-WinEvent -ListProvider $listProvider -ComputerName $computername -ErrorAction SilentlyContinue
            } CATCH {
            }
            ### THERE CAN ONLY BE ON 
            IF (  $test_listProvider.count -eq 1) {
                $p_logname = $($test_listProvider.Name) + "/" + $($Logtype)
                TRY {     
                    $query_LogName = Get-WinEvent -ListProvider $listProvider -ComputerName $env:computername -ErrorAction Stop  | 
                                    Select-Object -ExpandProperty loglinks | 
                                    where-object logname -eq $p_logname
                } CATCH {
                }
            } ELSEIF (  $test_listProvider.count -ge 1) {
                Write-Warning "LISTPROVIDER HAS TO BE MORE PRECISE - [$($test_listProvider.count)] MATCHES FOUND."
                If ($show.IsPresent) {
                    $test_listProvider | foreach-object { Write-host $_.name }
                }
            } ELSE {
                Write-warning "NO LISTPROVIDER NAMED: $listlog - EXISTS"
            } # END IF/IFELSE/ELSE
            IF (($query_LogName.count -eq 1) ) {
                $null = Get-WinEvent -ComputerName $computername -listlog $p_logname -OutVariable targetlog

                IF ($enable.IsPresent) {                
                    TRY {
                        ## ENABLE LOGGING    
                        $targetlog.set_IsEnabled($true)
                        
                        ## CHANGE LOGSIZE IF CHOOSEN
                        IF ($PSBoundParameters.ContainsKey('sizingMb')) {
                            $targetlog.set_maximumSizeInBytes($SizingMB * 1MB)
                        }
                        $targetlog.SaveChanges()
                    } CATCH {
                    }
                }
            } ELSE {
                Write-Warning "NO LOGNAME CAN BE FOUND."
            }
        }
    }
    END {
        If ($show.IsPresent) {
            $targetlog | Select-Object LogName, IsEnabled, MaximumSizeInBytes, LogMode
        }
    }
}


