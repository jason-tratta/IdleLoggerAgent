//
//  AppDelegate.m
//  IdleLoggerAgent
//
//  Created by Tratta, Jason A on 5/18/15.
//  Copyright (c) 2015 Jason Tratta. All rights reserved.
//
//  The MIT License (MIT)
//
//Copyright (c) 2015 Jason Tratta
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//

#import "AppDelegate.h"
#include <IOKit/IOKitLib.h>
#include <CoreServices/CoreServices.h>
#include <stdio.h>



extern OSStatus MDSendAppleEventToSystemProcess(AEEventID eventToSend);

@implementation AppDelegate
@synthesize timerTime, countUpTime;
@synthesize retyLogout;
@synthesize firstLaunch;
@synthesize loggedInUser;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
   // NSLog(@"START");
    [self setFirstLaunch:YES];
    [self start];
    countUpTime = [NSNumber numberWithInt:0];
   
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event){
        
     // NSLog(@"Reset Count Up");
        [self resetCountUp];
        
    }];
    
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDown handler:^(NSEvent *event){
        
      // NSLog(@"Key DOWN Up");
        [self resetCountUp];
        
    
        
    }];
     
    
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(userSwitched) name:NSWorkspaceSessionDidBecomeActiveNotification object:nil];

    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(userSwitched) name:NSWorkspaceSessionDidResignActiveNotification object:nil];

    [[NSProcessInfo processInfo] disableAutomaticTermination:@"Good Reason"];
    
   loggedInUser = NSUserName();
    

    
}


-(void)userSwitched {
    
    //Fast User Switching was initiated.  Logout in 5 mins.
    
    timerTime = [NSNumber numberWithUnsignedInteger:300];
    countUpTime = [NSNumber numberWithInt:0];
    
    NSLog(@"User Switched. Resetting logout time to 5 mins.");
    
}



