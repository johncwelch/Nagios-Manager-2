//
//  main.m
//  Nagios Manager
//
//  Created by John Welch on 5/18/18.
//  Copyright © 2018 John Welch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, const char * argv[]) {
     [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
     return NSApplicationMain(argc, argv);
}
