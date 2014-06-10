//
//  ViewController.swift
//  eTimer
//
//  Created by Eric Huss on 6/6/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

let kETTableCellIdentifier = "ETTableCellIdentifier"

let kETNotificationNewTheme = "ETNotificationNewTheme"

let kETBackGradientHeight: Float = 100.0

class ViewController: UIViewController, UITextFieldDelegate, UITabBarDelegate {
                            
//    var backgroundView : UIView!
    var backgroundLayer: CAGradientLayer!

    @IBOutlet var plusHourButton : ETButton
    @IBOutlet var plus15Button : ETButton
    @IBOutlet var plus5Button : ETButton
    @IBOutlet var plus1Button : ETButton
    @IBOutlet var startButton : ETButton
    @IBOutlet var clearButton : ETButton
    @IBOutlet var alarmButton : ETButton

    /***********************************************************************/
    // MARK: Setup
    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundLayer = CAGradientLayer()
        backgroundLayer.frame = CGRect(x: 0, y: -view.frame.height-kETBackGradientHeight,
            width: view.frame.width, height: view.frame.height*2+kETBackGradientHeight)
        var bga = (view.frame.height) / backgroundLayer.frame.height
        var bgb = (view.frame.height + kETBackGradientHeight) / backgroundLayer.frame.height
        backgroundLayer.locations = [0.0, bga, bgb, 1.0]
        view.layer.insertSublayer(backgroundLayer, atIndex: 0)

        createLabels()

        // Make the current timer front-and-center.
        sharedTimers.currentTimer.makeLabelsActiveInView(view)

        // Notification from ETTimer.
        let noc = NSNotificationCenter.defaultCenter()
        noc.addObserver(self, selector: "endTimerNotification",
            name: kETNotificationTimerEnd, object: nil)
        noc.addObserver(self, selector: "enterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        noc.addObserver(self, selector: "switchTheme",
            name: kETNotificationNewTheme, object: nil)
        noc.addObserver(self, selector: "activeTimerTick",
            name: kETNotificationActiveTimerTick, object: nil)

        // Unforutnately you can't set the image rendering mode in Interface Builder.
        var i = alarmButton.imageView.image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        alarmButton.setImage(i, forState: UIControlState.Normal)

        // Assuming that viewDidLoad() is the same as app launching, which is
        // generally safe in our setup.  I think.
        sharedTimers.resumeSuspendedTimers()

