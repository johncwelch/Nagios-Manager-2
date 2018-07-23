Okay, so maybe this can be a permanent readme. Basically, this is a front end to the Nagios REST API

1.3
currently, it can manage its own list of servers and users. To answer a question, no, it can't get user settings, the API doesn't allow for that. I can add users and delete users. (well, you CAN get user status, but all you get is name, user name, user ID, enabled state and email address. I may add that in, I may not, it's not that important.)

What I want to do in 1.4: 
add in host management. DONE

1.5 will be code cleanup to remove redundant code and move some things into popuplists as they should be. DONE

1.6 will be adding hostgroups and services. Not sure of the order. May play with NSURL a bit to see if there's an advantage to using that over do shell script curl blah blah. Then again, I may not.

1.7 will be adding services. Hostgroups will be a pita. 1.6 didn't get services thanks to some serious assholery on Nagios' part (UNDOCUMENTED CHANGES TO JSON RETURNS ARE NOT OKAY Y'ALL)


yes, it's written in AppleScriptObjective C. No, I don't particularly care if you like that language, it does what *I* need it to do and that's its only
requirement.

Too many thanks to Mark Aldritt, Sal Soghoian, Andy Bachorski (RIP), Chris Nebel, Chris Espinosa (other chris) Chris Page (other, other chris), Todd Fernandez, Shane Stanely, and a host of people at Apple and other companies who realize what gems AppleScript and AppleScript Objective C are.
