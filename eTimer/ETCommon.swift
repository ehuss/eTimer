//
//  ETCommon.swift
//  eTimer
//
//  Created by Eric Huss on 6/6/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import Foundation
import CoreGraphics

let kTimerCount: Int = 3

enum ETColorTypes: String {
    case Green = "Green"
    case Red = "Red"
}


extension String {
    // I don't know why String doesn't have anything like this.
    // Alternatively, could cast to NSString and use substringWithRange.
    func ET_substring(start: Int, end: Int) -> String {
        let si = advance(self.startIndex, start)
        let ei = advance(self.startIndex, end)
        return substringWithRange(Range(start: si, end: ei))
    }

    func ET_asInt(base: Int = 10) -> Int {
        switch base {
        case 10:
            var i: Int = 0
            NSScanner(string: self).scanInteger(&i)
            return i
        case 16:
            var i: CUnsignedInt = 0
            NSScanner(string: self).scanHexInt(&i)
            return Int(i)
        default:
            println("Unsupported base: \(base)")
            abort()
        }
    }

    func ET_asFloat() -> Float {
        var f: Float = 0
        NSScanner(string: self).scanFloat(&f)
        return f
    }

    func ET_asCGFlat() -> CGFloat {
        var f: Float = 0
        NSScanner(string: self).scanFloat(&f)
        return CGFloat(f)
    }
}
