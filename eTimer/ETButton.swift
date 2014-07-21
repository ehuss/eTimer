//
//  ETButton.swift
//  eTimer
//
//  Created by Eric Huss on 6/6/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

import UIKit

// Simple extension to UIButton.
// Several extra properties are expected to be set in Interface Builder:
// - etFont
// - etFontSize
// - etColorType (see ETColorTypes)
class ETButton: UIButton {

    var etFont: String!
    var etFontSize: NSNumber!
    // The color type used for the ring.
    var etColorType: String! {
        didSet {
            updateEtColor()
        }
    }
    var etColor: UIColor!

    func updateEtColor() {
        var selectedColor: UIColor = ETGetCurrentTheme().softColor
        if etColorType {
            if let cType = ETColorTypes.fromRaw(etColorType) {
                switch cType {
                case ETColorTypes.Green:
                    selectedColor = ETGetCurrentTheme().greenColor
                case ETColorTypes.Red:
                    selectedColor = ETGetCurrentTheme().redColor
                }
            }
        }
        etColor = selectedColor
        setTitleColor(selectedColor, forState: UIControlState.Normal)
        setNeedsDisplay()
    }

    // Must implement the designated initializer, else it will crash.
    init(coder aDecoder: NSCoder!)  {
        super.init(coder: aDecoder)
    }

    init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if etFont {
            let font = UIFont(name: etFont, size: CGFloat(etFontSize ? etFontSize.floatValue : 12))
            assert(font != nil)
            titleLabel.font = font
        }
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateTheme", name: kETNotificationNewTheme, object: nil)
        updateTheme()
    }

    func updateTheme() {
        updateEtColor()
        if currentImage {
            tintColor = ETGetCurrentTheme().softColor
        }
    }

    override func beginTrackingWithTouch(touch: UITouch!, withEvent event: UIEvent!) -> Bool {
        super.beginTrackingWithTouch(touch, withEvent: event)
        // Allow the background color to update in drawRect.
        setNeedsDisplay()
        return true
    }

    override func endTrackingWithTouch(touch: UITouch!, withEvent event: UIEvent!) {
        super.endTrackingWithTouch(touch, withEvent: event)
        // Allow the background color to update in drawRect.
        setNeedsDisplay()
    }

    // Create a circle path for the outline of the button.
    func createPath() -> UIBezierPath {
        var path = UIBezierPath(ovalInRect:CGRect(x: 2, y: 2,
            width: frame.width-4, height: frame.height-4))
        path.lineWidth = 2
        return path
    }

    override func drawRect(rect: CGRect)
    {
        var path = createPath()
        etColor.setStroke()
        var fillColor: UIColor!
        if highlighted {
            fillColor = UIColor(white: 0.5, alpha: 0.35)
        } else {
            fillColor = UIColor(white: 1.0, alpha: 0.35)
        }
        fillColor.setFill()
        var context = UIGraphicsGetCurrentContext()
        path.fill()
        path.stroke()
    }


}
