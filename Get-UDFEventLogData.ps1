
FUNCTION Get-UDFEventLogData {
    <#
    .SYNOPSIS
       Getting eventlogs sorted after time created for Throubleshootning
    .DESCRIPTION
        Most troubleshooting by using Eventlog can be a long time comsuming task, as you have to look in many different folders, search trough date etc.
        The function make this easier by taking eventlog sorted by either time (default 1 hour back), by logname, by LogId, or combined.
        The output can be in either text og CSV format
       
    .PARAMETER LogName
        The logname in eventlog etc. "Microsoft-Windows-PrintService/Operational" or "Application"
    .PARAMETER LogID
        The Specific LogID number in Eventlog. Can be combined with "LogName"
    .PARAMETER listNumbers
        Numbers of eventlogs in output. Can be used for testing purpose
    .PARAMETER logFilePath
        Folder path to the where the output file is located
    .PARAMETER lockup
        Adding name to output file
        Default = "EventLogs"
    .PARAMETER computerName
        Computername for where to query the eventlog. Added to output filname
        Default = $Env:computername
    .PARAMETER fileExt
        Choose between CSV or TXT file
        Default = CSV
    .PARAMETER delimiter
        Choose between ; or |
        Default = ;
    .PARAMETER customDate
        SWITCH parameter used to set a custom range on when to the eventlog was made.
        If no other paramaters is set, the default range i 1 hour back from "now"
    .PARAMETER startYear
        Start year for query
        Default current year
    .PARAMETER startMonth
        Start month for query
        Default current month
    .PARAMETER startDay
        Start day for query
        Default yesterday
    .PARAMETER startHour
        Start hour for query
        Default current hour
    .PARAMETER startMinute
        Start minute for query
        Default current minute
    .PARAMETER endYear
        End year for query
        Default current year
    .PARAMETER endMonth
        End month for query
        Default current year
    .PARAMETER endDay
        End Day for query
        Default today
    .PARAMETER endHour
        End hour for query
        Default current hour
    .PARAMETER endMinute
        End Minute for query
        Default current minute
    .PARAMETER Show
        SWITCH parameter adding output to screen
    .INPUTS
        
    .OUTPUTS
    
    .EXAMPLE
        Get-UDFEventLogData -lockup "SERVICE_Restart"
    .EXAMPLE
        Get-UDFEventLogData  -listNumbers 10 -fileExt csv -Show -lockup "test" -customDate
    .EXAMPLE
        Get-UDFEventLogData -startYear 2020 -endYear 2020 -startMonth 11 -startDay 23 -startHour 13 -startMinute 15 -endMonth 11 -endDay 23 -endHour 15 -endMinute 15 -logFilePath "C:\itr\AKMBO" -lockup "SERVICE_Restart"
    .EXAMPLE
        
    .LINK
    
    .NOTES
        Author:     AKSEL BORK (AKMBO@ITRELATION.DK)
        GetWinEvent-All-Logs-TimeDiff_v2.ps1
        vers. 2020-11-24
    
    
    #>
        [cmdletbinding(DefaultParameterSetName = 'DEFAULT')]
        param (
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [string[]]$LogName, 			# = "application", #"Microsoft-Windows-PrintService/Operational",
            
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [int[]]$LogID, 				    # = $(1013,11706,10010),
    
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [int]$listNumbers,
    
            # LOGFILE FORMAT
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [parameter(mandatory=$false)]
            [ValidateScript({ test-path $_ -pathtype 'Container' })]
            $logFilePath, 			 #    = "Z:\POWERSHELL\LOG"
    
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            $lockup,                    # = "Breakdown",
    
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [parameter(mandatory=$false)]
            [validateScript({IF (Test-connection $_ -Count 1 ) {
                                    $true
                                } ELSE {
                                    trow "Cannot connect to - $_ ..."
                                }
            })]
            $computerName = $env:COMPUTERNAME,
    
            [parameter(mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("csv","txt")]
            $fileExt = "csv",
    
            [parameter(mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet(";","|")]
            $delimiter = ";",
    
            [parameter(mandatory=$false,
                ParameterSetName="DateDiff")]
            [switch]$customDate,
    
            [parameter(mandatory=$false,
                Position=0,
                ParameterSetName="DateDiff")]
            [int]$startYear,                # = 2020,
            [parameter(mandatory=$false,
                Position=1,
                ParameterSetName="DateDiff")]
            [int]$startMonth,               # = 3,
            [parameter(mandatory=$false,
                Position=2,
                ParameterSetName="DateDiff")]
            [int]$startDay,                 # = 26,
            [parameter(mandatory=$false,
                Position=3,
                ParameterSetName="DateDiff")]
            [int]$startHour,                # = 10,
            [parameter(mandatory=$false,
                Position=4,
                ParameterSetName="DateDiff")]
            [int]$startMinute,              # = 05,
            [parameter(mandatory=$false,
                Position=5,
                ParameterSetName="DateDiff")]
            [int]$endYear,                  # = 2020,
            [parameter(mandatory=$false,
                Position=6,
                ParameterSetName="DateDiff")]
            [int]$endMonth,                 # = 3,
            [parameter(mandatory=$false,
                Position=7,
                ParameterSetName="DateDiff")]
            [int]$endDay,                   # = 26,
            [parameter(mandatory=$false,
                Position=8,
                ParameterSetName="DateDiff")]
            [int]$endHour,                  # = 12,
            [parameter(mandatory=$false,
                Position=9,
                ParameterSetName="DateDiff")]
            [int]$endMinute,                # = 20,
    
            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [SWITCH]$Show,

            [parameter(mandatory=$false,ParameterSetName="DEFAULT")]
            [parameter(mandatory=$false,ParameterSetName="DateDiff")]
            [SWITCH]$noOutput
        )
    
        BEGIN {
    
            $Date = (get-date -Format yyyy-MM-dd)
            $DateTime = (get-date -Format HH-mm)
            $dateNow = Get-Date
            $QueryableDate = $true
    
            ## CREATE LOG FIL
            IF (-not($PSBoundParameters.ContainsKey('LogFilePath'))) {
                $logFilePath = [environment]::getfolderpath("mydocuments")  #"C:\Users\akmbo\Documents\DATA\TROUBLESHOOTING" #"C:\DATA\TROUBLESHOOTING"
            }
    
            IF (-not($PSBoundParameters.ContainsKey('Lockup'))) {
                    $lockup = "EventLogs"
            }
    
            [string]$exportPath = $logFilePath+"`\"+$Date.ToString()+"`_"+$DateTime.ToString()+"`_"+$computerName.ToUpper()+"-"+$lockup+"`."+$fileExt
            
    
            If ($Show.IsPresent) {
                write-host $exportPath -ForegroundColor Yellow
            }
            
    
            ## SET DATE VALUES IF NON ENTERED (DEFAULT -1 HOUR)
            IF (-not ($PSBoundParameters.ContainsKey('StartYear'))) {
                $startYear = $dateNow.Year
            }
    
            IF (-not ($PSBoundParameters.ContainsKey('Startmonth'))) {
                $startMonth = $dateNow.Month
            }   
    
            IF (-not ($PSBoundParameters.ContainsKey('Startday'))) {
                $startDay = $dateNow.Day
            }
            
            IF (-not ($PSBoundParameters.ContainsKey('Starthour'))) {
                $startHour = $dateNow.AddHours(-1).Hour
            }
            
            IF (-not ($PSBoundParameters.ContainsKey('StartMinute'))) {
                $startMinute = $dateNow.Minute
            }
    
            IF (-not ($PSBoundParameters.ContainsKey('EndYear'))) {
                $endYear = $dateNow.Year
            }
    
            IF (-not ($PSBoundParameters.ContainsKey('Endmonth'))) {
                $endMonth = $dateNow.Month
            }
    
            IF (-not ($PSBoundParameters.ContainsKey('endday'))) {
                $endDay = $dateNow.Day
            }
            
            
            IF (-not ($PSBoundParameters.ContainsKey('Endhour'))) {
                $endHour = $dateNow.Hour
            }
    
            IF (-not ($PSBoundParameters.ContainsKey('EndMinute'))) {
                $endMinute = $dateNow.Minute
            }
    
            # DATE DIFF ON EVENTLOGS COLLECTED
            IF ($PSCmdlet.ParameterSetName -eq "DateDiff") {
                $StartTime = Get-Date -Year $startYear -Month $startMonth -Day $startDay -Hour $startHour -Minute $startMinute
                $EndTime   = Get-Date -Year $endYear -Month $endMonth -Day $endDay -Hour $endHour -Minute $endMinute
            
                IF ($Show.IsPresent) {
                    Write-host "STARTTIME: $StartTime" -ForegroundColor Green
                    Write-Host "ENDTIME:   $EndTime" -ForegroundColor Yellow
                }
                IF ($EndTime -gt $StartTime) {
                    $QueryableDate = $true
                } ELSE {
                    $QueryableDate = $false
                }
            }
    
        } #BEGIN
    
        PROCESS {
            IF ($QueryableDate) {
                $Events = @()
    
                IF ([string]::IsNullOrEmpty($LogName)) {
                    $LogName = "*"  
                }
                IF ($PSCmdlet.ParameterSetName -eq 'DateDiff') {
                    IF ($PSBoundParameters.ContainsKey('LogName')) {
                        write-host $LogName -ForegroundColor Yellow
                        foreach ($LogNameObj in $LogName) {
                            # TEST IF THERE IS RECORDS IN THE LIST, ELSE ABOUT SEARCH
                            Get-WinEvent -ListLog $LogNameObj -ComputerName $computerName  -EA silentlycontinue |  
                                Foreach-Object { 
                                    IF ([string]::IsNullOrEmpty( $LogID )) {
                                        TRY {
                                            $events += Get-WinEvent -FilterHashtable @{LogName=$LogNameObj;StartTime=$StartTime;EndTime=$EndTime} -ComputerName $computerName -ErrorAction SilentlyContinue
                                        } CATCH {
                                        }
                                    } ELSE {
                                        TRY {
                                            $events += Get-WinEvent -FilterHashtable @{LogName=$LogNameObj;Id = $LogID;StartTime=$StartTime;EndTime=$EndTime} -ComputerName $computerName -ErrorAction SilentlyContinue    
                                        } CATCH {
                                        }
                                    }# IF/ELSE NULL $LogID
                                } # FOREACH
                        
                        } # END FOREACH LOGNAME     
    
                    } ELSE {
                        Get-WinEvent -ListLog * -ComputerName $computerName  -EA silentlycontinue | 
                            where-object { $_.recordcount } |
                                Foreach-Object { 
                                    TRY {
                                        $events +=  Get-WinEvent -FilterHashtable @{LogName=$_.logname;StartTime=$StartTime;EndTime=$EndTime} -ComputerName $computerName -ErrorAction SilentlyContinue
                                    } CATCH {
                                    }
                                }
                    } # END IF CONTAINS LOGNAME
                } ELSE {
                    IF ($PSBoundParameters.ContainsKey('LogName')) {
                    #    $LogName
                        foreach ($LogNameObj in $LogName) {
                            Get-WinEvent -ListLog $LogNameObj -ComputerName $computerName  -EA silentlycontinue | 
                            Foreach-Object { 
                            IF ($PSBoundParameters.ContainsKey('LogID')){
                                    TRY {
                                        IF ($PSBoundParameters.ContainsKey('ListNumbers')) {
                                            $events += Get-WinEvent -FilterHashtable @{LogName=$LogNameObj;id = $LogID} -ComputerName $computerName -ErrorAction SilentlyContinue | Select-Object -First $listNumbers
                                        } ELSE {
                                            $events += Get-WinEvent -FilterHashtable @{LogName=$LogNameObj;id = $LogID} -ComputerName $computerName -ErrorAction SilentlyContinue
                                        }
                                    } CATCH {
                                    }
                                    
                                } ELSE {
                                    TRY {
                                        IF ($PSBoundParameters.ContainsKey('Listnumbers')) {
                                            $events += Get-WinEvent -LogName $LogNameObj -ComputerName $computerName -ErrorAction SilentlyContinue -MaxEvents $listNumbers # | Select-Object -First $ListNumbers
                                        } ELSE {
                                            $events += Get-WinEvent -LogName $LogNameObj -ComputerName $computerName -ErrorAction SilentlyContinue 
                                        }
                                    } CATCH {
                                    }
                                }
                            } # END FOREACH
                        } # END FOREACH
                    } ELSE {
                        Get-WinEvent -ListLog * -ComputerName $computerName  -EA silentlycontinue | 
                            where-object { $_.recordcount } |
                            Foreach-Object { 
                                TRY {
                                    $events +=  Get-WinEvent -FilterHashtable @{LogName=$_.logname} -ComputerName $computerName -ErrorAction SilentlyContinue
                                } CATCH {
                                }
                            }
                    } # END IF CONTAINS LOGNAME
                } # END IF DATEDIFF
            } # END IF($QueryableDate)
        } #PROCESS
    
        END {
            $OrderedEvents = $Events | Select-Object TimeCreated, LogName, ProviderName,ProviderID,UserID, Id, LevelDisplayName, Message | Sort-Object timeCreated
            IF ($fileExt -eq "csv") {
                $OrderedEvents | Export-Csv -Path $exportPath -Delimiter $delimiter -NoTypeInformation
            } ELSEIF ($fileExt -eq "txt")  {
                $OrderedEvents | Out-File -Path $exportPath -Encoding unicode -Append
            } ELSE {
                Write-Warning "No output file extension. No output file is created"
            }
            
            IF (-NOT ($noOutput.IsPresent)) {
                $OrderedEvents
            } ELSE {
                Write-host "[EVENTLOGS] Count [$($OrderedEvents.count)]"
            }
        }
    }
    
    
    
    ##Get-UDFEventLogData -LogName "Microsoft-Windows-PrintService/Operational" -LogID 307 -computerName fd02prt04 -listNumbers 1 -Show