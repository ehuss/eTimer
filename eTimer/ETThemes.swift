//
//  ETThemes.swift
//  eTimer
//
//  Created by Eric Huss on 6/6/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import UIKit

// Convert a string to a UIColor.
//
// Strings may be 3 or 4 numbers separated by ", " like:
//      "255, 255, 255, 1.0"
// for red, green, blue, and an optional alpha.
// Numbers may be ints in range [0,255] or floats with a dot in range [0,1].
//
// The string may also be a hex RGB value, like "#33FF66".  The initial hash
// mark is optional.
//
// If colorInfo is nil, will return the given defaultColor.
func colorFrom(colorInfo: String!, #defaultColor: UIColor) -> UIColor {

    if (colorInfo != nil) {
        let components = colorInfo.componentsSeparatedByString(", ")
        switch components.count {
        case 0:
            assert(false)

        case 1:
            // Hex color string.  # prefix is optional.
            let colorStr = components[0]
            var si: Int = 0
            if colorStr.hasPrefix("#") {
                si = 1
            }
            let red = CGFloat(colorStr.ET_substring(si, end: si+2).ET_asInt(base: 16)) / 255.0
            let green = CGFloat(colorStr.ET_substring(si+2, end: si+4).ET_asInt(base: 16)) / 255.0
            let blue = CGFloat(colorStr.ET_substring(si+4, end: si+6).ET_asInt(base: 16)) / 255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)

        case 3, 4:
            // 3 rgb values in range [0,255] or [0,1] with optional alpha.
            var parts = components.map { (part: String) -> CGFloat in
                if part.rangeOfString(".") != nil {
                    return CGFloat(part.ET_asInt(base: 16)) / 255.0
                } else {
                    return CGFloat(part.ET_asFloat())
                }
            }
            if parts.count == 3 {
                parts.append(1.0)
            }
            return UIColor(red: parts[0], green: parts[1], blue: parts[2], alpha: parts[3])

        default:
            println("Unexpected color \(colorInfo)")
            abort()
        }
    }
    return defaultColor
}

class ETTheme {
    let name: String
    let id: String
    let backgroundFullColor: UIColor
    let backgroundEmptyColor: UIColor
    let softColor: UIColor
    let hardColor: UIColor
    let greenColor: UIColor
    let redColor: UIColor
    // This is for convenience, it is the index into themes.  This is not
    // saved to disk, it may change between versions.
    let themeIndex: Int

    init(data: Dictionary<String, AnyObject>, index: Int) {
        themeIndex = index
        name = data["name"]! as String
        id = data["id"]! as String
        // I cannot find a way to get Swift to convert the AnyObject? to
        // String? directly in assignment.
        // According to: https://devforums.apple.com/thread/239557?tstart=0
        // this is a bug.
        var c: AnyObject? = data["backgroundFullColor"];
        backgroundFullColor = colorFrom(c as? String, defaultColor: UIColor.whiteColor())
        c = data["backgroundEmptyColor"]
        backgroundEmptyColor = colorFrom(c as? String, defaultColor: UIColor.whiteColor())
        c = data["softColor"]
        softColor = colorFrom(c as? String, defaultColor: UIColor(white: 0.2, alpha: 1.0))
        c = data["hardColor"]
        hardColor = colorFrom(c as? String, defaultColor: UIColor.blackColor())
        c = data["greenColor"]
        greenColor = colorFrom(c as? String, defaultColor: UIColor(
            red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0))
        c = data["redColor"]
        redColor = colorFrom(c as? String, defaultColor: UIColor(
            red: 235.0/255.0, green: 68.0/255.0, blue: 56.0/255.0, alpha: 1.0))
    }
}

class ETThemes {

    var themes: [ETTheme]!
    var themeMap: Dictionary<String, ETTheme>!

    func load() {
        // I'm not certain why Swift won't allow me to set themes to an empty,
        // array (it makes it immuatable).  Something about it being an implicit
        // optional.
        var a: [ETTheme] = []
        var tmap: Dictionary<String, ETTheme> = [:]
        let themesPath = NSBundle.mainBundle().pathForResource("Themes", ofType: "plist")
        let themesData = NSDictionary(contentsOfFile: themesPath!) as Dictionary<NSObject, AnyObject>
        let rawThemes = themesData["Themes"] as NSArray
        for themeDict: AnyObject in rawThemes {
            // Unfortunately can't seem to cast directly to this in iterator.
            var theme = ETTheme(data: themeDict as Dictionary, index: a.count)
            a.append(theme)
            tmap[theme.id] = theme
        }
        themes = a
        themeMap = tmap
    }

    func themeById(tid: String) -> ETTheme? {
        return themeMap[tid]
    }
}


// Unfortunately class variables were not implemented when I wrote this.
var sharedThemes: ETThemes = ETThemes()
