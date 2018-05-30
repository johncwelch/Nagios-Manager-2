--
--  AppDelegate.applescript
--  Nagios Manager
--
--  Created by John Welch on 5/18/18.
--  Copyright © 2018 John Welch. All rights reserved.
--

--1.0 goals to delete users from a nagios server
     
--1.1 move from hardcoded server list to user-entered list

--changed from _() to : syntax in function calls
--table columns are not editable. Table size atrib's are all solid bars
--woohoo! don't need a separate get users button, that's handled on load and by changing selection.

--BINDINGS NOTES

--array controllers
     (*popup selection: content array bound to theNagiosServerRecords as source for array,  the referencing outlet is popupSelection, referencing bindings are from the server name popup list, its content values binds to serverName in theNagiosServerRecords, controller key is arrangedObjects*)

     (*User Selection: content array bound to user array, which is an empty list. We probably should fix that at some point, but currently causes zero harm. Referencing outlet is userSelection. Referencing bindings are from the user name/ID table. the value for the user name column binds to the array controler, model key path is theUserName, controller key is arranged objects. The user key column binds to the array controller, model key path is theUserID, controller key is arranged objects*)

--popup lists

     (*server selection popup list: sent action binds to onSelectedServerName:, content values bind to the popup selection array controller*)

--pushbuttons

     (*get users button: sent action binds to getServerUsers:*)
     -- THIS HAS BEEN DELETED, BUT KEEPING COMMENT BECAUSE
     --WE MAY NEED TO PUT THIS BACK IN ONE DAY

     (*delete users button: sent action binds to deleteSelectedUsers:*)

     (*the user name/id table: (user table table view) has userTable as its referencing outlet*, user name column binds to theUserName in the user selection array controller. user id column binds to theUserID in the user selection array controller.*)
     

