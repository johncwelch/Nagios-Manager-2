--
--  AppDelegate.applescript
--  Nagios Manager
--
--  Created by John Welch on 5/18/18.
--  Copyright © 2018 John Welch. All rights reserved.
--

--1.0 goals: to delete users from a nagios server
--1.1 goals: add a local user to a nagios server (make sure to label as "local only, no AD"
     --URL scheme for adding is same as getting info, so no change necessary there, woohoo!
     --hardcode:
          --language: "xi default"
          --date_format: 1
          --number_format: 1
          --use radio buttons for auth_level default to user.
               --if admin selected, all options but read-only are enabled and unchangeable
          --if read_only set to 1, then auth-level is forced to user, only "see all" is changeable, others set to 0
     --all text fields are mandatory
     --when using this, force_pw_change, email_info, monitoring_contact, enable_notifications are always set to 1
     --sans the NSMatrix object, point all "related" radio buttons at the same thing to get them to work "together" properly.
	--BONUS, figured out autoincrementing builds (see the build phases for details)
--1.2 goals : build tabbed interface so we can add a server manager (add/remove) tab that's separate from user manager (and other features eventually
--1.3 move from hardcoded server list to user-entered list

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
     property canSeeAllObjects : missing value --attached to same-named checkbox
     property canReconfigureAllObjects : missing value --attached to same-named checkbox
     property canControlAllObjects : missing value --attached to same-named checkbox
     property canSeeOrConfigureMonitoringEngine : missing value --attached to same-named checkbox
     property canAccessAdvancedFeatures : missing value --attached to same-named checkbox
     property readOnly : missing value --attached to same-named checkbox
     property adminRadioButton : missing value --attached to "admin" radio button
     property userRadioButton : missing value --attached to "user" radio button
     
     
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
     property theRESTresults : "" --so we can show the results of rest commands as appropriate
     
     property theNewUserName : "" --name of user to be added
     property theNewUserPassword : "" --password of user to be added
     property theNewName : "" --name, not username of the user to be added
     property theNewUserEmailAddress : "" --email address of user to be added
	property theUserType : "" --used to test for user level
	
	--hardcoded Nagios create user parameters, these aren't initially settable, but later they might be so just in case
	property theNagiosLanguage: "xi default" --use whatever the default for the server is
	property theNagiosDateFormat: "1" --the default nagios date format, try as text initially
	property theNagiosNumberFormat: "1" --the default nagios number format, try as text initially
	property theNagiosForcePasswordChange : "1" --always require an initial password change
	property theNagiosEmailAccountInfo : "1" --always email the user the account info
	property theNagiosMonitoringContact : "1" --always a monitoring contact
	property theNagiosEnableNotifications : "1" --always enable notifications
	
	--other add user parameters
	property theNagiosNewUserName: ""
	property theNagiosNewUserPassword: ""
	property theNagiosNewUserRealName: ""
	property theNagiosNewUserEmailAddress: ""
     
     
	
     on applicationWillFinishLaunching:aNotification
		-- Insert code here to initialize your application before any files are opened
          --initialize our properties to the default value in the popup
          set x to my popupSelection's selectedObjects()'s firstObject() --this grabs the initial record
		current application's NSLog("first thing in popup controller: %@", x)
          --current application's NSLog("selected: %@", x)
          set my theServerName to x's serverName --grab the server name
          set my theServerAPIKey to x's serverAPIKey --grab the server key
          set my theServerURL to x's serverURL --grab the server URL
          tell userTable to setDoubleAction:"deleteSelectedUsers:" --this lets a doubleclick work as well as clicking the delete button. We may remove this
		--because it could be dangrous
          my getServerUsers:(missing value) --use missing value because we have to pass something. in ths case, the ASOC version of nil
          
          --set the initial state and enabled of the checkboxes
          my canSeeAllObjects's setEnabled:true
          my canSeeAllObjects's setState:1
          my canReconfigureAllObjects's setEnabled:true
          my canReconfigureAllObjects's setState:0
          my canControlAllObjects's setEnabled:true
          my canControlAllObjects's setState:1
          my canSeeOrConfigureMonitoringEngine's setEnabled:true
          my canSeeOrConfigureMonitoringEngine's setState:0
          my canAccessAdvancedFeatures's setEnabled:true
          my canAccessAdvancedFeatures's setState:1
          my readOnly's setEnabled:true
          my readOnly's setState:0
		--current application's NSLog("admin button state: %@", my adminRadioButton's objectValue())
		--current application's NSLog("user button state: %@", my userRadioButton's objectValue())
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
          --set theTest to "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\""
          set my theServerJSON to do shell script "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\"" --gets the JSON dump as text
          set my theServerJSON to current application's NSString's stringWithString:my theServerJSON --convert text to NSSTring
          set my theJSONData to my theServerJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
          set {my theJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
          set my theServerUsers to users of my theJSONDict --yank out just the "users" section of the JSON return, that's
          --all we care about
          
          --doing this the long way, will fix to be more "cocoa-y" later
          repeat with x from 1 to count of my theServerUsers --iterate through theServerUsers
               set theItem to item x of theServerUsers as record --convert NSDict to record because it's initially easier
               set the end of my theUserNameList to {theUserName:|name| of theItem,theUserID:user_id of theItem} --build a list of records with the two values we care about
          end repeat
		current application's NSLog("theUserNameList: %@", my theUserNameList)
          my userSelection's removeObjects:(my userSelection's arrangedObjects()) --clear the table
          my userSelection's addObjects:my theUserNameList --fill the table
          set my theUserNameList to {} --clear out theUserNameList so it's got fresh data each time.
          --set theItem to my userSelection's arrangedObjects() --as record
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
               set deleteUserButtonRecord to display alert  "You are about to delete user " & theUserNameToBeDeleted & " from " & theServerName & "\r\rARE YOU SURE?" as critical buttons {"OK","Cancel"} default button "Cancel" giving up after 90 --last chance warning
               set deleteUserButton to button returned of deleteUserButtonRecord --get button user clicked
                
               if deleteUserButton is "OK" then --buh-bye
                    set my theRESTresults to do shell script theDeleteUIDCommand --run the delete command, display results in the window
                    current application's NSLog("delete Return: %@", my theRESTresults) --log the results of the command
                    my getServerUsers:(missing value) --reload the user list from the selected server to show the user has been deleted
               else if deleteUserButton is "Cancel" then
                    return
               end if
          on error errorMessage number errorNumber --try block, mostly for -1728
               if errorNumber is -1728 then --nothing selected
                    display dialog "You don't have anything selected. You have to select someone to delete them" --error message for -1728
                    --if we get enough of these, we'll create a separate function just for them
                    current application's NSLog("Nothing Selected Error: %@", errorMessage) --log the error message
               end if
               my getServerUsers:(missing value) --reload the list
               return
          end try
          
     end deleteSelectedUsers:
     
     on getUserLevel:sender --This is only here to handle the user type radio buttons. but, it works well enough for that.
          set my theUserType to sender's title as text--get user level as text
          --certain checkboxes.
          --current application's NSLog("sender's title: %@", theUserType)
          if my theUserType is "Admin" then --set the checkbutton states to the appropriate setting for an admin
               my canSeeAllObjects's setState:1
               my canReconfigureAllObjects's setState:1
               my canControlAllObjects's setState:1
               my canSeeOrConfigureMonitoringEngine's setState:1
               my canAccessAdvancedFeatures's setState:1
               my readOnly's setEnabled:false --note this is how nagios does it in the web UI, so we are mirroring that behavior here
               my readOnly's setState:0
          else if my theUserType is "User" then
               my canSeeAllObjects's setState:1
               my canReconfigureAllObjects's setState:0
               my canControlAllObjects's setState:1
               my canSeeOrConfigureMonitoringEngine's setState:0
               my canAccessAdvancedFeatures's setState:1
               my readOnly's setEnabled:true
               my readOnly's setState:0
          end if
     end getUserLevel:
     
     on enabledReadOnly:sender --this action is only bound to the read only button
          if sender's intValue() = 1 then --if we set it to read only, we clear all the other buttons and disable them
               --we also force the user type to "user" and disable the admin radio button. A read-only admin is stupid.
               --again, this is how nagios does it in the web UI, so we shall here
                --ALWAYS USE () FOR THIS KIND OF THING ELSE YOU WILL BE IN HELL!
              --current application's NSLog("admin button's integer value: %@", theTest)
               my canSeeAllObjects's setEnabled:false
               my canSeeAllObjects's setState:0
               my canReconfigureAllObjects's setEnabled:false
               my canReconfigureAllObjects's setState:0
               my canControlAllObjects's setEnabled:false
               my canControlAllObjects's setState:0
               my canSeeOrConfigureMonitoringEngine's setEnabled:false
               my canSeeOrConfigureMonitoringEngine's setState:0
               my canAccessAdvancedFeatures's setEnabled:false
               my canAccessAdvancedFeatures's setState:0
               my userRadioButton's setState:1
               my adminRadioButton's setState:0
               my adminRadioButton's setEnabled:false
          else if sender's intValue() = 0 then --don't try to reset the state, just re-enable the other checkbox buttons
              --current application's NSLog("admin button's integer value: %@", theTest)
               my canSeeAllObjects's setEnabled:true
               my canSeeAllObjects's setState:1
               my canReconfigureAllObjects's setEnabled:true
               my canReconfigureAllObjects's setState:0
               my canControlAllObjects's setEnabled:true
               my canControlAllObjects's setState:1
               my canSeeOrConfigureMonitoringEngine's setEnabled:true
               my canSeeOrConfigureMonitoringEngine's setState:0
               my canAccessAdvancedFeatures's setEnabled:true
               my canAccessAdvancedFeatures's setState:1
               my adminRadioButton's setEnabled:true
          end if
          --set theTest to my readOnly's intValue
          --current application's NSLog("read only's integer value: %@", readOnlyToggle) --log the error message
          
     end enabledReadOnly:
	
	on addUser:sender --kicks off when add user button is clicked
		set my theRESTresults to "" --clear the notification field value
		set isAdminUser to my adminRadioButton's objectValue() --get the value of the admin radio button, since it's mutually exclusive
		if isAdminUser then
			set theAuthLevel to "admin"
		else if not isAdminUser then
			set theAuthLevel to "user"
		end if
		
		if (my theNagiosNewUserName is missing value) or (my theNagiosNewUserName is "") then --test for blank username
			set my theRESTresults to "The Username field cannot be blank"
			return
		end if
		
		if (my theNagiosNewUserPassword is missing value) or (my theNagiosNewUserPassword is "") then --test for blank password
			set my theRESTresults to "The password field cannot be blank"
			return
		end if
		
		if (my theNagiosNewUserRealName is missing value) or (my theNagiosNewUserRealName is "") then --test for blank user's name
			set my theRESTresults to "The Name field cannot be blank"
			return
		end if
		
		if (my theNagiosNewUserEmailAddress is missing value) or (my theNagiosNewUserEmailAddress is "") then --test for blank email address
			set my theRESTresults to "The Email Address field cannot be blank"
			return
		end if
		
		(*this next line builds the actual command to add a user. There's a lot of things that are hardcoded as that's the norm.
		 it's not a problem to fix later if we need, the variables are already declared, just unused.*)
		set theAddCommand to "/usr/bin/curl -XPOST \"" & (my theServerURL as text) & (my theServerAPIKey as text) & "&pretty=1\"" & " -d \"username=" & my theNagiosNewUserName & "&password=" & my theNagiosNewUserPassword & "&name=" & my theNagiosNewUserRealName & "&email=" & my theNagiosNewUserEmailAddress & "&force_pw_change=1&email_info=1&monitoring_contact=1&enable_notifications=1&language=xi default&date_format=1&number_format=1&auth_level=" & theAuthLevel & "&can_see_all_hs=" & my canSeeAllObjects's intValue() & "&can_control_all_hs=" & my canControlAllObjects's intValue() & "&can_reconfigure_hs=" & my canReconfigureAllObjects's intValue() & "&can_control_engine=" & my canSeeOrConfigureMonitoringEngine's intValue() & "&can_use_advanced=" & my canAccessAdvancedFeatures's intValue() & "&read_only=" & my readOnly's intValue() & "\""
		
		current application's NSLog("Add User Return: %@", my theRESTresults) --log the results of the command
		set my theRESTresults to do shell script theAddCommand --add the user
		my getServerUsers:(missing value) --reload the list
	end addUser:
	
	on cancelAddUser:sender --cancel adding a user function. blank out text fields, reset checkboxes and radios to default states
		my userRadioButton's setState:1
		my adminRadioButton's setState:0 --this is technically not needed, but doesn't cause any real problems either
		set my theNagiosNewUserName to ""
		set my theNagiosNewUserPassword to ""
		set my theNagiosNewUserRealName to ""
		set my theNagiosNewUserEmailAddress to ""
		my canSeeAllObjects's setState:1
		my canReconfigureAllObjects's setState:0
		my canControlAllObjects's setState:1
		my canSeeOrConfigureMonitoringEngine's setState:0
		my canAccessAdvancedFeatures's setState:1
		my readOnly's setEnabled:true
		my readOnly's setState:0
		
		set my theRESTresults to "" --clear the notification field value
	end cancelAddUser:
     
     (*on clearTable:sender --test function to see why we aren't clearing table data correctly.
          userSelection's removeObjects:(userSelection's arrangedObjects()) --clear the table
          set my theUserNameList to {} --not doing this was causing our problems
     end clearTable:*)
     
     on applicationShouldTerminateAfterLastWindowClosed:sender
          return true
     end applicationShouldTerminateAfterLastWindowClosed:
	
end script