        switchTheme()
        updateDisplay()
    }

    func createLabels() {
        for timer in sharedTimers.timers {
            timer.createLabelsInView(view)
            let r = UITapGestureRecognizer(target: self, action: "switchTimerTap:")
            timer.tapView.addGestureRecognizer(r)
        }

        // Create an empty view that will catch tap events for renaming the timer.
        renameTapView = UIView(frame: CGRect(x: 0, y: kETTimerNameYSelected,
            width: view.frame.width, height: kETTimerNameHeight))
        renameTapView.userInteractionEnabled = true
        view.addSubview(renameTapView)
        let r = UITapGestureRecognizer(target: self, action: "tapRename")
        renameTapView.addGestureRecognizer(r)

        // View for renaming.
        renameTextField = UITextField(frame: CGRect(x: 0, y: kETTimerNameYSelected,
            width: view.frame.width, height: kETTimerNameHeight))
        renameTextField.font = UIFont(name: kETTimerNameFontName, size: kETTimerNameFontSizeSelected)
        renameTextField.textAlignment = NSTextAlignment.Center
        renameTextField.hidden = true
        renameTextField.delegate = self
        renameTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        view.addSubview(renameTextField)
    }

    func updateDisplay() {
        if sharedTimers.currentTimer.isRunning() {
            startButton.setTitle("Pause", forState: UIControlState.Normal)
            startButton.etColorType = ETColorTypes.Red.toRaw()
            clearButton.setTitle("Cancel", forState: UIControlState.Normal)
        } else {
            startButton.setTitle("Start", forState: UIControlState.Normal)
            startButton.etColorType = ETColorTypes.Green.toRaw()
            clearButton.setTitle("Clear", forState: UIControlState.Normal)
        }
        updateBackground()
    }

    func switchTheme() {
        let newTheme = ETGetCurrentTheme()
        // ETTimer will handle updates to the timer labels.
        backgroundLayer.colors = [
            newTheme.backgroundEmptyColor.CGColor,
            newTheme.backgroundEmptyColor.CGColor,
            newTheme.backgroundFullColor.CGColor,
            newTheme.backgroundFullColor.CGColor,
        ]
        // Buttons update their colors themselves.
    }

    func activeTimerTick() {
        updateBackground()
    }

    func updateBackground() {
        // Determine how far along the current timer is as a percentage.
        let t = sharedTimers.currentTimer
        let progress: Float = t.duration == 0 ? 0 : 1.0 - Float(t.durationRemaining) / Float(t.duration)
        // The y coordinate at the start.
        let a: Float = -view.frame.height-kETBackGradientHeight
        // The y coordinate at the end.
        let b: Float = 0.0
        // lerp
        let y = a + progress*(b - a)
        let bgf = backgroundLayer.frame
        backgroundLayer.frame = CGRect(x: bgf.origin.x, y: y, width: bgf.width, height: bgf.height)
    }

    /***********************************************************************/
    // MARK: Notifications
    func endTimerNotification() {
        updateDisplay()
    }

    func enterForeground() {
        updateDisplay()
    }

    /***********************************************************************/
    // MARK: UI Control events.

    // A tap event on one of the timers at the top of the screen.
    func switchTimerTap(recognizer: UITapGestureRecognizer) {
        let toTimerIndex = recognizer.view.tag
        if sharedTimers.currentTimerIndex != toTimerIndex {
            var oldTimer = sharedTimers.currentTimer
            var newTimer = sharedTimers.timers[toTimerIndex]
            sharedTimers.currentTimerIndex = toTimerIndex

            func animations() {
                oldTimer.makeLabelsInactiveInView(view)
                newTimer.makeLabelsActiveInView(view)
                for timer in sharedTimers.timers {
                    timer.switchTheme() 
                }
            }
            func aniCompletion(finished: Bool) {
                println("completed")
            }

            CATransaction.begin()
            CATransaction.setValue(1.0, forKey: kCATransactionAnimationDuration)
            animations()
            CATransaction.commit()

            UIView.animateWithDuration(1.0) {
                self.switchTheme()
            }
            updateDisplay()
        }
    }

    @IBAction func tapPlus1() {
        sharedTimers.currentTimer.addTime(60)
        sharedTimers.currentTimer.updateDisplay()
    }
    @IBAction func tapPlus5() {
        sharedTimers.currentTimer.addTime(5 * 60)
        sharedTimers.currentTimer.updateDisplay()
    }
    @IBAction func tapPlus15() {
        sharedTimers.currentTimer.addTime(15 * 60)
        sharedTimers.currentTimer.updateDisplay()
    }
    @IBAction func tapPlus1hr() {
        sharedTimers.currentTimer.addTime(60 * 60)
        sharedTimers.currentTimer.updateDisplay()
    }

    @IBAction func tapStart() {
        if sharedTimers.currentTimer.isRunning() {
            sharedTimers.currentTimer.pause()
        } else {
            sharedTimers.currentTimer.start()
        }
        updateDisplay()
    }

    @IBAction func tapClear() {
        if sharedTimers.currentTimer.isRunning() {
            sharedTimers.currentTimer.pause()
            sharedTimers.currentTimer.durationRemaining = sharedTimers.currentTimer.duration
        } else {
            sharedTimers.currentTimer.duration = 0
            sharedTimers.currentTimer.durationRemaining = 0
        }
        sharedTimers.currentTimer.updateDisplay()
        updateDisplay()
    }

    @IBAction func tapBell() {
        showThemeSelection()
    }

    /***********************************************************************/
    // MARK: Renaming
    var renameTapView: UIView!
    var renameTextField: UITextField!

    func tapRename() {
        let currentTimer = sharedTimers.currentTimer
        renameTapView.userInteractionEnabled = false
        renameTextField.text = currentTimer.name
        renameTextField.textColor = currentTimer.theme.softColor
        renameTextField.hidden = false
        currentTimer.timerNameLayer.hidden = true
        renameTextField.becomeFirstResponder()
    }

    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        let currentTimer = sharedTimers.currentTimer
        currentTimer.rename(renameTextField.text)
        renameTextField.resignFirstResponder()
        renameTextField.hidden = true
        currentTimer.timerNameLayer.hidden = false
        renameTapView.userInteractionEnabled = true
        return true
    }

    /***********************************************************************/
    // MARK: Theme Selection
    var themeTableView: UITableView!
    var themeTabBar: UITabBar!
    var themeView: UIView!
    // Currently an empty view, used to dismiss the theme selector.
    var themeExitView: UIView!

    enum ETThemeSelMode {
        case Theme, Alarm
    }
    var themeSelMode = ETThemeSelMode.Theme

    var themeTable = ETThemeTable()
    var alarmTable = ETAlarmTable()

    func showThemeSelection() {
        if !themeView {
            // Create all the views necessary for selecting the theme and alarm.
            let width = view.frame.width/2.0

            // Assumes width is half.
            themeExitView = UIView(frame: CGRect(x: 0, y: 0,
                width: width, height: view.frame.height))
            themeExitView.userInteractionEnabled = true
            let r = UITapGestureRecognizer(target: self, action: "tapDismissThemeSelector")
            themeExitView.addGestureRecognizer(r)
            view.addSubview(themeExitView)

            // Initially offscreen.
            themeView = UIView(frame: CGRect(x: view.frame.width, y: 0,
                width: width, height: view.frame.height))
            view.addSubview(themeView)

            // TODO: Some way to determine 49 programmatically.
            themeTabBar = UITabBar(frame: CGRect(x: 0, y: view.frame.height-49,
                width: width, height: 49))
            var alarmItem = UITabBarItem(title: "Alarms", image: nil, tag: 0)
            alarmItem.image = UIImage(named: "bell")
            var themeItem = UITabBarItem(title: "Themes", image: nil, tag: 1)
            themeItem.image = UIImage(named: "themesIconDim").imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            themeItem.selectedImage = UIImage(named: "themesIcon").imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            themeTabBar.setItems([alarmItem, themeItem], animated:false)
            // TODO: Switch to 0 (Alarms)
            themeTabBar.selectedItem = alarmItem
            themeTabBar.delegate = self
            themeView.addSubview(themeTabBar)

            themeTableView = UITableView(frame: CGRect(x: 0, y: 20,
                width: width, height: view.frame.height - 49 - 20))
            themeTableView.dataSource = alarmTable
            themeTableView.delegate = alarmTable
            themeView.addSubview(themeTableView)
        } else {
            // Theme views already exist.
            // Put this back into position.
            themeExitView.center = CGPoint(x: themeExitView.center.x-view.frame.width, y: themeExitView.center.y)
            themeTableView.reloadData()
        }
        // Animate into position.
        UIView.animateWithDuration(1.0) {
            self.themeView.center = CGPoint(x: self.themeView.center.x-self.themeView.frame.width,
                y: self.themeView.center.y)
        }
    }

    func tapDismissThemeSelector() {
        // Position off screen.
        themeExitView.center = CGPoint(x: themeExitView.center.x+view.frame.width, y: themeExitView.center.y)
        // Animate away.
        UIView.animateWithDuration(1.0) {
            self.themeView.center = CGPoint(x: self.themeView.center.x+self.themeView.frame.width,
                y: self.themeView.center.y)
        }
    }

    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        switch item.tag {
        case 0: // Alarms
            themeTableView.dataSource = alarmTable
            themeTableView.delegate = alarmTable
        case 1: // Themes
            themeTableView.dataSource = themeTable
            themeTableView.delegate = themeTable
        default:
            abort()
        }
        themeTableView.reloadData()
    }
}

