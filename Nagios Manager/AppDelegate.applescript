--
--  AppDelegate.applescript
--  Nagios Manager
--
--  Created by John Welch on 5/18/18.
--  Copyright © 2018 John Welch. All rights reserved.
--

--changed from _() to : syntax in function calls
--table columns are not editable. Table size atrib's are all solid bars

--BINDINGS NOTES

script AppDelegate
	property parent : class "NSObject"
     
     --this is the list of records for the nagios servers. in v2, we'll be able to add/delete from this.
     
     property theNagiosServerRecords : {{serverName:"INTMON1", serverURL:"https://nwr-nagios-internal.nwrdc.com/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"7kqlk2e8"}, ¬
     {serverName:"INTMON2", serverURL:"https://nwr-nagios-internal2.nwrdc.com/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"8jelg6bq"}, ¬
     {serverName:"DBSMON", serverURL:"http://10.105.1.79/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"orts7e5t"}, ¬
     {serverName:"DOEMON", serverURL:"http://10.10.178.195/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"aVpCpQBflf2ldtpARhXWGNXFYIgnc0PlVuekE5TgkUEAn36eDjqfmITlGp2Rp8tF"}, ¬
     {serverName:"OELMON", serverURL:"http://10.200.27.17/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"Y8HWHE7dbqjMshFb4d2kv994pVIILpDJBgWea3KkN4mvE2JXu0hjpqnSFlQmOpml"}, ¬
     {serverName:"GALMON", serverURL:"http://10.200.64.148/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"Xin8iLnhB2WvpIOusJiXODWGqWv03KCg2gHD0lbBmnm65qDR9U5eO2TueIugonPJ"}, ¬
     {serverName:"DORMON", serverURL:"http://204.89.125.112/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"mofJIoemgmeWZYVeBptfLKErCVnnIgflXN4VrBBKdOWd4RKEhdaiW4MOZqsXZKCd"}, ¬
     {serverName:"SCMON", serverURL:"http://64.56.80.135/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"ZjlHn2IRRI56EMg4Gi2QPAa0is7AB6kApId6ZbWQ9hdM3MPY47PSHY9fLfPik993"}, ¬
     {serverName:"VRMON", serverURL:"http://10.104.1.125/nagiosxi/api/v1/system/user/?apikey=", serverAPIKey:"blP7RrD8A3rCAMR5glh2XWWUCXkWVF6mhcs8G6vsog4e2UiCASTNPPInN2kIHJ4e"}}
	
	-- IBOutlets
	property theWindow : missing value
     property popupSelection:missing value --this is attached to the array controller's referencing outlet
     --it contains the full record for the selected server name in the popup list
     property userSelection : missing value--this is attached to the user array referencing outlet
     --contains the user values we care about, name and ID
     property userArray:{} --this serves the same function as theNagiosServerRecords, but is blank. we may dump this at some point
     property userTable : missing value --this is so we can have teh doble clickz 
     
     --Other Properties
     property theServerName:"" --name of the server for curl ops
     property theServerAPIKey:"" --API key of server for curl ops
     property theServerURL:"" --URL of server for curl ops
     
     property theServerJSON:"" --the list of stuff from the server as JSON
     property theJSONData:"" --used to hold the converted theServerJSON text data as an NSData object
     property theJSONDict:"" --this holds the result of NSJSONSerialization as an NSArray of NSDicts
     property theServerUsers:"" --grabs just the users out of theJSONDict as a NSArray of NSDicts
     property theUserName:"" --user name from the nagios server
     property theUserID:"" --user id from the nagios server
     property theUserNameList:{} --a list of records we convert from NSDicts
     
	
     on applicationWillFinishLaunching:aNotification
		-- Insert code here to initialize your application before any files are opened
          --initialize our properties to the default value in the popup
          set x to popupSelection's selectedObjects()'s firstObject() --this grabs the initial record
          current application's NSLog("selected: %@", x)
          set my theServerName to x's serverName --grab the server name
          set my theServerAPIKey to x's serverAPIKey --grab the server key
          set my theServerURL to x's serverURL --grab the server URL
          tell userTable to setDoubleAction:"manageSelectedUsers:"
     end applicationWillFinishLaunching:
	
     on applicationShouldTerminate:sender
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
     end applicationShouldTerminate:
     
     --function for if the user actually changes the default selection in the popup
     on selectedServerName:sender --the popup's sent action method is bound to this function
          set thePopupIndex to sender's indexOfSelectedItem --get the index of the selected item
          set theResult to popupSelection's setSelectionIndex:thePopupIndex --we don't actually care about the result,
          --it's a bool, but if this stops working, we know what to log. This sets the "current selection" of the
          --array controller to thePopupIndex, so we can pull the right info for the curl commands
          set x to popupSelection's selectedObjects()--grab the selected recored
          set my theServerName to x's serverName --grab the server name
          set my theServerAPIKey to x's serverAPIKey --grab the server key
          set my theServerURL to x's serverURL --grab the server api
     end selectedServerName:
     
     on getServerUsers:sender
          set theTest to "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\""
          set theServerJSON to do shell script "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\"" --gets the JSON dump as text
         -- current application's NSLog("selected: %@", theTest)
          set theServerJSON to current application's NSString's stringWithString:theServerJSON --convert text to NSSTring
          set theJSONData to theServerJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
          set {theJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
          set theServerUsers to users of theJSONDict --yank out just the "users" section of the JSON return, that's
          --all we care about
          
          --doing this the long way, will fix to be more "cocoa-y" later
          repeat with x from 1 to count of theServerUsers --iterate through theServerUsers
               set theTest to item x of theServerUsers as record --convert NSDict to record because it's initially easier
               set the end of my theUserNameList to {theUserName:|name| of theTest,theUserID:user_id of theTest} --build a list of records with the two values we care about
          end repeat
          
          
          userSelection's removeObjects:(userSelection's arrangedObjects()) --clear the table
          userSelection's addObjects:theUserNameList --fill the table
          set my theUserNameList to {} --clear out theUserNameList so it's got fresh data each time.
     end getServerUsers:
     
     on manageSelectedUsers:sender --this activates for either the "delete user" button or a double click in the table
          set theSelection to userSelection's selectedObjects() as record --this gets the slection in the table row
          --and converts the NSArray to an AS record
     end manageSelectedUsers:
     
     (*on clearTable:sender --test function to see why we aren't clearing table data correctly.
          userSelection's removeObjects:(userSelection's arrangedObjects()) --clear the table
          set my theUserNameList to {} --not doing this was causing our problems
     end clearTable:*)
     
     on applicationShouldTerminateAfterLastWindowClosed:sender
          return true
     end applicationShouldTerminateAfterLastWindowClosed:
	
end script
