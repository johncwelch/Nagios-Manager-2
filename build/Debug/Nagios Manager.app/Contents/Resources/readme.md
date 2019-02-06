Okay, so maybe this can be a permanent readme. Basically, this is a front end to the Nagios REST API

1.3
currently, it can manage its own list of servers and users. To answer a question, no, it can't get user settings, the API doesn't allow for that. I can add users and delete users. (well, you CAN get user status, but all you get is name, user name, user ID, enabled state and email address. I may add that in, I may not, it's not that important.)

What I want to do in 1.4: 
add in host management. DONE

1.5 will be code cleanup to remove redundant code and move some things into popuplists as they should be. DONE

1.6 will be adding hostgroups and services. Not sure of the order. May play with NSURL a bit to see if there's an advantage to using that over do shell script curl blah blah. Then again, I may not.

1.7 hostgroups. services will be a pita beyond adding. 1.6 didn't get services thanks to some serious assholery on Nagios' part (UNDOCUMENTED CHANGES TO JSON RETURNS ARE NOT OKAY Y'ALL)

1.8 is going to be documentation and then I'll look at services. it may be limited to adding them because of how Nagios lists them in the REST API. 

Okay, so here's the final 1.8 build complete with a help file and voiceover working at least basically.

IMPORTANT!!!!!

1.8 is the FINAL version that will support Nagios XI pre-5.5.X. There are MAJOR improvements to the REST API that make supporting both pre- and post- 5.5 really hard. So this one will remain up for anyone needing pre-5.5.x support. The next update will be the 2.X branch wherein I can start adding in the 5.5. changes. Like AD/LDAP support! So cool.

2.0: getting Nagios Manager to work with AD/LDAP auth servers is the big new feature. Also redoing some of the code, there's no need for that much grepping, ye gods. Once that's done, then 2.X will add, slowly, new features in the API in the post 5.5.X world. I created a new repository so the pre-2.X code that will work on pre-5.5.X nagios still exists. NM2 will be the first one I push into the Mac App Store. Or, at least try to.


yes, it's written in AppleScriptObjective C. No, I don't particularly care if you like that language, it does what *I* need it to do and that's its only
requirement.

Too many thanks to Mark Aldritt, Sal Soghoian, Andy Bachorski (RIP), Chris Nebel, Chris Espinosa (other chris) Chris Page (other, other chris), Todd Fernandez, Shane Stanely, and a host of people at Apple and other companies who realize what gems AppleScript and AppleScript Objective C are.


