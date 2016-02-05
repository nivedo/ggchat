//
//  ReadReceipt.swift
//  ggchat
//
//  Created by Gary Chang on 2/5/16.
//  Copyright © 2016 Blub. All rights reserved.
//

import Foundation

class ReadReceipt {
    var from: String
    var to: String
    var ids: [String]
    
    init(from: String, to: String, ids: [String]) {
        self.from = UserAPI.stripResourceFromJID(from)
        self.to = UserAPI.stripResourceFromJID(to)
        self.ids = ids
    }
    
    class func parseReadReceiptFromString(xmlString: String) -> ReadReceipt? {
        var element: DDXMLElement?
        do {
            element = try DDXMLElement(XMLString: xmlString)
        } catch _ {
            element = nil
        }
        
        return self.parseReadReceiptFromElement(element)
    }
    
    class func parseReadReceiptFromElement(element: DDXMLElement?) -> ReadReceipt? {
        if let bodyElement = element?.elementForName("body"),
            let from = element?.attributeStringValueForName("from"),
            let to = element?.attributeStringValueForName("to"),
            let type = element?.attributeStringValueForName("type") {
                if type != "chat" {
                    return nil
                }
                if let content_type = element?.attributeStringValueForName("content_type") {
                    if content_type != "read_receipt" {
                        return nil
                    }
                }
                var ids = [String]()
                if let receipts = bodyElement.elementForName("receipts") {
                    let reads = receipts.elementsForName("read")
                    for read in reads {
                        if let id = read.attributeStringValueForName("id") {
                            ids.append(id)
                        }
                    }
                }
                return ReadReceipt(from: from, to: to, ids: ids)
        }
        return nil
    }
}
