--
--  AppDelegate.applescript
--  Exporter
--
--  Created by Iain Wood on 21/11/2014.
--  Copyright (c) 2014 soulflyer. All rights reserved.
--

--
--  IWAppDelegate.applescript
--  moreTables
--
--  Created by Iain Wood on 01/07/2014.
--  Copyright (c) 2014 soulflyer. All rights reserved.
--

script IWAppDelegate
	property parent : class "NSObject"
	property theData : {}
	property topFolders : {"2014"}
	property allProjects : {}
	property separator : "/"
	property exportPath : "/Users/iain/Pictures/Published"
	property logFile : exportPath & "lastModifiedExports"
	property lastRunDate : "12/10/1958"
	property p_sql : "/usr/bin/sqlite3 "
	property libDBPOSIX : ""
	property tempDatabase : "/tmp/Library.apdb"
	property exportStatusMessage : ""
	property currentProject : ""
	property progressCounter : 0
	property progressSteps : 6
	property stepsPerProject : 6
	
	-- IBOutlets
	property theWindow : missing value
	property theArrayController : missing value
	property theTable : missing value
	
	-----------------------------------------------------------------------------------------------------------------------
	on applicationWillFinishLaunching:aNotification
		tell application "Finder"
			try
				set my lastRunDate to modification date of file (logFile as POSIX file) as string
			end try
		end tell
		log ("Last run date: " & my lastRunDate)
		my getProjects:(null)
		set g_libPath to my getLibPath()
		set libPOSIX to POSIX path of g_libPath
		set my libDBPOSIX to quoted form of (libPOSIX & "/Database/Library.apdb") as string
		set thescript to "cp " & my libDBPOSIX & " /tmp"
		log thescript
		do shell script thescript
		log "copied database"
		set my progressCounter to 0
	end applicationWillFinishLaunching:
	
	-----------------------------------------------------------------------------------------------------------------------
	on getProjects_(sender)
		tell application "Aperture"
			repeat with topFolder in my topFolders
				(my logg:topFolder)
				(my getProjectsInFolder:(folder topFolder))
			end repeat
			
			set theNames to {}
			set fullProjectPaths to {}
			set firstExportDates to {}
			set lastExportDates to {}
			set exportStatuses to {}
			repeat with theProject in my allProjects
				set end of theNames to (my projectPath:theProject)
				set end of fullProjectPaths to (my fullProjectPath:theProject)
				set end of firstExportDates to (my firstExportDate:theProject)
				set end of lastExportDates to (my lastExportDate:theProject)
				set end of exportStatuses to (my exportStatus:theProject)
			end repeat
		end tell
		set tempList to {}
		repeat with i from 1 to count of theNames
			set end of tempList to {theName:item i of theNames, theString:item i of fullProjectPaths, firstExportDate:item i of firstExportDates, lastExportDate:item i of lastExportDates, exportStatus:item i of exportStatuses}
			--, theProject:item i of allProjects}
		end repeat
		theArrayController's addObjects:tempList
		--log "Finished getProjects"
	end getProjects:
	
	-----------------------------------------------------------------------------------------------------------------------
	on testButton_(sender)
		set theSel to theArrayController's selectedObjects() as list
		set my progressSteps to (length of theSel) * (my stepsPerProject)
		--set my progressCounter to 0
		log "Progress steps " & my progressSteps
		repeat with selection in theSel
			(my logg:(theName of selection))
			set my currentProject to (theName of selection)
			(my exportPics:(theName of selection))
		end repeat
		set my progressCounter to 0
		set my exportStatusMessage to "Finished export"
	end testButton:
	
	-----------------------------------------------------------------------------------------------------------------------
	on setExportedDate(selectedPics)
		-- Make sure the modified time comes before the exported date
		set edate to (current date) + 1 * minutes
		set curyear to year of edate as string
		set curmonth to month of edate as string
		my logg:curmonth
		set curmonth to my monthToIntegerString:curmonth
		set curday to day of edate as string
		if length of curday is 1 then
			set curday to "0" & curday
		end if
		set curhour to hours of edate as string
		if length of curhour is 1 then
			set curhour to "0" & curhour
		end if
		set curmins to minutes of edate as string
		if length of curmins is 1 then
			set curmins to "0" & curmins
		end if
		set cursecs to seconds of edate as string
		if length of cursecs is 1 then
			set cursecs to "0" & cursecs
		end if
		set exportedDate to curyear & curmonth & curday & "T" & curhour & curmins & cursecs & "+07"
		log "Export date: " & exportedDate
		tell application "Aperture"
			repeat with pic in selectedPics
				tell pic
					(my logg:("setting export date of " & name))
					make new IPTC tag with properties {name:"ReferenceDate", value:exportedDate}
				end tell
			end repeat
		end tell
	end setExportedDate
	
	-----------------------------------------------------------------------------------------------------------------------
	on setUrgency(pr)
		tell application "Aperture"
			tell project pr
				-- Digikam uses Urgency to store the ratings, so convert Aperture rating to urgency
				tell (every image version where main rating is 5)
					make new IPTC tag with properties {name:"Urgency", value:"1"}
				end tell
				tell (every image version where main rating is 4)
					make new IPTC tag with properties {name:"Urgency", value:"2"}
				end tell
				tell (every image version where main rating is 3)
					make new IPTC tag with properties {name:"Urgency", value:"4"}
				end tell
				tell (every image version where main rating is 2)
					make new IPTC tag with properties {name:"Urgency", value:"5"}
				end tell
				tell (every image version where main rating is 1)
					make new IPTC tag with properties {name:"Urgency", value:"6"}
				end tell
			end tell
		end tell
	end setUrgency
	
	-----------------------------------------------------------------------------------------------------------------------
	on exportPics:theProjectPath
		set fullsizePath to my exportPath & "/fullsize/" & theProjectPath
		set largePath to my exportPath & "/large/" & theProjectPath
		set mastersPath to my exportPath & "/masters/" & theProjectPath
		set thumbsPath to my exportPath & "/thumbs/" & theProjectPath
		set mediumPath to my exportPath & "/medium/" & theProjectPath
		set rootPath to my exportPath & "/" & theProjectPath
		
		set components to (current application's NSString's stringWithString:theProjectPath)
		set componentsArray to (current application's NSMutableArray)
		set componentsArray to (components's componentsSeparatedByString:"/")
		if componentsArray's |count|() is 3 then
			set asComponents to componentsArray as list
			set theYear to item 1 of asComponents
			set theMonth to item 2 of asComponents
			set theMonth to my integerToMonthString:theMonth
			set theProject to item 3 of asComponents
			my removeAndReplaceDir(thumbsPath)
			my removeAndReplaceDir(mediumPath)
			my removeAndReplaceDir(largePath)
			my removeAndReplaceDir(rootPath)
			my removeAndReplaceDir(fullsizePath)
			my removeAndReplaceDir(mastersPath)
			tell application "Aperture"
				tell folder theYear
					tell folder theMonth
						tell project theProject
							set thescript to p_sql & my tempDatabase & " \"select note from RKNOTE where ATTACHEDTOUUID='" & id & "'\""
							set notes to do shell script thescript
							set cursel to (every image version where (main rating is greater than 2) or (color label is red)) as list
							my setUrgency(theProject)
						end tell
					end tell
				end tell
			end tell
			my doExport(cursel, thumbsPath, mediumPath, largePath, fullsizePath)
			my addLinks(cursel, mastersPath)
			set my exportStatusMessage to "Building web page for " & my currentProject
			set thescript to "echo \"" & notes & "\"> " & rootPath & "/notes.txt"
			do shell script thescript
			set thescript to "/Users/iain/bin/build-shoot-page " & rootPath
			log thescript
			do shell script thescript
			set my progressCounter to (my progressCounter) + 1
		else
			(alert("Problem with path to project. Is it in yyyy/mm/dd-projname form?"))
		end if
	end exportPics:
	
	-----------------------------------------------------------------------------------------------------------------------
	on removeAndReplaceDir(dirName)
		--my logg:("Removing previous versions in " & dirName)
		if my fileExists(POSIX path of dirName) then
			set thescript to "rm -r " & dirName
			do shell script thescript
		end if
		set thescript to "mkdir -p " & dirName
		do shell script thescript
	end removeAndReplaceDir
	
	-----------------------------------------------------------------------------------------------------------------------
	on doExport(theSel, theThumbsPath, theMediumPath, theLargePath, theFullsizePath)
		--make a temporary directory for the export to avoid apples ludicrous file renaming when file already exists
		set curyear to year of (current date) as string
		set curmonth to month of (current date) as string
		set curday to day of (current date) as string
		set curtime to time of (current date) as string
		set tempPath to "/tmp/" & curyear & curmonth & curday & curtime
		set thescript to "mkdir " & tempPath
		do shell script thescript
		
		tell application "Aperture"
			set my exportStatusMessage to "Exporting thumbnails from " & my currentProject
			theWindow's displayIfNeeded()
			export theSel naming files with file naming policy "Version Name" using export setting "JPEG - Thumbnail" to tempPath
			set thescript to "mv " & tempPath & "/* " & theThumbsPath & "/"
			--my logg:thescript
			do shell script thescript
			set my progressCounter to (my progressCounter) + 1
			my logg:"Finished exporting thumbnails"
			
			set my exportStatusMessage to "Exporting medium pics from " & my currentProject
			theWindow's displayIfNeeded()
			export theSel naming files with file naming policy "Version Name" using export setting "JPEG - Fit within 1024 x 1024" to tempPath
			set thescript to "/Users/iain/bin/add-watermark " & tempPath & "/*.jpg "
			do shell script thescript
			set thescript to "mv " & tempPath & "/* " & theMediumPath
			do shell script thescript
			set my progressCounter to (my progressCounter) + 1
			my logg:"Finished exporting mediums"
			
			set my exportStatusMessage to "Exporting large pics from " & my currentProject
			theWindow's displayIfNeeded()
			export theSel naming files with file naming policy "Version Name" using export setting "JPEG - Fit within 2048 x 2048" to tempPath
			set thescript to "/Users/iain/bin/add-watermark " & tempPath & "/*.jpg "
			do shell script thescript
			set thescript to "mv " & tempPath & "/* " & theLargePath
			do shell script thescript
			set my progressCounter to (my progressCounter) + 1
			my logg:"Finished exporting larges"
			theWindow's displayIfNeeded()
			
			set my exportStatusMessage to "Exporting fullsize pics from " & my currentProject
			theWindow's displayIfNeeded()
			export theSel naming files with file naming policy "Version Name" using export setting "JPEG - Original Size" to tempPath
			set thescript to "mv " & tempPath & "/* " & theFullsizePath
			do shell script thescript
			my logg:"Finished exporting fullsize"
			set my progressCounter to (my progressCounter) + 1
			theWindow's displayIfNeeded()
		end tell
		
		my setExportedDate(theSel)
		
		set thescript to "rm -r " & tempPath
		do shell script thescript
	end doExport
	
	-----------------------------------------------------------------------------------------------------------------------
	on addLinks(theSel, linksPath)
		tell application "Aperture"
			set databasePath to quoted form of my tempDatabase
			repeat with curimg in theSel
				set masterName to value of other tag "FileName" of curimg
				set curname to name of curimg
				set isRef to referenced of curimg
				set curID to id of curimg
				
				--(my logg:("Mastername: " & masterName & " Name: " & curname))
				
				if isRef is true then
					set thescript to p_sql & databasePath & " \"select MASTERUUID from RKVERSION where UUID='" & curID & "'\""
					set ZFILEUUID to do shell script thescript
					
					# ---------- Get the master's path
					set thescript to p_sql & databasePath & " \"select IMAGEPATH from RKMASTER where UUID='" & ZFILEUUID & "'\""
					set ZIMAGEPATH to do shell script thescript
					
					# ---------- Get the master's disk name
					set thescript to p_sql & databasePath & " \"select FILEVOLUMEUUID from RKMASTER where UUID='" & ZFILEUUID & "'\""
					set ZFILEVOLUMEUUID to do shell script thescript
					set thescript to p_sql & databasePath & " \"select NAME from RKVOLUME where UUID='" & ZFILEVOLUMEUUID & "'\""
					set diskName to do shell script thescript
					
					set imgPath to "/Volumes/" & diskName & "/" & ZIMAGEPATH
					set linkName to linksPath & "/" & quoted form of masterName
					set thescript to "rm " & linkName & "; ln -s " & quoted form of imgPath & " " & linkName
					try
						do shell script thescript
					end try
				end if
				
			end repeat
			set my progressCounter to (my progressCounter) + 1
		end tell
	end addLinks
	
	-----------------------------------------------------------------------------------------------------------------------
	on exportStatus:myProject
		set notesFile to (my fullProjectPath:myProject) & "/notes.txt"
		tell application "Finder"
			try
				POSIX file notesFile as alias
				return "Exported"
			on error
				return "Not exported"
			end try
		end tell
	end exportStatus:
	
	-----------------------------------------------------------------------------------------------------------------------
	on projectPath:myProject
		set myProjectName to name of myProject
		-- if it is a month, turn it into a number, otherwise leave it as is
		set myProjectName to my monthToIntegerString:(myProjectName)
		tell application "Aperture"
			if name of parent of myProject is "Aperture Library" then
				set returnVal to name of myProject as string
				return returnVal
			else
				return (my projectPath:(parent of myProject)) & my separator & (my monthToIntegerString:(name of myProject))
			end if
		end tell
	end projectPath:
	
	-----------------------------------------------------------------------------------------------------------------------
	on fullProjectPath:myProject
		set exportFolder to my exportPath & "/" & (my projectPath:myProject)
		--my logg:("exportFolder: " & exportFolder)
		return exportFolder
	end fullProjectPath:
	
	-----------------------------------------------------------------------------------------------------------------------
	on firstExportDate:myProject
		set notesFile to (my fullProjectPath:myProject) & "/notes.txt"
		
		set myFirstExportDate to current date
		set year of myFirstExportDate to 1958
		set month of myFirstExportDate to October
		set day of myFirstExportDate to 12
		
		tell application "Finder"
			try
				set myFirstExportDate to creation date of file (notesFile as POSIX file)
			end try
		end tell
		set fixedDate to my makeNSDateFrom:myFirstExportDate
		return fixedDate
	end firstExportDate:
	
	-----------------------------------------------------------------------------------------------------------------------
	on lastExportDate:myProject
		set notesFile to (my fullProjectPath:myProject) & "/notes.txt"
		
		set myFirstExportDate to current date
		set year of myFirstExportDate to 1958
		set month of myFirstExportDate to October
		set day of myFirstExportDate to 12
		
		tell application "Finder"
			try
				set myFirstExportDate to modification date of file (notesFile as POSIX file)
			end try
		end tell
		set fixedDate to my makeNSDateFrom:myFirstExportDate
		return fixedDate
	end lastExportDate:
	
	-----------------------------------------------------------------------------------------------------------------------
	on getProjectsInFolder:folderName
		local allFolders
		tell application "Aperture"
			tell folderName
				set allFolders to name of every folder
				if length of allFolders is greater than 0 then
					repeat with aFolder in allFolders
						(my getProjectsInFolder:(folder aFolder))
					end repeat
				end if
				set my allProjects to my allProjects & every project as list
			end tell
		end tell
	end getProjectsInFolder:
	
	
	-----------------------------------------------------------------------------------------------------------------------
	on logg:message
		tell current application
			log message
		end tell
	end logg:
	
	-----------------------------------------------------------------------------------------------------------------------
	on makeNSDateFrom:theASDate
		-- get components of date
		set {theYear, theMonth, theDay, theSeconds} to theASDate's {year, month, day, time}
		if theYear < 0 then
			set theYear to -theYear
			set theEra to 0
		else
			set theEra to 1
		end if
		-- make new instance of NSDateComponents and set its properties
		--set theComponents to current application's NSDateComponents's new()
		--theComponents's setEra:theEra
		--theComponents's setYear:theYear
		--theComponents's setMonth:(theMonth as integer)
		--theComponents's setDay:theDay
		--theComponents's setSecond:theSeconds
		-- tell NSCalendar to build a date from the provided components
		--set theNSDate to current application's NSCalendar's currentCalendar()'s dateFromComponents:theComponents
		(*
         In OS X 10.9, you do not need to make a new instance of NSDateComponents, instead using:	*)
		set theCalendar to current application's NSCalendar's currentCalendar()
		set theNSDate to theCalendar's dateWithEra:theEra |year|:theYear |month|:(theMonth as integer) ¬
			|day|:theDay hour:0 minute:0 |second|:theSeconds nanosecond:0
		--*)
		return theNSDate
	end makeNSDateFrom:
	
	-----------------------------------------------------------------------------------------------------------------------
	on monthToIntegerString:mN
		if (mN is "Jan") or (mN is "jan") or (mN is "January") or (mN is "january") then
			return "01"
		else if (mN is "Feb") or (mN is "feb") or (mN is "February") or (mN is "february") then
			return "02"
		else if (mN is "Mar") or (mN is "mar") or (mN is "March") or (mN is "march") then
			return "03"
		else if (mN is "Apr") or (mN is "apr") or (mN is "April") or (mN is "april") then
			return "04"
		else if (mN is "May") or (mN is "may") then
			return "05"
		else if (mN is "Jun") or (mN is "jun") or (mN is "June") or (mN is "june") then
			return "06"
		else if (mN is "Jul") or (mN is "jul") or (mN is "July") or (mN is "july") then
			return "07"
		else if (mN is "Aug") or (mN is "aug") or (mN is "August") or (mN is "august") then
			return "08"
		else if (mN is "Sep") or (mN is "sep") or (mN is "September") or (mN is "september") then
			return "09"
		else if (mN is "Oct") or (mN is "oct") or (mN is "October") or (mN is "october") then
			return "10"
		else if (mN is "Nov") or (mN is "nov") or (mN is "November") or (mN is "november") then
			return "11"
		else if (mN is "Dec") or (mN is "dec") or (mN is "December") or (mN is "december") then
			return "12"
		else
			return mN
		end if
	end monthToIntegerString:
	
	-----------------------------------------------------------------------------------------------------------------------
	on integerToMonthString:mN
		set monthss to {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
		return item mN of monthss
	end integerToMonthString:
	
	on fileExists(posixPath)
		return ((do shell script "if ls " & quoted form of posixPath & " &>/dev/null; then
        echo 1;
        else
        echo 0;
        fi") as integer) as boolean
	end fileExists
	
	-----------------------------------------------------------------------------------------------------------------------
	on getLibPath()
		tell application "System Events" to set p_libPath to value of property list item "LibraryPath" of property list file ((path to preferences as Unicode text) & "com.apple.Aperture.plist")
		
		if ((offset of "~" in p_libPath) is not 0) then
			set p_script to "/bin/echo $HOME"
			set p_homePath to (do shell script p_script)
			
			set p_offset to offset of "~" in p_libPath
			set p_path to text (p_offset + 1) thru -1 of p_libPath
			
			return p_homePath & p_path
		else
			return p_libPath
		end if
	end getLibPath
	
	on applicationShouldTerminate_(sender)
		set thescript to "rm " & my tempDatabase
		do shell script thescript
		log "Deleting database copy and exiting"
		-- Insert code here to do any housekeeping before your application quits
		return current application's NSTerminateNow
	end applicationShouldTerminate:
	
end script
