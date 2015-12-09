//
//  MessageAutocompleteController.swift
//  ggchat
//
//  Created by Gary Chang on 12/7/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol MessageAutocompleteControllerDelegate {
    // func autocompleteController(
    //    autocompleteController: MessageAutocompleteController)
}

class AutocompleteSuggestion {
    
    var displayString: String
    
    init(displayString: String) {
        self.displayString = displayString
    }
    
}

class MessageAutocompleteController: NSObject,
    UITableViewDelegate,
    UITableViewDataSource {
 
    static let defaultRowHeight = CGFloat(44.0)
    static let defaultHeight = CGFloat(44.0 * 3)
    
    var tableView: UITableView
    var delegate: MessageAutocompleteControllerDelegate
    var suggestions = [AutocompleteSuggestion]()

    init(delegate: MessageAutocompleteControllerDelegate) {
        self.tableView = UITableView(frame: UIScreen.mainScreen().bounds)
        self.delegate = delegate

        super.init()
        
        self.tableView.registerNib(MessageAutocompleteCell.nib(),
            forCellReuseIdentifier: MessageAutocompleteCell.cellReuseIdentifier())
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(0.7))
        self.tableView.tableFooterView = UIView()
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyle.White
        
        self.tableView.hidden = true
        self.tableView.reloadData()
    }
    
    func displaySuggestions(suggestions: [String], frame: CGRect) {
        self.tableView.frame = CGRect(
            origin: CGPoint(x: 0, y: frame.origin.y - MessageAutocompleteController.defaultHeight),
            size: CGSize(width: frame.width, height: MessageAutocompleteController.defaultHeight))
        self.tableView.hidden = false
        self.suggestions = suggestions.map {
            (let str) -> AutocompleteSuggestion in
            return AutocompleteSuggestion(displayString: str)
        }
        print(suggestions)
        
        self.tableView.reloadData()
    }
    
    func hide() {
        self.tableView.hidden = true
    }
    
    // Data source methods
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
        return self.suggestions.count
    }
    
    func tableView(_ tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            MessageAutocompleteCell.cellReuseIdentifier(),
            forIndexPath: indexPath) as! MessageAutocompleteCell
     
        let suggestion = self.suggestions[indexPath.row]
        cell.cellMainLabel.text = suggestion.displayString.capitalizedString
            
        return cell
    }
    
    func tableView(_ tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected autocomplete \(indexPath)")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return MessageAutocompleteController.defaultRowHeight
    }
}
