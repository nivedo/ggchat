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
    
    init(request: AWSS3TransferManagerUploadRequest) {
        self.request = request
        self.fileURL = nil
    }
    
    func onSuccess(fileURL: NSURL) {
        self.request = nil
        self.fileURL = fileURL
    }
}

protocol S3UploadDelegate {
    
    func onUploadFailure()
    func onUploadSuccess(fileURL: NSURL)
    func onUploadPauseCancel()
    func onUploadCancelFailure()
    func onUploadPauseFailure()
    
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
   
    func upload(image: UIImage) {
        let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
        let fileURL = self.tempFolderURL.URLByAppendingPathComponent(fileName)
        let filePath = fileURL.path!
        let imageData = UIImagePNGRepresentation(image)
        imageData!.writeToFile(filePath, atomically: true)
        
        self.upload(fileURL, fileName: fileName)
    }
    
    func upload(fileURL: NSURL, fileName: String) {
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = fileURL
        uploadRequest.key = fileName
        uploadRequest.bucket = GGSetting.awsS3BucketName
        
        self.uploads.append(S3Upload(request: uploadRequest))
        self.upload(uploadRequest)
    }
    
    func upload(uploadRequest: AWSS3TransferManagerUploadRequest) {
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
                            break;
                        }
                    } else {
                        print("upload() failed: [\(error)]")
                        self.delegate?.onUploadFailure()
                    }
                } else {
                    print("upload() failed: [\(error)]")
                    self.delegate?.onUploadFailure()
                }
            }
            
            if let exception = task.exception {
                print("upload() failed: [\(exception)]")
                self.delegate?.onUploadFailure()
            }
            
            if task.result != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let index = self.indexOfUploadRequest(uploadRequest) {
                        self.uploads[index]!.onSuccess(uploadRequest.body)
                       
                        self.delegate?.onUploadSuccess(uploadRequest.body)
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