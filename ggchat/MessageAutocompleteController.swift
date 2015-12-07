//
//  MessageAutocompleteController.swift
//  ggchat
//
//  Created by Gary Chang on 12/7/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol MessageAutocompleteDelegate {
    func autocompleteController(
        autocompleteController: MessageAutocompleteController)
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
   
    var tableView: UITableView
    var delegate: MessageAutocompleteDelegate
    var suggestions = [AutocompleteSuggestion]()

    init(delegate: MessageAutocompleteDelegate) {
        self.tableView = UITableView()
        self.delegate = delegate

        super.init()
        
        self.tableView.registerNib(MessageAutocompleteCell.nib(),
            forCellReuseIdentifier: MessageAutocompleteCell.cellReuseIdentifier())
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
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
        cell.cellMainLabel.text = suggestion.displayString
            
        return cell
    }
    
}