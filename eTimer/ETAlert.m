//
//  ETAlert.m
//  eTimer
//
//  Created by Eric Huss on 6/8/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// Working around bug with Swift and UIAlertView...
void
ETShowAlert(NSString *title, NSString *message, id delegate, NSString *buttonTitle) {
    UIAlertView *view = [[UIAlertView alloc]
     initWithTitle:title
     message:message
     delegate:delegate
     cancelButtonTitle:buttonTitle otherButtonTitles:nil];
    [view show];
}

// Private APIs.  Amazing Apple does not provide this.
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID,id arg,NSDictionary* vibratePattern);
void AudioServicesStopSystemSound(SystemSoundID inSystemSoundID);

void
ETVibrateStart(int duration)
{
    NSMutableArray* arr = [NSMutableArray array];

    // I don't really know how to make it repeat automatically.
    for (int i=0; i<duration/2; i++) {
        [arr addObject:@YES];
        [arr addObject:@1000];

        [arr addObject:@NO];
        [arr addObject:@1000];
    }

    NSDictionary *dict = @{
                           @"Intensity": @1,
                           @"VibePattern": arr
                           };
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate,nil,dict);

    // This style of input plays continuously (even when the app exits!!!).
//    NSDictionary *dict2 = @{@"Intensity": @1,
//                            @"OffDuration": @1,
//                            @"OnDuration": @10
//            };
//    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate,nil,dict2);
}

void ETVibrateStop()
{
    AudioServicesStopSystemSound(kSystemSoundID_Vibrate);
}

