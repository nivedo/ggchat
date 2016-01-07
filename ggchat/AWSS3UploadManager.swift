//
//  AWSS3UploadManager.swift
//  ggchat
//
//  Created by Gary Chang on 12/3/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import AWSS3

class S3Upload {
    var request: AWSS3TransferManagerUploadRequest?
    var fileURL: NSURL?
    var userData: [String: AnyObject]?
    
    init(request: AWSS3TransferManagerUploadRequest, userData: [String: AnyObject]?) {
        self.request = request
        self.fileURL = nil
        self.userData = userData
    }
    
    func onSuccess(fileURL: NSURL) {
        self.request = nil
        self.fileURL = fileURL
    }
}

protocol S3UploadDelegate {
    
    func onUploadFailure()
    func onUploadSuccess(key: String, userData: [String: AnyObject]?)
    func onUploadPauseCancel()
    func onUploadCancelFailure()
    func onUploadPauseFailure()
    
}

struct S3PhotoSize {
    static let facebook = CGSize(width: 1200, height: 628)
    static let twitter = CGSize(width: 1024, height: 512)
    static let linkedin = CGSize(width: 800, height: 800)
    static let google = CGSize(width: 800, height: 1200)
    static let pinterest = CGSize(width: 735, height: 1102)
    static let instagram = CGSize(width: 1080, height: 1080)
    
    static let maxDimension = CGFloat(1200.0)
    static let thumbnailDimension = CGFloat(20.0)  // Thumbnail should be less than 10 KB
}

class S3PhotoManager: S3UploadDelegate {
    
    class var sharedInstance: S3PhotoManager {
        struct Singleton {
            static let instance = S3PhotoManager()
        }
        return Singleton.instance
    }
    
    init() {
        AWSS3UploadManager.sharedInstance.delegate = self
    }
    
    func originalCompressedImage(image: UIImage) -> UIImage {
        let size = CGSizeMake(S3PhotoSize.maxDimension, S3PhotoSize.maxDimension)
        return image.gg_imageCompressedToFitSize(size, isOpaque: true)
    }
    
    func thumbnailCompressedImage(image: UIImage) -> UIImage {
        let size = CGSizeMake(S3PhotoSize.thumbnailDimension, S3PhotoSize.thumbnailDimension)
        return image.gg_imageCompressedToFitSize(size, isOpaque: true)
    }
   
    func sendPhoto(image: UIImage, to: String) {
        print("sendPhoto to: \(to)")
        
        let originalImage = self.originalCompressedImage(image)
        let thumbnailImage = self.thumbnailCompressedImage(image)
        
        let uniqueKey = NSProcessInfo.processInfo().globallyUniqueString
        let originalKey = "\(uniqueKey).jpg"
        let thumbnailKey = "\(uniqueKey)_thumb.jpg"
        let userData: [String: AnyObject] = [
            "originalKey"  : originalKey,
            "thumbnailKey"  : thumbnailKey,
            "to" : to
        ]
        AWSS3UploadManager.sharedInstance.upload(originalImage, fileName: originalKey)
        AWSS3UploadManager.sharedInstance.upload(thumbnailImage, fileName: thumbnailKey, userData: userData)
    }
   
    /*
    func getPhotoMessage(xmppMessage: DDXMLElement, completion: ((Void) -> Void)?, delegate: MessageMediaDelegate?) -> Message? {
        let photo = xmppMessage.elementForName("body")!.elementForName("photo")!
        let originalKey = photo.elementForName("originalKey")!.stringValue()
        let thumbnailKey = photo.elementForName("thumbnailKey")!.stringValue()
        let from = xmppMessage.attributeStringValueForName("from")!
       
        if S3ImageCache.sharedInstance.isImageCachedForKey(originalKey) {
            S3ImageCache.sharedInstance.retrieveImageForKey(originalKey,
                bucket: GGSetting.awsS3BucketName,
                completion: { (image: UIImage?) -> Void in
                if let image = image {
                    return self.photoMessage(image, from: from, delegate: delegate)
                }
            })
        } else {
            
        }
        
        /*
        if let originalFileURL = AWSS3DownloadManager.sharedInstance.fileURLOfDownloadKey(originalKey) {
            // print("Found cached download at \(originalFileURL)")
            return self.photoMessage(originalFileURL, from: from, delegate: delegate)
        } else {
            if let thumbnailFileURL = AWSS3DownloadManager.sharedInstance.fileURLOfDownloadKey(thumbnailKey) {
                // print("Found cached download at \(thumbnailFileURL)")
                return self.photoMessage(thumbnailFileURL, from: from, delegate: delegate)
            } else {
                let message: Message = self.placeholderPhotoMessage(from)
                AWSS3DownloadManager.sharedInstance.download(
                    thumbnailKey,
                    userData: nil,
                    completion: { (fileURL: NSURL) -> Void in
                        // message = self.photoMessage(fileURL, from: from)
                        // print("Downloaded \(fileURL)")
                        let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                        let image = UIImage(data: data)
                        message.addMedia(PhotoMediaItem(image: image!, delegate: delegate))
                        completion?()
                        
                        AWSS3DownloadManager.sharedInstance.download(
                            originalKey,
                            userData: nil,
                            completion: { (fileURL: NSURL) -> Void in
                            let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                            let image = UIImage(data: data)
                            message.addMedia(PhotoMediaItem(image: image!, delegate: delegate))
                            completion?()
                        })
                    })
                return message
            }
        }
        */
    }

    func photoMessage(image: UIImage, from: String, delegate: MessageMediaDelegate?) -> Message {
        let photoMedia: PhotoMediaItem = PhotoMediaItem(image: image, delegate: delegate)
        let message: Message = Message(
            senderId: from,
            senderDisplayName: from,
            isOutgoing: XMPPManager.sharedInstance.isOutgoingJID(from),
            date: NSDate(),
            media: photoMedia)
        return message
    }
    
    func placeholderPhotoMessage(from: String) -> Message {
        let photoMedia: PhotoMediaItem = PhotoMediaItem()
        let message: Message = Message(
            senderId: from,
            senderDisplayName: from,
            isOutgoing: XMPPManager.sharedInstance.isOutgoingJID(from),
            date: NSDate(),
            media: photoMedia)
        return message
    }
    */
    
    // S3UploadDelegate methods
    func onUploadFailure() {
        
    }
    
    func onUploadSuccess(key: String, userData: [String: AnyObject]?) {
        print("onUploadSucces: \(key)")
        
        if let data = userData,
            let originalKey = data["originalKey"] as? String,
            let thumbnailKey = data["thumbnailKey"] as? String,
            let to = data["to"] as? String {
            XMPPMessageManager.sendPhoto(
                originalKey,
                thumbnailKey: thumbnailKey,
                to: to,
                completionHandler: nil)
        }
    }
    
    func onUploadPauseCancel() {
        
    }
    
    func onUploadCancelFailure() {
        
    }
    
    func onUploadPauseFailure() {
        
    }
}

