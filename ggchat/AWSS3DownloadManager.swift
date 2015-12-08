//
//  AWSS3DownloadManager.swift
//  ggchat
//
//  Created by Gary Chang on 12/3/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import AWSS3

class S3Download {
    var request: AWSS3TransferManagerDownloadRequest?
    var fileURL: NSURL?
   
    init(request: AWSS3TransferManagerDownloadRequest) {
        self.request = request
        self.fileURL = nil
    }
    
    func onSuccess(fileURL: NSURL) {
        self.request = nil
        self.fileURL = fileURL
    }
}

protocol S3DownloadDelegate {
    
    func onDownloadFailure()
    func onDownloadPause()
    func onDownloadPauseFailure()
    func onDownloadSuccess(fileURL: NSURL)
    
}

class AWSS3DownloadManager {
    
    class var sharedInstance: AWSS3DownloadManager {
        struct Singleton {
            static let instance = AWSS3DownloadManager()
        }
        return Singleton.instance
    }
   
    var downloads = Array<S3Download?>()
    var delegate: S3DownloadDelegate?
    
    func download(downloadRequest: AWSS3TransferManagerDownloadRequest) {
        switch (downloadRequest.state) {
        case .NotStarted, .Paused:
            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
            transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject! in
                if let error = task.error {
                    if error.domain == AWSS3TransferManagerErrorDomain as String
                        && AWSS3TransferManagerErrorType(rawValue: error.code) == AWSS3TransferManagerErrorType.Paused {
                            print("Download paused.")
                            self.delegate?.onDownloadPause()
                    } else {
                        print("download failed: [\(error)]")
                        self.delegate?.onDownloadFailure()
                    }
                } else if let exception = task.exception {
                    print("download failed: [\(exception)]")
                    self.delegate?.onDownloadFailure()
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let index = self.indexOfDownloadRequest(downloadRequest) {
                            self.downloads[index]!.onSuccess(downloadRequest.downloadingFileURL)
                            
                            self.delegate?.onDownloadSuccess(
                                downloadRequest.downloadingFileURL)
                        }
                    })
                }
                return nil
            })
            
            break
        default:
            break
        }
    }
    
    func downloadAll() {
        for (_, value) in self.downloads.enumerate() {
            if let downloadRequest = value?.request {
                if downloadRequest.state == .NotStarted
                    || downloadRequest.state == .Paused {
                        self.download(downloadRequest)
                }
            }
        }
    }
    
    func cancelAllDownloads() {
        for (_, value) in self.downloads.enumerate() {
            if let downloadRequest = value?.request {
                if downloadRequest.state == .Running
                    || downloadRequest.state == .Paused {
                        downloadRequest.cancel().continueWithBlock({ (task) -> AnyObject! in
                            if let error = task.error {
                                print("cancel() failed: [\(error)]")
                            } else if let exception = task.exception {
                                print("cancel() failed: [\(exception)]")
                            }
                            return nil
                        })
                }
            }
        }
    }
    
    func pause(downloadRequest: AWSS3TransferManagerDownloadRequest) {
        downloadRequest.pause().continueWithBlock({ (task) -> AnyObject! in
            if let error = task.error {
                print("pause() failed: [\(error)]")
                self.delegate?.onDownloadPauseFailure()
            } else if let exception = task.exception {
                print("pause() failed: [\(exception)]")
                self.delegate?.onDownloadPauseFailure()
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.delegate?.onDownloadPause()
                })
            }
            return nil
        })
    }
    
    func followProgress(downloadRequest: AWSS3TransferManagerDownloadRequest,
        completion: S3ProgressCompletion) {
        downloadRequest.downloadProgress = { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            })
        }
    }
    
    func indexOfDownloadRequest(downloadRequest: AWSS3TransferManagerDownloadRequest?) -> Int? {
        for (index, object) in self.downloads.enumerate() {
            if object!.request == downloadRequest {
                return index
            }
        }
        return nil
    }
}
