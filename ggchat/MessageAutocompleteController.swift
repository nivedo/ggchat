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
    func autocompleteSelect(
        autocompleteController: MessageAutocompleteController,
        assetSuggestion: AssetAutocompleteSuggestion)
}

class AssetAutocompleteSuggestion {
    
    var displayString: String
    var replaceIndex: Int
    var id: String
    
    init(displayString: String, replaceIndex: Int, id: String) {
        self.displayString = displayString
        self.replaceIndex = replaceIndex
        self.id = id
    }
   
    func description() -> String {
        return self.displayString
    }
}

class MessageAutocompleteController: NSObject,
    UITableViewDelegate,
    UITableViewDataSource {
 
    static let defaultRowHeight = CGFloat(44.0)
    static let defaultHeight = CGFloat(44.0 * 4.5)
    
    var tableView: UITableView
    var delegate: MessageAutocompleteControllerDelegate
    var suggestions = [AssetAutocompleteSuggestion]()

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
    
    func displaySuggestions(suggestions: [AssetAutocompleteSuggestion], frame: CGRect) {
        self.tableView.frame = CGRect(
            origin: CGPoint(x: 0, y: frame.origin.y - MessageAutocompleteController.defaultHeight),
            size: CGSize(width: frame.width, height: MessageAutocompleteController.defaultHeight))
        self.tableView.hidden = false
        /*
        self.suggestions = suggestions.map {
            (let str) -> AssetAutocompleteSuggestion in
            return AssetAutocompleteSuggestion(displayString: str)
        }
        */
        self.suggestions = suggestions
        // print(suggestions)
        
        self.tableView.reloadData()
    }
    
    func hide() {
        self.suggestions.removeAll()
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
        let cards = self.suggestions.map{ (var asset) in
            return asset.displayString
        }
        // print(cards)
        
        cell.cellMainLabel.text = suggestion.displayString.capitalizedString
            
        if let icon = GGWiki.sharedInstance.wikis[GGWiki.sharedInstance.autocompleteWiki] {
            cell.iconImageView.image = UIImage(named: icon.icon)
        }
            
        return cell
    }
    
    func tableView(_ tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected autocomplete \(indexPath)")
        let assetSuggestion = self.suggestions[indexPath.row]
            
        self.delegate.autocompleteSelect(
            self,
            assetSuggestion: assetSuggestion)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return MessageAutocompleteController.defaultRowHeight
    }
}
