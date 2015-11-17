//
//  MessageTimestampFormatter.swift
//  ggchat
//
//  Created by Gary Chang on 11/17/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

class MessageTimestampFormatter {

    var dateFormatter: NSDateFormatter
    var dateTextAttributes: [String:AnyObject]
    var timeTextAttributes: [String:AnyObject]
    
    class var sharedInstance: MessageTimestampFormatter {
        struct Singleton {
            static let instance = MessageTimestampFormatter()
        }
        return Singleton.instance
    }
    
    init() {
        self.dateFormatter = NSDateFormatter()
        self.dateFormatter.locale = NSLocale.currentLocale()
        self.dateFormatter.doesRelativeDateFormatting = true
            
        let color: UIColor = UIColor.lightGrayColor()
            
        let paragraphStyle: NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.Center
            
        self.dateTextAttributes = [
            NSFontAttributeName : UIFont.boldSystemFontOfSize(12.0),
            NSForegroundColorAttributeName : color,
            NSParagraphStyleAttributeName : paragraphStyle ]
            
        self.timeTextAttributes = [
            NSFontAttributeName : UIFont.systemFontOfSize(12.0),
            NSForegroundColorAttributeName : color,
            NSParagraphStyleAttributeName : paragraphStyle ]
    }

    // pragma mark - Formatter

    func timestampForDate(date: NSDate) -> String {
        self.dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return self.dateFormatter.stringFromDate(date)
    }
    
    func attributedTimestampForDate(date: NSDate) -> NSAttributedString {
        let relativeDate: String = self.relativeDateForDate(date)
        let time: String = self.timeForDate(date)
        
        let timestamp: NSMutableAttributedString = NSMutableAttributedString(
            string:relativeDate,
            attributes: self.dateTextAttributes)
        
        timestamp.appendAttributedString(NSAttributedString(string:" "))
        
        timestamp.appendAttributedString(NSAttributedString(string:time,
            attributes:self.timeTextAttributes))
        
        return NSAttributedString(string: timestamp.string)
    }
    
    func timeForDate(date: NSDate) -> String {
        self.dateFormatter.dateStyle = NSDateFormatterStyle.NoStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return self.dateFormatter.stringFromDate(date)
    }
    
    func relativeDateForDate(date: NSDate) -> String {
        self.dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        self.dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        return self.dateFormatter.stringFromDate(date)
    }
}