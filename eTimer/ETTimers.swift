//
//  ETTimers.swift
//  eTimer
//
//  Created by Eric Huss on 6/7/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import Foundation

class ETTimers: NSObject, NSCoding {

    class var timerPath: String {
        get {
            let docs = NSSearchPathForDirectoriesInDomains(
                NSSearchPathDirectory.DocumentDirectory,
                NSSearchPathDomainMask.UserDomainMask, true)
            let doc = docs[0] as String
            return doc.stringByAppendingPathComponent("timers.plist")
        }
    }

    var timers: ETTimer[]
    // The current timer being displayed.
    var currentTimerIndex: Int = 0
    var currentTimer: ETTimer {
        get {
            return timers[currentTimerIndex]
        }
    }

    init() {
        timers = []
    }

    func reset() {
        timers = [
            ETTimer(name: "Timer 1", duration: /*3*60*/5, themeId: "skyBlue", alarmId: "bliss", index:0),
            ETTimer(name: "Timer 2", duration: 10*60, themeId: "red", alarmId: "bliss", index:1),
            ETTimer(name: "Timer 3", duration: 60*60, themeId: "grey", alarmId: "bliss", index:2),
        ]
        currentTimerIndex = 0
    }

    // Reload timers after app launch.
    func resumeSuspendedTimers() {
        for timer in timers {
            timer.resumeSuspendedTimer()
        }
    }

    // MARK: NSCoding
    init(coder aDecoder: NSCoder!) {
        timers = aDecoder.decodeObjectForKey("timers") as Array<ETTimer>
        currentTimerIndex = aDecoder.decodeObjectForKey("currentTimerIndex") as Int
    }

    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(timers as AnyObject, forKey: "timers")
        aCoder.encodeObject(currentTimerIndex as AnyObject, forKey: "currentTimerIndex")
    }

    func save() {
        NSKeyedArchiver.archiveRootObject(self, toFile: ETTimers.timerPath)
    }

    class func loadTimers() {
        if NSFileManager.defaultManager().fileExistsAtPath(ETTimers.timerPath) {
            sharedTimers = NSKeyedUnarchiver.unarchiveObjectWithFile(ETTimers.timerPath) as ETTimers
        } else {
            sharedTimers = ETTimers()
            sharedTimers.reset()
        }
    }
}

// Unfortunately class variables were not implemented when I wrote this.
var sharedTimers: ETTimers!

// Convenience function.
func ETGetCurrentTheme() -> ETTheme {
    return sharedTimers.currentTimer.theme
}
