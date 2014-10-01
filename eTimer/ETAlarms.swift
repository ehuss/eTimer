//
//  ETAlarms.swift
//  eTimer
//
//  Created by Eric Huss on 6/9/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import Foundation

class ETAlarm {
    let name: String
    let id: String
    let path: String
    // This is for convenience, it is the index into alarms.  This is not
    // saved to disk, it may change between versions.
    let alarmIndex: Int

    init(data: Dictionary<String, AnyObject>, index: Int) {
        alarmIndex = index
        name = data["name"]! as String
        id = data["id"]! as String
        path = data["path"]! as String
    }

}

class ETAlarms {
    var alarms: [ETAlarm]!
    var alarmMap: Dictionary<String, ETAlarm>!

    func load() {
        // I'm not certain why Swift won't allow me to set themes to an empty,
        // array (it makes it immuatable).  Something about it being an implicit
        // optional.
        var a: [ETAlarm] = []
        var amap: Dictionary<String, ETAlarm> = [:]
        let alarmsPath = NSBundle.mainBundle().pathForResource("Alarms", ofType: "plist")
        let alarmsData = NSDictionary(contentsOfFile: alarmsPath!) as Dictionary<NSObject, AnyObject>
        let rawAlarms = alarmsData["Alarms"] as NSArray
        for alarmDict: AnyObject in rawAlarms {
            // Unfortunately can't seem to cast directly to this in iterator.
            var alarm = ETAlarm(data: alarmDict as Dictionary, index: a.count)
            a.append(alarm)
            amap[alarm.id] = alarm
        }
        alarms = a
        alarmMap = amap
    }

    func alarmById(tid: String) -> ETAlarm? {
        return alarmMap[tid]
    }

}

// Unfortunately class variables were not implemented when I wrote this.
var sharedAlarms: ETAlarms = ETAlarms()
