--
--  AppDelegate.applescript
--  Nagios Manager
--
--  Created by John Welch on 5/18/18.
--  Copyright © 2018 John Welch. All rights reserved.
--step 1 : get a good sized pumpkin

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
--step 2: cut pumpkin into wedges about 4" wide and remove pulp
--1.2 goals : build tabbed interface so we can add a server manager (add/remove) tab that's separate from user manager (and other features eventually
--1.3 move from hardcoded server list to user-entered list. This will be fun
--1.4 Get a proper icon and make the menus in the menubar actually do something
--1.5 convert time periods and contacts in new host to pulldowns/popups and see about duplicate code, like grep & json code

--changed from _() to : syntax in function calls
--table columns are not editable. Table size atrib's are all solid bars
--woohoo! don't need a separate get users button, that's handled on load and by changing selection.
--step 3: heat oven to 400 degrees F. No, you're not pre-heating it, don't make me come over there

--BINDINGS NOTES

--array controllers
     (*User Selection: content array bound to user array, which is an empty list. We probably should fix that at some point, but currently causes zero harm. Referencing outlet is userSelection. Referencing bindings are from the user name/ID table. the value for the user name column binds to the array controler, model key path is theUserName, controller key is arranged objects. The user key column binds to the array controller, model key path is theUserID, controller key is arranged objects*)
--step 5: cook pumpkin wedges for about 2 hours, maybe 2.5, skin-side down. If the skin's a bit burnt, that's fine, it comes off easier that way.
--popup lists

	(*Server Table Controller: array controller bound to server array. This is filled from the defaults plist file.
		referencing outlet: theServerTableController
		content array: theSMServerTableControllerArray
		referencing bindings:
			arranged objects.theSMTableServerAPIKey value is server api key column in server table
			arranged objects.theSMTableServerName value is server name
				content value is item 1  in the server selection popup in User manager. This is so that the popup there can use the server name in the prefs
			arranged objects.theSMTableURL value is server url*)

     (*server selection popup list: sent action binds to onSelectedServerName:, content values bind to the server table array controller*)

--pushbuttons

     (*get users button: sent action binds to getServerUsers:*)
     -- THIS HAS BEEN DELETED, BUT KEEPING COMMENT BECAUSE
     --WE MAY NEED TO PUT THIS BACK IN ONE DAY
--Step 6: let pumpkin cool, then cut it out of the skin. I mean, you can do it right away, but it's kind of hot
     (*delete users button: sent action binds to deleteSelectedUsers:*)

     (*the user name/id table: (user table table view) has userTable as its referencing outlet*, user name column binds to theUserName in the user selection array controller. user id column binds to theUserID in the user selection array controller.*)

	--minor comment note: I'm now trying to organize properties by what tab they apply to. So Server Manager, User Manager, etc.
--step 7: Run chunks through a mixer, then pipe the mixer output into a blender. You can skip the mixer, but it makes things a lot easier. basically, you want pumpkin slurry
-- god I hate git. so much

script AppDelegate
	property parent : class "NSObject"
	
	--Application - level IBOutlets
	property theWindow : missing value --outlet for theWindow
	property theTabView : missing value --outlet for the tab view. not any individual tab, but all the tabs
	
	
	
	-- User Manager IBOutlets
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
--step 8: other pie ingredients. This is per batch, each batch makes about 1.8 pies - 2 eggs, 1 3/4 cups pumpkin, 3/4ths cup brown sugar
	--1 1/2 cups sweetened condensed milk. I just used the whole 14 oz. can, it's fine. It's pie, not souffle. 1/2 tsp salt
	--1 tsp ground cinnamon
	--1/2 tsp ground ginger
	--1/4 tsp ground cloves
	--pie crust of choice. This pie has flavor so a blander crust works better. I like graham cracker or 'nilla wafer crusts
	--just buy them, this pie takes long enough as it is
	
	--User Manager Other properties
	property theServerJSON:"" --the list of stuff from the server as JSON
	property theJSONData:"" --used to hold the converted theServerJSON text data as an NSData object
	property theJSONDict:"" --this holds the result of NSJSONSerialization as an NSArray of NSDicts
	property theServerUsers:"" --grabs just the users out of theJSONDict as a NSArray of NSDicts
	property theUserName:"" --user full name from the nagios server
	property theUserID:"" --user id from the nagios server
	
	property theOtherUserInfoList : {} -- alist of records we'll need to do something cool without a gob of recoding
	
	property theUserNameList:{} --a list of records we convert from NSDicts
	--property theDeletePattern : "^.*\\?" --the pattern we use to find where the question mark is. There's only one, so for our needs this works. this allows us to split the string at the ? so we can build a proper delete URL
	property theDeletePattern : "\\?" --figured out how to do NSRegularExpressions SO much better. This is the new pattern
--step 9: put all the ingredients in a blender (blenders are your friend) and run until everything is liquid AF
	
	
	property theNewUserName : "" --name of user to be added
	property theNewUserPassword : "" --password of user to be added
	property theNewName : "" --name, not username of the user to be added
	property theNewUserEmailAddress : "" --email address of user to be added
	property theUserType : "" --used to test for user level
--step 10: pour contents of blender into pie crust until almost full. There's not a lot of expansion, so no worries.
	
	--User Manager add user parameters
	property theNagiosNewUserName: ""
	property theNagiosNewUserPassword: ""
	property theNagiosNewUserRealName: ""
	property theNagiosNewUserEmailAddress: ""
--step 11: heat oven to 425 degrees F. Again, if I hear you say "pre-heat, I'm stealing the pie
	
	--hardcoded Nagios create user parameters, these aren't initially settable, but later they might be so just in case
	property theNagiosLanguage: "xi default" --use whatever the default for the server is
	property theNagiosDateFormat: "1" --the default nagios date format, try as text initially
	property theNagiosNumberFormat: "1" --the default nagios number format, try as text initially
	property theNagiosForcePasswordChange : "1" --always require an initial password change
	property theNagiosEmailAccountInfo : "1" --always email the user the account info
	property theNagiosMonitoringContact : "1" --always a monitoring contact
	property theNagiosEnableNotifications : "1" --always enable notifications
--step 12: bake at 425 for 15 minutes or so, then reduce to 350 for 45 minutes or so until it passes the toothpick test


	-- Server manager IBOutlets
	property theDefaults : missing value --referencing outlet for our NSDefaults object
	property theServerTable : missing value --table view referencing outlet
	property theServerTableController : missing value --server table array controller referencing outlet
