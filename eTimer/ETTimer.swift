//
//  ETTimer.swift
//  eTimer
//
//  Created by Eric Huss on 6/7/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import UIKit
import QuartzCore
import AudioToolbox
import AVFoundation

let kETNotificationTimerEnd = "ETNotificationTimerEnd"
let kETNotificationActiveTimerTick = "kETNotificationActiveTimerTick"

// Settings for the Timer Name label at the top of the screen.
let kETTimerNameFontName = "HelveticaNeue"
let kETTimerNameFontSize: CGFloat = 14.0
// Size for the timer name label when it is selected.
let kETTimerNameFontSizeSelected: CGFloat = 23.0
let kETTimerNameY: CGFloat = 20.0 // Status bar height.  Could use [UIApplication sharedApplication].statusBarFrame.size.height
let kETTimerNameYSelected: CGFloat = 147.0
let kETTimerNameHeight: CGFloat = 30.0

// Settings for the Timer Count Label at the top of the screen
let kETTimerCountFontName = "HelveticaNeue-Light"
let kETTimerCountFontSize: CGFloat = 18.0
// Size for the timer count when it is selected.
let kETTimerCountFontSizeSelected: CGFloat = 72.0
let kETTimerCountY: CGFloat = 34.0
let kETTimerCountYSelected: CGFloat = 170.0
let kETTimerCountHeight: CGFloat = 83.0

// The height of the tap region to select a timer.  Should be roughly the
// height of the two labels together.
let kETTapEnableHeight: CGFloat = 40.0

// Format a duration in seconds into a string.
func ETFormatDuration(duration: NSTimeInterval) -> String {
    let seconds = Int(duration % 60)
    let minutes = Int((duration / 60) % 60)
    let hours = Int((duration / 60) / 60)
    if hours == 0 {
        return NSString(format: "%i:%02i", minutes, seconds)
    } else {
        return NSString(format: "%i:%02i:%02i", hours, minutes, seconds)
    }
}

// Helper for creating CATextLayers.
func ETCreateCATextLayer() -> CATextLayer {
    var layer = CATextLayer()
    layer.contentsScale = UIScreen.mainScreen().scale
    layer.rasterizationScale = UIScreen.mainScreen().scale
    return layer
}


// Encapsulation of a timer.
// This includes the timer settings (name, alarm sound, duration, etc.) as
// well as the views for displaying the timer.
//
// The ETTimers class keeps a list of all the timers.  It is responsible
// for creating the timers and loading their settings from disk.  NSCoding
// is used for serialization.
//
// We use CATextLayer for labels because animating UILabel is problematic
// (you can animate transform, but large transforms look poor).  CATextLayer
// is much more powerful, and better with animation.
//
// The labels' width is the width of the screen at all times, and the height
// stays constaint.  This makes things a little convenient.  Just beware that
// when the labels are at the top of the screen, they overlap, and extend off
// the screen.
//
// Must subclass from NSObject for the NSTimer to work.
class ETTimer: NSObject, NSCoding, UIAlertViewDelegate {
    var name: String
    // For convenience, this is the index into the global timers list.
    var timerIndex: Int
    var themeId: String {
        get {
            return theme.id
        }
        set {
            // Doing a force unwrap to force a runtime error
            // if the theme is not found.
            theme = sharedThemes.themeById(newValue)!
        }
    }
    // Convenient access to the theme.
    var theme: ETTheme!

    var alarmId: String {
        get {
            return alarm.id
        }
        set {
            // Doing a force unwrap to force a runtime error
            // if the theme is not found.
            alarm = sharedAlarms.alarmById(newValue)!
        }
    }
    // Convenient access to the theme.
    var alarm: ETAlarm!

    // What the timer was set to, in seconds.
    var duration: NSTimeInterval
    // What the current value of the timer is.
    // Primarily used for paused timers.
    var durationRemaining: NSTimeInterval
    var durationText: String {
        get {
            return ETFormatDuration(duration)
        }
    }
    var durationRemainingText: String {
        get {
            return ETFormatDuration(durationRemaining)
        }
    }
    var alertText: String {
        get {
            return "\(name) Done"
        }
    }

    // The X position of the timer labels on the top of the screen.
    var labelX: CGFloat = 0

    // The timer name layer contains the text for the name of the timer.
    var timerNameLayer: CATextLayer!
    // The counter layer contains the text showing how much time is remaining.
    var counterLayer: CATextLayer!
    // An empty view to capture tap events.
    var tapView: UIView!