script AppDelegate
	property parent : class "NSObject"
     
     --this is the list of records for the nagios servers. in v2, we'll be able to add/delete from this.
     
     property theNagiosServerRecords : {{serverName:"INTMON1", serverURL:"https://nwr-nagios-internal.nwrdc.com/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"7kqlk2e8"}, ¬
     {serverName:"INTMON2", serverURL:"https://nwr-nagios-internal2.nwrdc.com/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"8jelg6bq"}, ¬
     {serverName:"DBSMON", serverURL:"http://10.105.1.79/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"orts7e5t"}, ¬
     {serverName:"DOEMON", serverURL:"http://10.10.178.195/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"aVpCpQBflf2ldtpARhXWGNXFYIgnc0PlVuekE5TgkUEAn36eDjqfmITlGp2Rp8tF"}, ¬
     {serverName:"OELMON", serverURL:"http://10.200.27.17/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"Y8HWHE7dbqjMshFb4d2kv994pVIILpDJBgWea3KkN4mvE2JXu0hjpqnSFlQmOpml"}, ¬
     {serverName:"GALMON", serverURL:"http://10.200.64.148/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"Xin8iLnhB2WvpIOusJiXODWGqWv03KCg2gHD0lbBmnm65qDR9U5eO2TueIugonPJ"}, ¬
     {serverName:"DORMON", serverURL:"http://204.89.125.112/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"mofJIoemgmeWZYVeBptfLKErCVnnIgflXN4VrBBKdOWd4RKEhdaiW4MOZqsXZKCd"}, ¬
     {serverName:"SCMON", serverURL:"http://64.56.80.135/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"ZjlHn2IRRI56EMg4Gi2QPAa0is7AB6kApId6ZbWQ9hdM3MPY47PSHY9fLfPik993"}, ¬
     {serverName:"VRMON", serverURL:"http://10.104.1.125/nagiosxi/api/v1/system/user?apikey=", serverAPIKey:"blP7RrD8A3rCAMR5glh2XWWUCXkWVF6mhcs8G6vsog4e2UiCASTNPPInN2kIHJ4e"}}
	
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
     property theDeletePattern : "^.*\\?" --the pattern we use to find where the question mark is. There's only one, so for our needs this works. this allows us to split the string at the ? so we can build a proper delete URL
     
     
	
     on applicationWillFinishLaunching:aNotification
		-- Insert code here to initialize your application before any files are opened
          --initialize our properties to the default value in the popup
          set x to my popupSelection's selectedObjects()'s firstObject() --this grabs the initial record
          --current application's NSLog("selected: %@", x)
          set my theServerName to x's serverName --grab the server name
          set my theServerAPIKey to x's serverAPIKey --grab the server key
          set my theServerURL to x's serverURL --grab the server URL
          tell userTable to setDoubleAction:"deleteSelectedUsers:"
          my getServerUsers:(missing value) --use missing value because we have to pass something. in ths case, the ASOC version of nil
     end applicationWillFinishLaunching:
	
     on applicationShouldTerminate:sender
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
     end applicationShouldTerminate:
     
     --function for if the user actually changes the default selection in the popup
     on selectedServerName:sender --the popup's sent action method is bound to this function
          set thePopupIndex to sender's indexOfSelectedItem --get the index of the selected item
          set theResult to my popupSelection's setSelectionIndex:thePopupIndex --we don't actually care about the result,
          --it's a bool, but if this stops working, we know what to log. This sets the "current selection" of the
          --array controller to thePopupIndex, so we can pull the right info for the curl commands
          set x to my popupSelection's selectedObjects() as record--grab the selected recored
          set my theServerName to x's serverName --grab the server name
          set my theServerAPIKey to x's serverAPIKey --grab the server key
          set my theServerURL to x's serverURL --grab the server api
          my getServerUsers:(missing value)
          
     end selectedServerName:
     
     on getServerUsers:sender --this isn't attached to a specific button, but we'll leave the sender
          --in case we want to do so at a future date
          set theTest to "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\""
          set my theServerJSON to do shell script "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\"" --gets the JSON dump as text
          set my theServerJSON to current application's NSString's stringWithString:my theServerJSON --convert text to NSSTring
          set my theJSONData to my theServerJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
          set {my theJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
          set my theServerUsers to users of my theJSONDict --yank out just the "users" section of the JSON return, that's
          --all we care about
          
          --doing this the long way, will fix to be more "cocoa-y" later
          repeat with x from 1 to count of my theServerUsers --iterate through theServerUsers
               set theTest to item x of theServerUsers as record --convert NSDict to record because it's initially easier
               set the end of my theUserNameList to {theUserName:|name| of theTest,theUserID:user_id of theTest} --build a list of records with the two values we care about
          end repeat
          my userSelection's removeObjects:(my userSelection's arrangedObjects()) --clear the table
          my userSelection's addObjects:my theUserNameList --fill the table
          set my theUserNameList to {} --clear out theUserNameList so it's got fresh data each time.
          set theTest to my userSelection's arrangedObjects() --as record
     end getServerUsers:
     
     on deleteSelectedUsers:sender --this activates for either the "delete user" button or a double click in the table
          try
               set theSelection to userSelection's selectedObjects() as record --this gets the selection in the table row
               --and converts the NSArray to an AS record
               set theUserIDToBeDeleted to |theUserID| of theSelection --set user id to local var
               set theUserNameToBeDeleted to |theUserName| of theSelection --set user name to local var
               set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:my theDeletePattern options:1 |error|:(missing value) --sets up the expression paramater
               set theURLNSString to current application's NSString's stringWithString:my theServerURL --create an NSSTring version of theServerURL
               set theURLLength to theURLNSString's |length| --get length of the NSString SO MUCH MORE RELIABLE THAN AS WAY
               set theMatches to theRegEx's rangeOfFirstMatchInString:my theServerURL options:0 range:[0, theURLLength] --returns a range from 0 to location of question mark. we have to bar out length or we get errors.
               set |length| of theMatches to (|length| of theMatches) - 1 --change the range so we exclude the question mark
               current application's NSLog("the matches: %@", theMatches)
               --while in theory you could use AS's "text num thru num of string" function here, it ends up erroring out all over the place.
               --dumping to NSString and back adds exactly one line of code and works. A favorable tradeoff I think.
               set theURLNSString to theURLNSString's substringToIndex:(theMatches's |length|) --substring everything up to the question mark
               set theDeleteURL to theURLNSString as text --create a text version of the NSString
               set theDeleteURL to theDeleteURL & "/" --need the trailing slash there
               set theDeleteUIDCommand to "/usr/bin/curl -XDELETE \"" & theDeleteURL & theUserIDToBeDeleted & "?apikey=" & theServerAPIKey & "&pretty=1\""
               set deleteUserButtonRecord to display alert  "You are about to delete user " & theUserNameToBeDeleted & " from " & theServerName & "\r\rARE YOU SURE?" as critical buttons {"OK","Cancel"} default button "Cancel" giving up after 90
               set deleteUserButton to button returned of deleteUserButtonRecord
                
               if deleteUserButton is "OK" then
                    set theReturn to do shell script theDeleteUIDCommand
                    current application's NSLog("delete Return: %@", theReturn) --log the results of the command
                    my getServerUsers:(missing value)
               else if deleteUserButton is "Cancel" then
                    return
               end if
          on error errorMessage number errorNumber --try block, mostly for -1728
               if errorNumber is -1728 then --nothing selected
                    display dialog "You don't have anything selected. You have to select someone to delete them"
                    current application's NSLog("Nothing Selected Error: %@", errorMessage) --log the error message
               end if
               my getServerUsers:(missing value)
               return
          end try
          
     end deleteSelectedUsers:
     
     (*on clearTable:sender --test function to see why we aren't clearing table data correctly.
          userSelection's removeObjects:(userSelection's arrangedObjects()) --clear the table
          set my theUserNameList to {} --not doing this was causing our problems
     end clearTable:*)
     
     on applicationShouldTerminateAfterLastWindowClosed:sender
          return true
     end applicationShouldTerminateAfterLastWindowClosed:
	
end script