- ( void )printIdleTime: ( NSTimer * )timer
{
    
    [self incrementTimer];
 // NSLog( @"Idle time in seconds: %lu / %lu", [countUpTime integerValue],[timerTime integerValue]);
    
    
    if ([countUpTime integerValue]  == 60) {
        NSLog(@"Idle 1 Minute: %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);
    }
    
    if ([countUpTime integerValue]  == 120) {
        NSLog(@"Idle 2 Minutes %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);
    }
    
    if ([countUpTime integerValue]  == 240) {
        NSLog(@"Idle 4 Minutes %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);
    }
    
    if ([countUpTime integerValue]  == 1800) {
        NSLog(@"Idle 30 Minutes %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);    }

    if ([countUpTime integerValue]  == 3600) {
        NSLog(@"Idle 1 Hour %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);
    }
    
    if ([countUpTime integerValue]  == 5400) {
        NSLog(@"Idle 90 Minutes %@ Remaining out of %@", countUpTime.stringValue, timerTime.stringValue);
    }


  
    
    if ([countUpTime integerValue] > [timerTime integerValue]) {
        [self forceLogout];
        
    }
    
    
    
    
}

-(void)incrementTimer
{
    
    NSNumber *increment = countUpTime;
    countUpTime = [NSNumber numberWithInt:[increment intValue] + 1];
    
    
}

-(void)resetCountUp
{
    
    countUpTime = [NSNumber numberWithInt:0];
    timerTime = [NSNumber numberWithUnsignedInteger:7200];

}



-(void)start
{
    if (firstLaunch) {
        timerTime = [NSNumber numberWithUnsignedInteger:7200];
        retyLogout = YES;
        firstLaunch = NO;
    }
    
    NSLog(@"v.2015_v3 Log out time set to:%@ seconds.",[timerTime stringValue]);
    
  //  _idle  = [ [ IdleTime alloc ] init ];
    
    _timer = [ NSTimer
              scheduledTimerWithTimeInterval: 1
              target:                         self
              selector:                       @selector( printIdleTime: )
              userInfo:                       NULL
              repeats:                        YES
              ];
    
    
    
    
}




-(void)forceLogout
{
    
    
    
    // Get a list of currently running applications in our session
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    
    //Check to user name.  If we return "root" this means the computer is currently logged out.
    //We want to skip the termination process then, as to not kill anything important like ARD.
    
    NSString *user = [NSString stringWithFormat:@"%@",NSUserName()];
    
    if (![user isEqualToString:@"root"]) {
        
        
        
        for (NSRunningApplication *app in runningApps) {
            
            
            
            
            // Exclude this app and others to avoid bad times later.
            if (![[app localizedName] isEqualToString:@"Finder"]
                && ![[app localizedName] isEqualToString:[[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleName"]]
                && ![[app localizedName] isEqualToString:@"jamfAgent"]                  // Casper Agent
                && ![[app localizedName] isEqualToString:@"loginwindow"]                // Login Window
                && ![[app localizedName] isEqualToString:@"ARDAgent"]                   // Do Not Kill Apple Remote Desktop
                && ![[app localizedName] isEqualToString:@"SecurityAgent"]              // For Microsoft AntiVirus
                && ![[app localizedName] isEqualToString:@"Dock"]                       // No need to kill the Dock
                && ![[app localizedName] isEqualToString:@"SystemUIServer"]
                && [app localizedName] != NULL
                && ![[app localizedName] isEqualToString:@"KeyAccess"]                  //Keychain Access
                && ![[app localizedName] isEqualToString:@"Notification Center"]
                && ![[app localizedName] isEqualToString:@"kass"]) {                    //Keychain Access
                
               
                NSLog(@"Terminating:%@", [app localizedName]);
                
                [app forceTerminate]; // Terminates the app without giving it a chance to confirm with the user
                
                if (![app isTerminated]) {
                    // NSLog(@"Terminating Again:%@", [app localizedName]);
                    [self tryFiveTimes:app];
                }
                
                
                
            }
            
            [self logout];
            //[self resetCountUp];
        }
        
        
    }
    // Send Apple Event to log out
    
    
    
    if ([user isEqualToString:@"root"]) {
        
        NSLog(@"No user logged in, skipping session termination.");
    }
    
    
    
}


-(void)logout
{
    NSLog(@"Attempting Forced Logout");
    MDSendAppleEventToSystemProcess(kAEReallyLogOut);
    //MDSendAppleEventToSystemProcess(kAELogOut);
}


-(void)tryFiveTimes:(NSRunningApplication *)app
{
    int i;
    
    
    
    for (i = 0; i < 6; i++) {
        
        if (![app isTerminated]) {
            [app terminate]; }
        
        
        if (i == 5 && ![app isTerminated]) {
            
            NSString *killcommandString = [NSString stringWithFormat:@"kill -9 %d", [app processIdentifier]];
            //NSLog(@"%@ /%@",killcommandString, [app localizedName]);
            
            NSTask *task = [[NSTask alloc]init];
            [task setLaunchPath:@"/bin/bash"];
            NSArray *arguments = [NSArray arrayWithObjects:@"-c", killcommandString, nil];
            [task setArguments:arguments];
            [task launch];
            
        }
        
    }
    
    [self logout];
    
}




OSStatus MDSendAppleEventToSystemProcess(AEEventID eventToSendID) {
    AEAddressDesc targetDesc;
    static const ProcessSerialNumber kPSNOfSystemProcess = {0, kSystemProcess };
    AppleEvent eventReply = {typeNull, NULL};
    AppleEvent eventToSend = {typeNull, NULL};
    
    OSStatus status = AECreateDesc(typeProcessSerialNumber,
                                   &kPSNOfSystemProcess, sizeof(kPSNOfSystemProcess), &targetDesc);
    
    if (status != noErr) return status;
    
    status = AECreateAppleEvent(kCoreEventClass, eventToSendID,
                                &targetDesc, kAutoGenerateReturnID, kAnyTransactionID, &eventToSend);
    
    AEDisposeDesc(&targetDesc);
    
    if (status != noErr) return status;
    
    status = AESendMessage(&eventToSend, &eventReply,
                           kAENormalPriority, kAEDefaultTimeout);
    
    AEDisposeDesc(&eventToSend);
    if (status != noErr) return status;
    AEDisposeDesc(&eventReply);
    return status;
}

- ( void )dealloc
{
    [ _timer invalidate ];
    
}


@end