    // The time when the alarm should ring.  This is only set when the timer
    // is running.
    var timerEndDate: NSDate!
    // This timer is used to update the display.  It is also responsible for
    // checking when the time has elapsed and playing the alarm.
    // It is nil if the timer is stopped/paused, or the app is in the
    // background (in which case, we rely on the UILocalNotification to alert 
    // the user).
    var timer: NSTimer!
    // Notification used when the app is in the background.
    var localNotif: UILocalNotification!
    // Audio player used when the timer alarm fires when the app is in the
    // foreground.
    var audioPlayer: AVAudioPlayer!

    init(name: String, duration: NSTimeInterval, themeId: String, alarmId: String, index: Int) {
        self.name = name
        self.duration = duration
        self.durationRemaining = duration
        self.timerIndex = index
        // This is out of order due to the setters.
        super.init()
        self.themeId = themeId
        self.alarmId = alarmId

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "resignActive", name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "enterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "switchTheme", name: kETNotificationNewTheme, object: nil)

    }

    func rename(newName: String) {
        name = newName
        timerNameLayer.string = newName
    }

    func createLabelsInView(view: UIView) {
        var timerWidth = view.frame.width/CGFloat(kTimerCount)
        var timerX = timerWidth*CGFloat(timerIndex)
        labelX = timerX + timerWidth/2.0 - view.frame.width/2.0

        timerNameLayer = ETCreateCATextLayer()
        timerNameLayer.frame = CGRect(x: labelX, y: kETTimerNameY,
            width: view.frame.width, height: kETTimerNameHeight)
        timerNameLayer.string = name
        timerNameLayer.font = kETTimerNameFontName
        timerNameLayer.fontSize = kETTimerNameFontSize
        timerNameLayer.alignmentMode = kCAAlignmentCenter
        timerNameLayer.foregroundColor = ETGetCurrentTheme().softColor.CGColor
        view.layer.addSublayer(timerNameLayer)

        counterLayer = ETCreateCATextLayer()
        counterLayer.frame = CGRect(x: labelX, y: kETTimerCountY,
            width: view.frame.width, height: kETTimerCountHeight)
        counterLayer.string = durationRemainingText
        counterLayer.font = kETTimerCountFontName
        counterLayer.fontSize = kETTimerCountFontSize
        counterLayer.alignmentMode = kCAAlignmentCenter
        counterLayer.foregroundColor = ETGetCurrentTheme().softColor.CGColor
        view.layer.addSublayer(counterLayer)

        tapView = UIView(frame: CGRect(x: timerX, y: kETTimerNameY,
            width: timerWidth, height: kETTapEnableHeight))
        tapView.userInteractionEnabled = true
        // Use a tag so we can determine which one was tapped.
        tapView.tag = timerIndex
        view.addSubview(tapView)
    }

    func makeLabelsActiveInView(view: UIView) {
        timerNameLayer.frame = CGRect(x: 0, y: kETTimerNameYSelected,
            width: view.frame.width, height: kETTimerNameHeight)
        timerNameLayer.fontSize = kETTimerNameFontSizeSelected

        counterLayer.frame = CGRect(x: 0, y: kETTimerCountYSelected,
            width: view.frame.width, height: kETTimerCountHeight)
        counterLayer.fontSize = kETTimerCountFontSizeSelected
    }

    func makeLabelsInactiveInView(view: UIView) {
        timerNameLayer.frame = CGRect(x: labelX, y: kETTimerNameY,
            width: view.frame.width, height: kETTimerNameHeight)
        timerNameLayer.fontSize = kETTimerNameFontSize

        counterLayer.frame = CGRect(x: labelX, y: kETTimerCountY,
            width: view.frame.width, height: kETTimerCountHeight)
        counterLayer.fontSize = kETTimerCountFontSize
    }

    func updateDisplay() {
        counterLayer.string = durationRemainingText
    }

    func switchTheme() {
        timerNameLayer.foregroundColor = ETGetCurrentTheme().softColor.CGColor
        counterLayer.foregroundColor = ETGetCurrentTheme().softColor.CGColor

    }

    func addTime(seconds: NSTimeInterval) {
        duration += seconds
        durationRemaining += seconds
        if timerEndDate {
            // The timer is currently running, give it more time.
            timerEndDate = NSDate(timeIntervalSinceNow: NSTimeInterval(durationRemaining))
            scheduleNotification()
        }
    }

    func isRunning() -> Bool {
        if timerEndDate {
            return timerEndDate.timeIntervalSinceNow > 0
        }
        return false
    }