--step 13: eat the hell out of that pie. See? a prize for reading comments!
	
	--Server manager other properties
	
	property theSMServerName : "" --used to be theServerName, avoiding overuse of properties here
	property theSMServerURL : "" --used to be theServerURL, avoiding overuse of properties here
	property theSMServerAPIKey : "" --used to be theServerAPIKey, avoiding overuse of properties here
	property theSMServerTableControllerArray : {} --bound to content of the server table controller, not used
	property theSMTableServerName : "" --bound to server name column in table
	property theSMTableServerURL : "" --bound to server url column in table
	property theSMTableServerAPIKey : "" --bound to server API Key column in table
	
	property theSMSettingsExist : "" --are there any settings already there?
	property theSMDefaultsExist : "" --are there currently settings?
	property theSMSettingsList : {} --settings list array
	property theSMSDeletingLastServerFlag : false --if you're about to manually delete the last server, we set this to true so you don't get two alerts
	property theSMStatusFieldText : "" --binding for the text field at the bottom of the Server Manager. Allows it and User Manager to have different statuses
	
	--Host Manager IB Outlets
	property theHostTableController : missing value --referencing outlet for host array controller
	property theHostTable : missing value --referencing outlet for host table
	property theHostStatusHUD : missing value --referencing outlet for host status info hud
	
	--Host Manager Other properties
	property theHMHostTableControllerArray : {} --bound to content of the host manager array controller, probably not used.
	property theHMHostSearchPattern : "system/user"
	property theHMHostReplacementPattern : "objects/host"
	property theHMNewHostReplacementPattern : "config/host"
	property theHMHostStatusReplacementPattern: "objects/hoststatus"
	property theHMHostListJSON : "" --the initial storage for the result of the get all hosts curl command
	property theHMHostListJSONData : {} --the NSData version of theHMHostListJSON
	property theHMHostListJSONDict : {} --the NSDictionary version of theHMHostListJSONData
	property theHMHostCount : "" --holds a count of hosts
	property theHMHostListRecord : {} --the array we use to load all the host info into the host array controller
	property theHMStatusDisplay : "" --for status messages in the host tab
	property theHMServerName : "" -- current host manager server name, used to populate the host manager server popup
	property theHMServerAPIKey : "" --current host manager server API key
	property theHMServerURL : "" --current host manager server URL
	
	property theHMHostID : "" --binding for "host ID" field in the host status HUD
	property theHMHostLastStatus : "" --binding for the "Last Status" field in the Host status HUD
	property theHMHostLastStatusUpdateTime : "" --binding for the "Last Status Update Time" field in the host status HUD
	property theHMHostLastTimeDown : "" --binding for the "Last Time Down" field in the host status HUD
	property theHMHostLastTimeUnreachable : "" --binding for the "Last Time Unreachable" field in the host status HUD
	property theHMHostLastCheck : "" --binding for the "Last Check" field in the host status HUD
	property theHMHostNextCheck : "" --binding for the "Next Check" field in the host status HUD
	property theHMHostFlapDetectionEnabled : "" --binding for the "Flap Detection Enabled" field in the host status HUD
	property theHMHostIsFLapping : "" --binding for the "Is Flapping?" field in the host status HUD
	property theHMHostProblemAcknowledged : "" --binding for the "Problem Acknowledged?"
	
	
	--hardcoded values for adding new hosts
	property theHMNewHostCheckCommand : "check_command=check-host-alive"
	property theHMNewHostActiveChecksEnabled : "active_checks_enabled=1"
	property theHMNewHostPassiveChecksEnabled : "passive_checks_enabled=1"
	property theHMNewHostCheckPeriod : "check_period=xi_timeperiod_24x7" --this will eventually be a selectable popup/dropdown
	property theHMNewHostProcessPerfData: "process_perf_data=1"
	
	--user-set values for adding new hosts, with some (changeable) defaults
	property theHMNewHostName: ""
	property theHMNewHostAddress: ""
	property theHMNewHostCheckInterval : "5"
	property theHMNewHostRetryInterval : "1"
	property theHMNewHostMaxCheckAttempts : "5"
	property theHMNewHostNotificationsEnabled : "1"
	property theHMNewHostNotificationOptions : "d,u,r"
	property theHMNewHostFirstNotificationDelay : "0"
	property theHMNewHostNotificationInterval : "5"
	property theHMNewHostContacts : "" --this will eventually be a selectable popup/dropdown
	property theHMNewHostNotificationPeriod : "xi_timeperiod_24x7" --this will eventually be a selectable popup/dropdown
	
	
	
     --General Other Properties
     property theServerName:"" --name of the server for curl ops
     property theServerAPIKey:"" --API key of server for curl ops
     property theServerURL:"" --URL of server for curl ops
	property theRESTresults : "" --so we can show the results of rest commands as appropriate. This is actually a generic display value for bottom information display
		--I might fix it when I'm doing cleanup. or not.
	property theSelectedTabViewItemIndex : "" --the index of the currently selected tab view item. Note this doesn't have any real value until a
	--selection is made via mouse or key combo or menu item
	property theSelectedTabIsCorrect:false --flag for making sure the initial tab on launch is correct
	property theUMInitialUserLoadDone : false --flag to check if the initial user table load was done. false by default so that the first tab click/selection does the load
	property theHMInitialUserLoadDone : false --flag to check if the initial host table load was done. false by default so that the first tab click/selection does the load
	

	
     on applicationWillFinishLaunching:aNotification
		-- Insert code here to initialize your application before any files are opened
          --initialize our properties to the default value in the popup
		
		set theTest to my theTabView's numberOfTabViewItems()
		--log "Number of Tab View Items: " & theTest as text
		--set theTest to my theTabView's tabViewItems()
		--current application's NSLog("tabViewItems: %@", theTest)
		
		--SERVER MANAGER SETUP
		set my theDefaults to current application's NSUserDefaults's standardUserDefaults() --make theDefaults the container
		--for defaults operations
		my theDefaults's registerDefaults:{serverSettingsList:{}} --sets up "serverSettingsList" as a valid defaults key
		--changed to more correctly init as array instead of string. It also deals with nils much better
		
		set my theSMSettingsList to (my theDefaults's arrayForKey:"serverSettingsList")'s mutableCopy() --this removes a bit of code by
		--folding the NSMutableArray initialization and keeps it mutable even after copying the contents of serverSettingsList into it.
		
		set my theSMDefaultsExist to theDefaults's boolForKey:"hasDefaults"
		--current application's NSLog("theDefaultsExist: %@", my theDefaultsExist) --this is just here for when I need it elsewhere, I can
		--copy/paste easier
		
		if not my theSMDefaultsExist then --if there are not defaults, let the user know this so they can fix that issue.
			display dialog "there are no default settings existing at launch" --my version of a first run warning. Slick, ain't it.
			set my theSMStatusFieldText to "If you're seeing this, then there's no servers saved in the app's settings. This tab is where you add them.\r\rYou'll need three things - the server's name, URL and API Key. For the URL, only the first part, i.e. https://server.com/ is needed. The \"full\" URL is generated from that.\r\rThe app itself is pretty simple. You can add or remove servers. Those are saved locally on your mac.\rThose servers are used to pull down user info in the User Manager tab. More info will be in the (currently nonexistent) help. One day, that help will exist. This is not that day."
		else if my theSMDefaultsExist then --there's no point in running loadServerTable: if there's no data to load
			my loadServerTable:(missing value) -- initial load of existing data into the server table.
		end if
		
		tell my theServerTable to setDoubleAction:"deleteServerFromPrefs:" --this ties a doubleclick in the server to deleting that server.
		--current application's NSLog("theServerTableController's first object: %@", theTest)
		
		
		
		
		--USER MANAGER SETUP
		
		--we moved the initial load of user data from here so that it only does the initial load when the user manager tab is selected.
		--speeds up app launch. It's now in tabView:tabView didSelectTabViewItem:sender
		
		tell my userTable to setDoubleAction:"deleteSelectedUsers:" --this lets a doubleclick work as well as clicking the delete button. We may remove this
		--because it could be dangerous
          
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
		my theTabView's selectTabViewItemAtIndex:0 --this ensures the server manager tab is always the active tab on launch
		--note that we do this in a few places, but if the application hard crashes, there's not anything we can do to set things correctly in time. So hopefully, the application won't crash.
		set my theSelectedTabIsCorrect to true
		
		--HOST MANAGER SETUP
     end applicationWillFinishLaunching:
	
	--on applicationDidFinishLaunching:aNotification
	--	my theTabView's selectTabViewItemAtIndex:0 --this ensures the server manager tab is always the active tab on launch.
		--well, it's an attempt to do that
	--	set my theSelectedTabIsCorrect to true
	--end applicationDidFinishLaunching:
	
     on applicationShouldTerminate:sender
		-- Insert code here to do any housekeeping before your application quits
		my theTabView's selectTabViewItemAtIndex:0 --this ensures the server manager tab is always the active tab on launch
		set my theSelectedTabIsCorrect to false --reset this to the correct application quit state
		set theUMInitialUserLoadDone to false --reset this to the correct application quit state
		return current application's NSTerminateNow
     end applicationShouldTerminate:
	
	--WINDOW TAB FUNCTIONS
	
	--these are all bound to the appropriate menu items' sent action
	
	on selectedServerManagerTab:sender --select server manager tab with Window Menu item or key equivalent (cmd-1)
		my theTabView's selectTabViewItemAtIndex:0 --sets the tab with the specified index to be frontmost/current
	end selectedServerManagerTab:
	
	on selectedUserManagerTab:sender --select user manager tab with Window Menu item or key equivalent (cmd-2)
		my theTabView's selectTabViewItemAtIndex:1 --sets the tab with the specified index to be frontmost/current
	end selectedUserManagerTab:
	
	on selectedHostManagerTab:sender --select host manager tab with Window Menu item or key equivalent (cmd-3)
		my theTabView's selectTabViewItemAtIndex:2 --sets the tab with the specified index to be frontmost/current
	end selectedHostManagerTab:

	on tabView:tabView didSelectTabViewItem:sender --this runs any time a tab is selected via click, menu item or programmatically.
		if theSelectedTabIsCorrect then
			set my theSelectedTabViewItemIndex to tabView's indexOfTabViewItem:(sender)
			set my theSelectedTabViewItemIndex to my theSelectedTabViewItemIndex as text
			if theSelectedTabIsCorrect then
				if my theSelectedTabViewItemIndex is "0" then --clicked on Server Manager tab. Honestly, this may never do much of anything
					--the initial server tab operations are handled in applicationWillFinishLaunching and other places. But just in case
					--it's here
					--log "server"
				else if my theSelectedTabViewItemIndex is "1" then --this moves the initial user load to a more lazy system, where it doesn't
				--kick in until the user tab is selected at least once.
					if not my theUMInitialUserLoadDone then --the user manager hasn't loaded at least once. This prevents us from continually
						--sending curl commands every time someone clicks on a tab
						if my theSMDefaultsExist then --if we have no servers in the defaults, there is no sense in sending curl commands to
							--nothing or trying to fill the popup. putting this here is a bit lazy, but it means launching the application
							--when it's open to a different tab won't load this for no good reason. Speeds things up a bit. Maybe.
							my loadUserManagerPopup:(missing value) --initial popup load, moved to a function here.
							set my theUMInitialUserLoadDone to true
							--my userSelection's setSelectionIndex:0
						end if
					end if
				else if my theSelectedTabViewItemIndex is "2" then --we won't do anything here until this is actually doing something
					if not theHMInitialUserLoadDone then --the host manager hasn't loaded at least once. this prevents us from continuously sending
						--curl commands every time someone clicks on a tab.
						if my theSMDefaultsExist then --again, if we have no prefs, we have no servers. If we have no servers, we have nothing to get
							--host data for.
							--also we need to set this up ala user manager tab so we don't reload EVERY time someone clicks the tab.
							my loadHostManagerFromPopup:(missing value) --initial load of window.
							set my theHMStatusDisplay to "Because of how dependencies work within Nagios, this app doesn't delete hosts. Barring a way to handle dependencies via the API, it won't."
							set my theHMInitialUserLoadDone to true --load is done, set flag correctly
							--my theHostTableController's setSelectionIndex:0
						end if
					end if
					--log "host"
				end if
			end if
		end if
	end tabView:didSelectTabViewItem:
	
	on tableViewSelectionDidChange:(sender) --this handles up/down arrow movement in the table views. Also handles clicks, but nothing happens specifically for those yet. At some
		--point, we can merge the sent actions for the clicks into here since it all seems to happen here as well as those specific functions and just call them from here.
		
		if sender's object()'s isEqualTo:my theHostTable then --all three try blocks are here to sink the error 1700 that happens if a null selection in a table view
			--is made
			try
				my displayHMHostInfo:(missing value)
				on error errorMessage number errorNumber
				if errorNumber is -1700 then
					--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
					--differently, if needed.
				end if
			end try
			else if sender's object()'s isEqualTo:my userTable then
			try
				my displayUserInfo:(missing value)
				on error errorMessage number errorNumber
				if errorNumber is -1700 then
					--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
					--differently, if needed.
				end if
			end try
			else if sender's object()'s isEqualTo:my theServerTable then
			try
				my getSMServerStatus:(missing value)
				on error errorMessage number errorNumber
				if errorNumber is -1700 then
					--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
					--differently, if needed.
				end if
			end try
		end if
	end tableViewSelectionDidChange:


	--SERVER MANAGER FUNCTIONS
	
	on loadServerTable:sender --push the saved server array theSettingsList into an array controller that runs a table
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
		--array controller
		my theServerTableController's addObjects:my theSMSettingsList --shove the current contents of theSettingsList into the array controller
		set my theSMDefaultsExist to theDefaults's boolForKey:"hasDefaults" --grab current state for this every time this function runs
		if my theSMDefaultsExist then --we want to refresh the user manager popup when we add or delete a server
			my loadUserManagerPopup:(missing value) --refresh the popup data too
		end if
	end loadServerTable:

	on getSMServerStatus:sender
		try
			set theSMServerStatusSearchPattern to "/user" --the pattern we're using for the regex
			set theSMServerStatusReplacementPattern to "/status" --the replacement pattern we're using for the regex

			set theSelectedServer to my theServerTableController's selectedObjects()
			--current application's NSLog("theSelectedServer: %@", theSelectedServer)

			set theSMSelectedURL to theSelectedServer's theSMTableServerURL as text --get the URL for the server that was clicked on in the Server
			--manager table. Note, the conversion to text is necessary, or you get as a single item array or dictionary. Either way, it makes
			--rangeOfFirstMatchInString REALLY UNHAPPY
			set theSMSelectedAPIKey to theSelectedServer's theSMTableServerAPIKey as text --pull the selected server's API key as text
			set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:(theSMServerStatusSearchPattern) options:1 |error|:(missing value)
			--create regex object with the the search pattern as what it's looking for
			set theSMSelectedURLLength to theSMSelectedURL's length --get the length in characters of the selected server's URL
			set theSMMatches to theRegEx's rangeOfFirstMatchInString:(theSMSelectedURL) options:0 range:[0, theSMSelectedURLLength] --get the start
			--of /user and how long it is.
			set theSMStatusURL to theRegEx's stringByReplacingMatchesInString:theSMSelectedURL options:0 range:theSMMatches withTemplate:(theSMServerStatusReplacementPattern)
			--builds the status URL by replacing the /user in the URL with /status
			set theSMServerStatusCommand to "/usr/bin/curl -XGET \"" & theSMStatusURL & theSMSelectedAPIKey & "&pretty=1\"" --build the server
			--status command
			set theSMServerStatusJSON to do shell script theSMServerStatusCommand --run the command to pull the JSON from the server
			set theSMServerStatusJSON to current application's NSString's stringWithString:theSMServerStatusJSON --convert this to NSString
			set theSMServerStatusJSONData to theSMServerStatusJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert
			--NSString to NSData, needed for NSJSONSerialization
			set {theSMSServerStatusJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theSMServerStatusJSONData options:0 |error|:(reference)
			--returns an NSData record of NSArrays, technically an NSJSON object. It looks a LOT like an AS
			--record. You can even reference elements the way you would a record. W00T!!!
			set my theSMStatusFieldText to "active host checks enabled: " & theSMSServerStatusJSONDict's active_host_checks_enabled & "\ractive service checks enabled: " & theSMSServerStatusJSONDict's active_service_checks_enabled & "\rNagios in daemon mode: " & theSMSServerStatusJSONDict's daemon_mode & "\revent handlers enabled: " & theSMSServerStatusJSONDict's event_handlers_enabled & "\rflap detection enabled: " & theSMSServerStatusJSONDict's flap_detection_enabled & "\rlast log rotation: " & theSMSServerStatusJSONDict's last_log_rotation & "\rnotifications enabled: " & theSMSServerStatusJSONDict's notifications_enabled & "\rpassive host checks enabled: " & theSMSServerStatusJSONDict's passive_host_checks_enabled & "\rpassive service checks enabled: " & theSMSServerStatusJSONDict's passive_service_checks_enabled & "\rprocess id: " & theSMSServerStatusJSONDict's process_id
		on error errorMessage number errorNumber
			if errorNumber is -1700 then
				--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
				--differently, if needed.
			else if errorNumber is -128 then
				--user hit cancel on the "you have to have something selected to delete it dialog. So we don't care about that one either.
			end if
		end try
	end getSMServerStatus:
	
	on addServerToPrefs:sender --this was saveSettings:. I know renaming functions will cause problems in the short run, but better names will save pain in the long run
		--also, it avoids name clash with existing stuff until I can get that cleaned up
		
		--check for blank fields, and handle them. This is all the sanity checking I plan on doing for now.
		if (my theSMServerName is missing value) or (my theSMServerName is "") then --did they enter a name for the server?
			set my theSMStatusFieldText to "The Server Name field cannot be blank"
			return
		end if
		
		if (my theSMServerURL is missing value) or (my theSMServerURL is "") then --did they enter a URL for the server?
			set my theSMStatusFieldText to "The Server URL field cannot be blank"
			return
		end if
		
		if (my theSMServerAPIKey is missing value) or (my theSMServerAPIKey is "") then --did they enter an API Key for the server?
			set my theSMStatusFieldText to "The Server API key field cannot be blank"
			return
		end if
		
		set theTempURL to my theSMServerURL as text  --Create a temp text version --I did this all AppleScript style, because it works
		--and I was able to get it done faster this way. It may not execute as fast, but given the data sizes we're talking about,
		--I doubt it's a problem on anything faster than a IIsi
		
		set theLastChar to last character of theTempURL --get the last character of the URL
		
		
		if theLastChar is "/" then --if it's a trailing "/"
			set theTempURL to text 1 thru -2 of theTempURL --trim the last character of the string
			set my theSMServerURL to current application's NSString's stringWithString:theTempURL --rewrite theServerURL. As it turns out,
			--you have to use the current application's NSString's stringWithString for this, NOT theServerURL's stringWithString. Beats me
			--scoping maybe? <shrug>
		end if
		
		set my theSMServerURL to my theSMServerURL's stringByAppendingString:"/nagiosxi/api/v1/system/user?apikey=" --NSSTring append
		--this has the side benefit of showing up in the text box, so the user has a nice visual feedback outside of the table
		--for about .something seconds.
		
		set thePrefsRecord to {theSMTableServerName:my theSMServerName,theSMTableServerURL:my theSMServerURL,theSMTableServerAPIKey:my theSMServerAPIKey} --build the record
		
		my theSMSettingsList's addObject:thePrefsRecord --add the record to the end of the settings list
		
		set my theSMDefaultsExist to true --since we're writing a setting, we want to set this correctly.
		
		theDefaults's setObject:my theSMSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
		theDefaults's setBool:my theSMDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1)
		
		my loadServerTable:(missing value) --reload the server table function call. There's some cleanup that we'd have to dupe if we did it here
		--anyway, so there's no point in not doing this
		
		set my theSMServerURL to "" --if you don't want the text fields to clear, delete/comment out these last three lines
		set my theSMServerName to ""
		set my theSMServerAPIKey to ""
		
	end addServerToPrefs:
	
	on loadServersFromPrefs:sender --this was getSettings:
		my theSMSettingsList's removeAllObjects() -- blank out theSMSettingsList since we're reloading it. The () IS IMPORTANT
		set my theSMSettingsList to (my theDefaults's arrayForKey:"serverSettingsList")'s mutableCopy() --same as in applicationWillFinishLaunching:
		set my theSMDefaultsExist to theDefaults's boolForKey:"hasDefaults" --pull the "do we even have default settings" flag
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of the server table controller
		my theServerTableController's addObjects:my theSMSettingsList --shove the current contents of thePrefsRecord into the array controller
		
	end loadServersFromPrefs:
	
	on deleteServerFromPrefs:sender --this was deleteServer:
		--the ARE YOU SURE YOU WANT TO DO THIS??? warning
		try
			set theSelection to theServerTableController's selectedObjects() as record
			set theServerNameToBeDeleted to theSMTableServerName of theSelection
			
			set theDeleteServerAlertButtonRecord to display alert "You are about to delete " & theServerNameToBeDeleted & " from the saved list of servers. \r\rTHIS IS NOT UNDOABLE, ARE YOU SURE?" as critical buttons {"OK","Cancel"} default button "Cancel" giving up after 90
			set theDeleteServerButton to button returned of theDeleteServerAlertButtonRecord
			
			if theDeleteServerButton is "OK" then --buh-bye
				my theServerTableController's remove:(theServerTableController's selectedObjects()) --deletes the selected row right out of the controller
				--my god, this was so easy once I doped it out
				my theSMSettingsList's removeAllObjects() --blow out theSMSettingsList
				my theSMSettingsList's addObjectsFromArray:(theServerTableController's arrangedObjects()) --rebuild it from theServerTableController
				--this way, at least in here, theServerTableController and theSettingsList are ALWAYS in sync and that's IMPORTANT.
				
				set theServerTableControllerObjectCount to my theServerTableController's arrangedObjects()'s |count|() --get number of objects left in
				--the controller. Vertical bars are necessary because "count" is also an AppleScript keyword, so the bars keep it from being the AS count
				--and instead use it as the ASOC count, which is what we want.
				
				if theServerTableControllerObjectCount = 0 then --if the list is empty (we just deleted the last thing) then we'll call deleteAllServersFromPrefs and
					--save time since that's what deleteAllServersFromPrefs does, if you think about it
					set my theSMSDeletingLastServerFlag to true --this will avoid double dialogs that this particular case can cause
					my deleteAllServersFromPrefs:(missing value) --this handles explicitly clearing the defaults AND hasDefaults for us.
					--technically that may not be necessary, but this way we KNOW.
					
				else --so we have entries in the array, let's write that to disk
					--what's interesting is that we already have theServerTableController and theSettingsList in the desired state, so this gets SIMPLE
					set my theSMDefaultsExist to true --since we're writing a setting, we want to set this correctly.
					
					theDefaults's setObject:my theSMSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
					theDefaults's setBool:my theSMDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1), this way we avoid the
					--"but I thought it was okay" problem. We don't think we know what hasDefaults is on exit, we KNOW
					my loadUserManagerPopup:(missing value) --reload the popup since we deleted a server out from under it. this loads the first object in the server array controller
				end if
			else if theDeleteServerButton is "Cancel" then --nope
				return
			end if
		on error errorMessage number errorNumber
			if errorNumber is -1728 then --nothing selected
				display dialog "You don't have anything selected. You have to select a server to delete it" --error message for -1728
				--if we get enough of these, we'll create a separate function just for them
				current application's NSLog("Nothing Selected Error: %@", errorMessage) --log the error message
			else if errorNumber is -128 then
				--user hit cancel on the "you have to have something selected to delete it dialog. So we don't care about that one either.
			end if
		end try
		
	end deleteServerFromPrefs:
	
	on deleteAllServersFromPrefs:sender --this was clearSettings:
		if not theSMSDeletingLastServerFlag then --you weren't just deleting the last server manually
			set theDeleteAllServersAlertButtonRecord to display alert "You are about to delete EVERY SERVER FROM THIS APP AND ITS SETTINGS. \r\rTHIS IS NOT UNDOABLE, ARE YOU SURE?" as critical buttons {"OK","Cancel"} default button "Cancel" giving up after 90 --ARE YOU SURE YOU WANT TO DO THIS?
			set theDeleteAllServersButton to button returned of theDeleteAllServersAlertButtonRecord --grab button text of the clicked button
			
			if theDeleteAllServersButton is "OK" then --buh-bye
				theDefaults's removeObjectForKey:"serverSettingsList" --blank out defaults plist on disk
				theDefaults's removeObjectForKey:"hasDefaults" --blank out the hasDefaults key, that is now false (0). Well, actually, it's nonexistent
				--but really, that's the same thing for our needs. We can fix this later if we want.
				my theSMSettingsList's removeAllObjects() -- blank out theSettingsList. The () IS IMPORTANT
				my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
				--array controller here, rather than rerunning the loadserver function just to load an empty list
			else if theDeleteAllServersButton is "Cancel" --nope
				return --dump out of the function
			end if
		else --you've just manually deleted the last server, so lets do this without an additional warning that does no good anyway
			theDefaults's removeObjectForKey:"serverSettingsList" --blank out defaults plist on disk
			theDefaults's removeObjectForKey:"hasDefaults" --blank out the hasDefaults key, that is now false (0). Well, actually, it's nonexistent
			--but really, that's the same thing for our needs. We can fix this later if we want.
			my theSMSettingsList's removeAllObjects() -- blank out theSettingsList. The () IS IMPORTANT
			my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
			--array controller here, rather than rerunning the loadserver function just to load an empty list
		end if
		my userSelection's removeObjects:(my userSelection's arrangedObjects()) --since we've deleted all the servers, there's no point in having a list of users in the table. Probably a really bad idea.
		set my theSMSDeletingLastServerFlag to false --reset this so you get the warning if you delete the last server, add one or more servers, then realize you want to delete them all
		
	end deleteAllServersFromPrefs:
	
	
	
	
	--USER MANAGER FUNCTIONS
	
	--load the popup (we'll need this for changes to the server list
	
	on loadUserManagerPopup:sender
		if not theSMDefaultsExist then --if we have no defaults, there's no point in running this code
			return --back to main loop
		end if
		
		set x to my theServerTableController's arrangedObjects()'s firstObject() --get the first object in the array controller
		
		if x is missing value then --if there's nothing in x, stop the function
			return --back to the main loop
		end if
		
		set my theServerName to x's theSMTableServerName --grab the server name
		set my theServerAPIKey to x's theSMTableServerAPIKey --grab the server key
		set my theServerURL to x's theSMTableServerURL --grab the server URL
		
		my getServerUsers:(missing value) --use missing value because we have to pass something. in ths case, the ASOC version of nil

	end loadUserManagerPopup:
	
	on getServerUsers:sender --this isn't attached to a specific button, but we'll leave the sender
		--in case we want to do so at a future date
		set my theServerJSON to do shell script "/usr/bin/curl -XGET \"" & my theServerURL & my theServerAPIKey & "&pretty=1\"" --gets the JSON dump as text
		set my theServerJSON to current application's NSString's stringWithString:my theServerJSON --convert text to NSSTring
		set my theJSONData to my theServerJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
		set {my theJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
		set my theServerUsers to users of my theJSONDict --yank out just the "users" section of the JSON return, that's
		--all we care about
		
		set my theOtherUserInfoList to current application's NSMutableArray's array --init this as an NSMutableArray
		--doing this the long way, will fix to be more "cocoa-y" later
		repeat with x from 1 to count of my theServerUsers --iterate through theServerUsers
			set theItem to item x of theServerUsers as record --convert NSDict to record because it's initially easier
			set the end of my theUserNameList to {theUserName:|name| of theItem,theUserID:user_id of theItem} --build a list of records with the two values we care about
			--also, don't use "my" within the record definition!
			my theOtherUserInfoList's addObject:theItem --shove theItem on the end of the array
			
		end repeat
		my userSelection's removeObjects:(my userSelection's arrangedObjects()) --clear the table
		my userSelection's addObjects:my theUserNameList --fill the table
		set my theUserNameList to {} --clear out theUserNameList so it's got fresh data each time.
		
	end getServerUsers:
	
	on displayUserInfo:sender --this is a VERY inelegant way of displaying basic info on the selected user in the user manager table
		try
			set theTempID to theUserID of my userSelection's selectedObjects() --grab the user id
			set theTempPredicate to current application's NSPredicate's predicateWithFormat:("user_id = \"" & theTempID & "\"") --build a predicate which ends up
			--looking like: user_id == "234" or whatever the user_id is
			set theTempRecord to my theOtherUserInfoList's filteredArrayUsingPredicate:theTempPredicate --get an array with a single NSDictionary containing what we want
			set my theRESTresults to "Full Name: " & theTempRecord's |name| & "\rUsername: " & theTempRecord's username & "\rUser ID: " & theTempRecord's user_id & "\rEmail Address: " & theTempRecord's email & "\rUser Enabled: " & theTempRecord's enabled --display the user info from theTempRecord
		on error errorMessage number errorNumber
			if errorNumber is -1700 then
				--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
				--differently, if needed.
			end if
		end try
	end displayUserInfo:
	
     --function for if the user actually changes the  selection in the popup
     on selectedServerName:sender --the popup's sent action method is bound to this function
		if not theSMDefaultsExist then --so if there are no servers in server manager, even if someone clicks on the list, we don't want things to happen here. This should prevent that
			return
		end if
          set thePopupIndex to sender's indexOfSelectedItem --get the index of the selected item, put it into thePopupIndex
		
		set theResult to my theServerTableController's setSelectionIndex:thePopupIndex --set the current selection in theServerTableController to thePopupIndex. we don't actually care about the result,
		--it's a bool, but if this stops working, we know what to log. This sets the "current selection" of the server array controller to thePopupIndex,
		--so we can pull the right info for the curl commands
		
		set x to my theServerTableController's selectedObjects() as record--grab the selected record
          set my theServerName to x's theSMTableServerName --grab the server name
          set my theServerAPIKey to x's theSMTableServerAPIKey --grab the server key
          set my theServerURL to x's theSMTableServerURL --grab the server url
		
		my getServerUsers:(missing value) --load the user manager user table data
          
     end selectedServerName:
     
	
     
     on deleteSelectedUsers:sender --this activates for either the "delete user" button or a double click in the table
          try
               set theSelection to userSelection's selectedObjects() as record --this gets the selection in the table row
               --and converts the NSArray to an AS record. Is it strictly needed? No, but it's not a big deal either.
               set theUserIDToBeDeleted to |theUserID| of theSelection  --set user id to local var
               set theUserNameToBeDeleted to |theUserName| of theSelection --set user name to local var

			set theDeleteReplacement to "/" & theUserIDToBeDeleted & "\\?" --this sets the replacement string to be "/<the user_id>?"
			--replacing "?"
			set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:(my theDeletePattern) options:1 |error|:(missing value)
			--current application's NSLog("theRegEx: %@", theRegEx)
			set theURLLength to my theServerURL's |length| --get the length of the URL, we need that to get the range for
			--rangeOfFirstMatchInString
			set theMatches to theRegEx's rangeOfFirstMatchInString:(my theServerURL) options:0 range:[0, theURLLength] --this gets the starting
			--point for the match and how long it is. In this case, it's one character, and it starts and ends in the same place.
			set theDeleteURL to theRegEx's stringByReplacingMatchesInString:my theServerURL options:0 range:theMatches withTemplate:(theDeleteReplacement) --replace the characters in range theMatches. This is literally a "replace "?" with "/<user_id>?
			--which is what we need for a delete string. Does it all in one blush, saves a bunch of "build it the hard way code
			set theDeleteUIDCommand to "/usr/bin/curl -XDELETE \"" & theDeleteURL & my theServerAPIKey & "&pretty=1\"" --builds the full
			--command for the do shell script step. Yes, there may be a more cocoa-y way, but I'm pretty sure it's not more efficient in terms
			--of coding, (two lines) and I doubt it runs significantly faster.

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
			
               return
          end try
          
     end deleteSelectedUsers:
     
     on getUserLevel:sender --This is only here to handle the user type radio buttons. but, it works well enough for that.
          set my theUserType to sender's title as text--get user level as text
		
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
		
		--set my theNagiosNewUserName to "" --blank out the add user fields after adding a user
		--set my theNagiosNewUserPassword to ""
		--set my theNagiosNewUserRealName to ""
		--set my theNagiosNewUserEmailAddress to ""
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
	
	
	--HOST MANAGER FUNCTIONS
	
	on getHostList:sender --pull down the initial list of hosts
		set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:(theHMHostSearchPattern) options:1 |error|:(missing value) --create the RegEx object
		
		set theHMServerURL to current application's NSString's stringWithString:my theHMServerURL --for whatever reason, this function required this so that we could get the length
		--beats the heck outta me
		set theURLLength to my theHMServerURL's |length|() --get the length of the URL, we need that to get the range for
		--rangeOfFirstMatchInString
		set theMatches to theRegEx's rangeOfFirstMatchInString:(my theHMServerURL) options:0 range:[0, theURLLength] --this gets the starting
		--point for the match and how long it is. In this case, it's one character, and it starts and ends in the same place.
		set theHMHostStatusURL to theRegEx's stringByReplacingMatchesInString:my theHMServerURL options:0 range:theMatches withTemplate:(my theHMHostReplacementPattern) --replace the characters in range theMatches. This is literally a "replace "system/user" with "objects/host" operation" which is what we need for a url to get a list of hosts.
		set theHMGetHostListCommand to "/usr/bin/curl -XGET \"" & theHMHostStatusURL & my theHMServerAPIKey & "&pretty=1\"" --build the curl command to get the hosts
		set my theHMHostListJSON to do shell script theHMGetHostListCommand --get the initial JSON dump from nagios
		set my theHMHostListJSON to current application's NSString's stringWithString:my theHMHostListJSON --convert this to NSString
		set my theHMHostListJSONData to my theHMHostListJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
		set {my theHMHostListJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theHMHostListJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
		set my theHMHostCount to recordcount of my theHMHostListJSONDict's hostlist --get the host count for that server. May use it some day
		set my theHMHostListRecord to |host| of my theHMHostListJSONDict's hostlist --we have to pull it from hostlist of the Dict because it buries everything in hostlist.
		--note that if we want to pull the numerical ID of the host, that's buried in attributes of a given host. So that'll suck.
		--attributes we initially want: host_name,address,display_name,alias,is_active,active_checks_enabled,passive_checks_enabled,notifications_enabled,notification_interval,
			--first_notification_delay,check_interval,retry_interval,max_checks_attempt
		my theHostTableController's removeObjects:(my theHostTableController's arrangedObjects()) --clear out the host array controller
		my theHostTableController's addObjects:my theHMHostListRecord
		
		--set theTest to my theHostTableController's arrangedObjects()'s firstObject()
	end getHostList:
	
	on loadHostManagerFromPopup:sender --runs when the host manager tab is clicked. we may flag this so it only runs once, but it's all local data, so it's pretty fast
		--and, if something changes in the server manager, we want this running anyway.
		if not theSMDefaultsExist then --if we have no defaults, there's no point in running this code
			return --back to main loop
		end if
		set x to my theServerTableController's arrangedObjects()'s firstObject() --get the first object in the array controller. the way this runs, this is the initial load of things. So we want it to be the first thing in the list. When someone manually changes that, it would handled in selectedHMServerName
		if x is missing value then --if there's nothing in x, stop the function
			return --back to the main loop
		end if
		
		set my theHMServerName to x's theSMTableServerName --grab the server name
		set my theHMServerAPIKey to x's theSMTableServerAPIKey --grab the server key
		set my theHMServerURL to x's theSMTableServerURL --grab the server URL
		my getHostList:(missing value)
		
	end loadHostManagerFromPopup:
	
	on selectedHMServerName:sender -- This runs when you select a server in the popup list. we could just share everything with the user manager server, but, letting host functionality not determine what's in the user manager ultimately makes things more flexible.
		if not theSMDefaultsExist then --so if there are no servers in server manager, even if someone clicks on the list, we don't want things to happen here. This should prevent that
			return
		end if
		set thePopupIndex to sender's indexOfSelectedItem --get the index of the selected item, put it into thePopupIndex
		set theResult to my theServerTableController's setSelectionIndex:thePopupIndex --set the current selection in theServerTableController to thePopupIndex. we don't actually care about the result,
		--it's a bool, but if this stops working, we know what to log. This sets the "current selection" of the server array controller to thePopupIndex,
		--so we can pull the right info for the curl commands
		set x to my theServerTableController's selectedObjects() as record--grab the selected record
		set my theHMServerName to x's theSMTableServerName --grab the server name
		set my theHMServerAPIKey to x's theSMTableServerAPIKey --grab the server key
		set my theHMServerURL to x's theSMTableServerURL --grab the server api
		my getHostList:(missing value)
		
	end selectedHMServerName:
	
	on displayHMHostInfo:sender
		try
			set theTempHostName to host_name of my theHostTableController's selectedObjects() as text
			
			set theTempHMPredicate to current application's NSPredicate's predicateWithFormat:("host_name = \"" & theTempHostName & "\"") --build a predicate which ends up
			set theTempHMArray to current application's NSArray's arrayWithArray:(my theHostTableController's arrangedObjects())
			--looking like: host_name == "foo server" or whatever the host_name is
			
			set theTempRecord to theTempHMArray's filteredArrayUsingPredicate:theTempHMPredicate --get an array with a single NSDictionary containing what we want
			
			set my theHMStatusDisplay to "Basic Host Info:\rDisplay Name: " & theTempRecord's display_name & "\tAlias: " & theTempRecord's |alias| & "\rActive Checks Enabled: " & theTempRecord's active_checks_enabled & "\t\tPassive Checks Enabled: " & theTempRecord's passive_checks_enabled & "\t\tNotifications Enabled: " & theTempRecord's notifications_enabled & "\rCheck Interval: " & theTempRecord's check_interval & "\t\t\t\tRetry Interval: " & theTempRecord's retry_interval & "\t\t\t\t\t\t\t\t\tMax Check Attempts: " & theTempRecord's max_check_attempts & "\rNotification Interval: " & theTempRecord's notification_interval & "\t\t\tFirst Notification Delay: " & theTempRecord's first_notification_delay --set the status display to show basic host info
		on error errorMessage number errorNumber
			if errorNumber is -1700 then
				--we do nothing here, but we want to note the specific error we're trying to sink. Other errors, we want to know about so we can handle them
				--differently, if needed.
			end if
		end try
	end displayHMHostInfo:
	
	on getHMHostStatus:sender
		set theHostStatusName to host_name of my theHostTableController's selectedObjects()
		set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:(theHMHostSearchPattern) options:1 |error|:(missing value) --create the RegEx object
		set theHMServerURL to current application's NSString's stringWithString:my theHMServerURL --for whatever reason, this function required this so that we could get the length
		--beats the heck outta me
		set theURLLength to my theHMServerURL's |length|() --get the length of the URL, we need that to get the range for
		--rangeOfFirstMatchInString
		set theMatches to theRegEx's rangeOfFirstMatchInString:(my theHMServerURL) options:0 range:[0, theURLLength] --this gets the starting
		--point for the match and how long it is. In this case, it's one character, and it starts and ends in the same place.
		set theHMHostStatusURL to theRegEx's stringByReplacingMatchesInString:my theHMServerURL options:0 range:theMatches withTemplate:(my theHMHostStatusReplacementPattern)
			--replace the characters in range theMatches. This is literally a "replace "system/user" with "objects/hoststatus" operation" which is what we need for a url to get a
			--list of hosts.
		set theHMGetHostStatusCommand to "/usr/bin/curl -XGET \"" & theHMHostStatusURL & my theHMServerAPIKey & "&host_name=" & theHostStatusName & "&pretty=1\""
			--build the curl command to get the host status for the specified host
		set theHMGetHostStatusJSON to do shell script theHMGetHostStatusCommand --get the initial JSON dump from nagios
		set theHMGetHostStatusJSON to current application's NSString's stringWithString:theHMGetHostStatusJSON --convert this to NSString
		set theHMGetHostStatusJSONData to theHMGetHostStatusJSON's dataUsingEncoding:(current application's NSUTF8StringEncoding) --convert NSString to NSData
		set {theHMGetHostStatusJSONDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:theHMGetHostStatusJSONData options:0 |error|:(reference) --returns an NSData record of NSArrays
		set theHMHostStatusRecord to hoststatus of theHMGetHostStatusJSONDict's hoststatuslist --we have to pull it from hostlist of the Dict because it buries everything in
		--hoststatuslist.
		
		--fill in the fields in the HUD
		set my theHMHostID to host_id of theHMHostStatusRecord
		set my theHMHostLastStatus to status_text of theHMHostStatusRecord
		set my theHMHostLastStatusUpdateTime to status_update_time of theHMHostStatusRecord
		set my theHMHostLastTimeDown to last_time_down of theHMHostStatusRecord
		set my theHMHostLastTimeUnreachable to last_time_unreachable of theHMHostStatusRecord
		set my theHMHostLastCheck to last_check of theHMHostStatusRecord
		set my theHMHostNextCheck to next_check of theHMHostStatusRecord
		set my theHMHostFlapDetectionEnabled to flap_detection_enabled of theHMHostStatusRecord
		set my theHMHostIsFLapping to is_flapping of theHMHostStatusRecord
		set my theHMHostProblemAcknowledged to problem_acknowledged of theHMHostStatusRecord
		my theHostStatusHUD's makeKeyAndOrderFront:(me)
	end getHMHostStatus:

	on addHMHost:sender --add a host to the selected nagios instance
		--sanity checking for blanks.
		if (my theHMNewHostName is missing value) or (my theHMNewHostName is "") then --did they enter a name for the host?
			set my theHMStatusDisplay to "The Host Name field cannot be blank"
			return
		end if

		if (my theHMNewHostAddress is missing value) or (my theHMNewHostAddress is "") then --did they enter a name for the host?
			set my theHMStatusDisplay to "The Address field cannot be blank"
			return
		end if

		if (my theHMNewHostCheckInterval is missing value) or (my theHMNewHostCheckInterval is "") then --did they enter a name for the host?
			set my theHMStatusDisplay to "The Check Interval field cannot be blank"
			return
		end if

		if (my theHMNewHostRetryInterval is missing value) or (my theHMNewHostRetryInterval is "") then --did they enter a name for the host?
			set my theHMStatusDisplay to "The Retry Interval field cannot be blank"
			return
		end if

		if (my theHMNewHostMaxCheckAttempts is missing value) or (my theHMNewHostMaxCheckAttempts is "") then --did they enter a name for the host?
			set my theHMStatusDisplay to "The Max Checks Attempt field cannot be blank"
			return
		end if

		--so there are cases where you don't want to have the notifications enabled or even filled in. I have defaults, but "blank" is actually perfectly acceptable
		--for notifications
		
		set theHostStatusName to host_name of my theHostTableController's selectedObjects() --we're abusing "host" here. In this case, we mean the nagios server name.
		set theRegEx to current application's NSRegularExpression's regularExpressionWithPattern:(theHMHostSearchPattern) options:1 |error|:(missing value) --create the RegEx object
		set theHMServerURL to current application's NSString's stringWithString:my theHMServerURL --for whatever reason, this function required this so that we could get the length
		--beats the heck outta me
		set theURLLength to my theHMServerURL's |length|() --get the length of the URL, we need that to get the range for
		--rangeOfFirstMatchInString
		set theMatches to theRegEx's rangeOfFirstMatchInString:(my theHMServerURL) options:0 range:[0, theURLLength] --this gets the starting
		--point for the match and how long it is. In this case, it's one character, and it starts and ends in the same place.
		set theHMHostStatusURL to theRegEx's stringByReplacingMatchesInString:my theHMServerURL options:0 range:theMatches withTemplate:(my theHMNewHostReplacementPattern)
		--replace the characters in range theMatches. This is literally a "replace "system/user" with "objects/hoststatus" operation" which is what we need for a url to get a
		--list of hosts.
		log theHMHostStatusURL

		

	end addHMHost:

     (*on clearTable:sender --test function to see why we aren't clearing table data correctly.
          userSelection's removeObjects:(userSelection's arrangedObjects()) --clear the table
          set my theUserNameList to {} --not doing this was causing our problems
     end clearTable:*)
	
     on applicationShouldTerminateAfterLastWindowClosed:sender
          return true
     end applicationShouldTerminateAfterLastWindowClosed:
	
end script