class AWSS3UploadManager {
   
    let tempFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("upload")
    
    class var sharedInstance: AWSS3UploadManager {
        struct Singleton {
            static let instance = AWSS3UploadManager()
        }
        return Singleton.instance
    }

    init() {
        let error = NSErrorPointer()
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                tempFolderURL,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch let error1 as NSError {
            error.memory = error1
            print("Creating 'upload' directory failed. Error: \(error)")
        }
    }
    
    var uploads = Array<S3Upload?>()
    var delegate: S3UploadDelegate?
   
    func upload(image: UIImage, fileName: String, userData: [String: AnyObject]? = nil, bucket: String = GGSetting.awsS3BucketName, completion: ((Bool) -> Void)? = nil) {
        let fileURL = self.tempFolderURL.URLByAppendingPathComponent(fileName)
        let filePath = fileURL.path!
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        imageData!.writeToFile(filePath, atomically: true)
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = fileURL
        uploadRequest.key = fileName
        uploadRequest.bucket = bucket // GGSetting.awsS3BucketName
        
        self.uploads.append(S3Upload(request: uploadRequest, userData: userData))
        self.upload(uploadRequest, completion: completion)
    }
    
    func upload(uploadRequest: AWSS3TransferManagerUploadRequest, completion: ((Bool) -> Void)? = nil) {
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch (errorCode) {
                        case .Cancelled, .Paused:
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.delegate?.onUploadPauseCancel()
                            })
                            break;
                            
                        default:
                            print("upload() failed: [\(error)]")
                            self.delegate?.onUploadFailure()
                            completion?(false)
                            break;
                        }
                    } else {
                        print("upload() failed: [\(error)]")
                        self.delegate?.onUploadFailure()
                        completion?(false)
                    }
                } else {
                    print("upload() failed: [\(error)]")
                    self.delegate?.onUploadFailure()
                    completion?(false)
                }
            }
            
            if let exception = task.exception {
                print("upload() failed: [\(exception)]")
                self.delegate?.onUploadFailure()
                completion?(false)
            }
            
            if task.result != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let index = self.indexOfUploadRequest(uploadRequest) {
                        let key = uploadRequest.key!
                        self.uploads[index]!.onSuccess(uploadRequest.body)
                        self.delegate?.onUploadSuccess(key, userData: self.uploads[index]!.userData)
                        completion?(true)
                    }
                })
            }
            return nil
        }
    }
    
    func cancelAllUploads() {
        for (_, uploadRequest) in self.uploads.enumerate() {
            if let uploadRequest = uploadRequest {
                uploadRequest.request?.cancel().continueWithBlock({ (task) -> AnyObject! in
                    if let error = task.error {
                        print("cancel() failed: [\(error)]")
                        self.delegate?.onUploadCancelFailure()
                    }
                    if let exception = task.exception {
                        print("cancel() failed: [\(exception)]")
                        self.delegate?.onUploadCancelFailure()
                    }
                    return nil
                })
            }
        }
    }
    
    func pause(uploadRequest: AWSS3TransferManagerUploadRequest) {
        uploadRequest.pause().continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                print("pause() failed: [\(error)]")
                self.delegate?.onUploadPauseCancel()
            }
            if let exception = task.exception {
                print("pause() failed: [\(exception)]")
                self.delegate?.onUploadPauseCancel()
            }
            
            return nil
        })
    }
    
    func followProgress(uploadRequest: AWSS3TransferManagerUploadRequest,
        completion: S3ProgressCompletion) {
        uploadRequest.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(bytesSent, totalBytesSent, totalBytesExpectedToSend)
            })
        }
    }
    
    func indexOfUploadRequest(uploadRequest: AWSS3TransferManagerUploadRequest?) -> Int? {
        for (index, object) in self.uploads.enumerate() {
            if object!.request == uploadRequest {
                return index
            }
        }
        return nil
    }
}