    func start() {
        if !timer {
            timerEndDate = NSDate(timeIntervalSinceNow: NSTimeInterval(durationRemaining))
            scheduleTimer()
            scheduleNotification()
        }
    }
    func scheduleTimer() {
        assert(!timer)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
            target: self, selector: "timerFired:", userInfo: nil, repeats: true)
    }

    func scheduleNotification() {
        if localNotif {
            UIApplication.sharedApplication().cancelLocalNotification(localNotif)
        }
        localNotif = UILocalNotification()
        localNotif.fireDate = timerEndDate
        localNotif.alertBody = alertText
        localNotif.alertAction = "OK"
        localNotif.soundName = alarm.path
        //localNotif.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(localNotif)
    }

    func pause() {
        if timer {
            timer.invalidate()
            timer = nil
            timerEndDate = nil
            if localNotif {
                UIApplication.sharedApplication().cancelLocalNotification(localNotif)
                localNotif = nil
            }
        }
    }

    func timerFired(t: NSTimer) -> Void {
        if timerIndex == sharedTimers.currentTimerIndex {
            // Let view controller update the background display.
            NSNotificationCenter.defaultCenter().postNotificationName(kETNotificationActiveTimerTick, object: nil)
        }
        durationRemaining = timerEndDate.timeIntervalSinceNow
        if durationRemaining <= 0 {
            // Timer is finished.
            pause()
            // Reset timer so it can be used again.
            durationRemaining = duration
            // Used mainly to let the ViewController know that a timer finished, and
            // that it should update the buttons as needed.
            NSNotificationCenter.defaultCenter().postNotificationName(kETNotificationTimerEnd, object: nil)
            playAlarm()
        }
        updateDisplay()
    }

    func playAlarm() {
        // This is a workaround for a bug in Swift.  In 8.0, they deprecated
        // UIAlertView in favor of UIAlertController, but unfortunately
        // UIAlertView is broken.  It still works from ObjC, so I'm using a
        // little bridge to use it.
        ETShowAlert(alertText, nil, self, "OK")

//        var path = NSBundle.mainBundle().pathForResource("extreme_clock_alarm", ofType: "caf")
        var path = String.pathWithComponents([NSBundle.mainBundle().resourcePath, alarm.path])
        var url = NSURL(fileURLWithPath: path)
        var error: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        // This could be based on the length of the audio clip (such as, repeat
        // for 5 minutes).  Alternatively it could loop forever.  This is
        // also a candidate for a configurable setting.
        audioPlayer.numberOfLoops = 9
        if error != nil {
            println("Error playing file \(error)")
        } else {
            println("Playing")
            audioPlayer.play()
        }

        // More gratuitous casting.
        //AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        ETVibrateStart(30)
    }

    func alertView(alertView: UIAlertView!, didDismissWithButtonIndex buttonIndex: Int) {
        // Alert was dismissed.
        audioPlayer.stop()
        ETVibrateStop()
    }

    func resignActive() {
        // Stop any active alarms.
        if audioPlayer {
            audioPlayer.stop()
            ETVibrateStop()
        }
        // Disable the display timer.
        if timer {
            timer.invalidate()
            timer = nil
        }
    }

    func enterForeground() {
        if timerEndDate {
            // The timer should be running.
            let interval = timerEndDate.timeIntervalSinceNow
            if interval > 0 {
                // The timer is still running and valid.
                durationRemaining = interval
                scheduleTimer()
            } else {
                // Timer expired while we were away.
                timerEndDate = nil
                // Unfortunately there does not appear to be a way to stop
                // a UILocalNotification sound.
                if localNotif {
                    UIApplication.sharedApplication().cancelLocalNotification(localNotif)
                    localNotif = nil
                }
                // Reset timer so it can be used again.
                durationRemaining = duration
            }
        }
        updateDisplay()
    }

    // Reload timers after app launch.
    func resumeSuspendedTimer() {
        if timerEndDate {
            // Process exited while a timer was running.
            if timerEndDate.timeIntervalSinceNow > 0 {
                // And the timer should still be running.
                enterForeground()
            } else {
                timerEndDate = nil
            }
        }
    }

    // MARK: NSCoding
    convenience required init(coder aDecoder: NSCoder!) {
        self.init(
            name: aDecoder.decodeObjectForKey("name") as String,
            duration: aDecoder.decodeObjectForKey("duration") as NSTimeInterval,
            themeId: aDecoder.decodeObjectForKey("themeId") as String,
            alarmId: aDecoder.decodeObjectForKey("alarmId") as String,
            index: aDecoder.decodeObjectForKey("timerIndex") as Int
        )
        durationRemaining = aDecoder.decodeObjectForKey("durationRemaining") as NSTimeInterval
        timerEndDate = aDecoder.decodeObjectForKey("timerEndDate") as? NSDate
    }

    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(duration, forKey: "duration")
        aCoder.encodeObject(durationRemaining, forKey: "durationRemaining")
        aCoder.encodeObject(themeId, forKey: "themeId")
        aCoder.encodeObject(timerIndex, forKey: "timerIndex")
        aCoder.encodeObject(alarmId, forKey: "alarmId")
        aCoder.encodeObject(timerEndDate, forKey: "timerEndDate")
    }
}