/*****************************************************************************/
class ETThemeTableBase: NSObject, UITableViewDataSource, UITableViewDelegate {
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell = tableView.dequeueReusableCellWithIdentifier(kETTableCellIdentifier) as UITableViewCell!
        if !cell {
            cell = UITableViewCell(style: UITableViewCellStyle.Default,
                reuseIdentifier: kETTableCellIdentifier)
            cell.textLabel.adjustsFontSizeToFitWidth = true
        }
        cell.textLabel.text = textForCellAtIndex(indexPath.row)
        if indexPath.row == currentCheckedIndex() {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }

    // Subclass must implement.
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    func textForCellAtIndex(index: Int) -> String {
        return ""
    }
    func currentCheckedIndex() -> Int {
        return 0
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let oldCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: currentCheckedIndex(), inSection: 0)) {
            oldCell.accessoryType = UITableViewCellAccessoryType.None
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
    }

}

/*****************************************************************************/

class ETThemeTable: ETThemeTableBase {

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return sharedThemes.themes.count
    }
    override func textForCellAtIndex(index: Int) -> String {
        return sharedThemes.themes[index].name
    }
    override func currentCheckedIndex() -> Int {
        return ETGetCurrentTheme().themeIndex
    }

    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        let newTheme = sharedThemes.themes[indexPath.row]
        sharedTimers.currentTimer.themeId = newTheme.id
        NSNotificationCenter.defaultCenter().postNotificationName(kETNotificationNewTheme, object: nil)
    }
}

/*****************************************************************************/

class ETAlarmTable: ETThemeTableBase {

    var audioPlayer: AVAudioPlayer! = nil

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return sharedAlarms.alarms.count
    }
    override func textForCellAtIndex(index: Int) -> String {
        return sharedAlarms.alarms[index].name
    }
    override func currentCheckedIndex() -> Int {
        return sharedTimers.currentTimer.alarm.alarmIndex
    }

    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        let newAlarm = sharedAlarms.alarms[indexPath.row]
        sharedTimers.currentTimer.alarmId = newAlarm.id

        var path = String.pathWithComponents([NSBundle.mainBundle().resourcePath, newAlarm.path])
        var url = NSURL(fileURLWithPath: path)
        var error: NSError?
        if audioPlayer {
            audioPlayer.stop()
        }
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if error {
            println("Error playing file \(error)")
        } else {
            println("Playing")
            audioPlayer.play()
        }

    }
}
