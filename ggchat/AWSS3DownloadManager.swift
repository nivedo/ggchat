//  AWSS3DownloadManager.swift
//  ggchat
//
//  Created by Gary Chang on 12/3/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import AWSS3
import Kingfisher

public typealias S3DownloadCompletion = (NSURL) -> Void

class S3Download {
    var request: AWSS3TransferManagerDownloadRequest?
    var key: String?
    var fileURL: NSURL?
    var userData: [String: AnyObject]?
   
    init(request: AWSS3TransferManagerDownloadRequest, userData: [String: AnyObject]?) {
        self.request = request
        self.key = request.key
        self.fileURL = nil
        self.userData = userData
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
    func onDownloadSuccess(fileURL: NSURL, userData: [String: AnyObject]?)
    
}

class S3ImageCache {
    
    class var sharedInstance: S3ImageCache {
        struct Singleton {
            static let instance = S3ImageCache()
        }
        return Singleton.instance
    }
    
    var caches = [String: ImageCache]()
    
    init() {
        let buckets = [ GGSetting.awsS3AvatarsBucketName, GGSetting.awsS3BucketName ]
        for bucket in buckets {
            self.caches[bucket] = ImageCache(name: "cache_\(bucket)")
        }
    }
    
    func isImageCachedForKey(key: String, bucket: String? = nil) -> Bool {
        var cache: ImageCache!
        if let bucketName = bucket {
            cache = self.caches[bucketName]
        } else {
            cache = KingfisherManager.sharedManager.cache
        }
        return cache.isImageCachedForKey(key).cached
    }
    
    func retrieveImageForKey(key: String, bucket: String, completion: ((image: UIImage?) -> Void)?) {
        if let cache = self.caches[bucket] {
            cache.retrieveImageForKey(key,
                options: KingfisherManager.DefaultOptions,
                completionHandler: { (image: UIImage?, cacheType: CacheType!) -> () in
                    if image == nil {
                        self.downloadImageForKey(key, bucket: bucket, completion: completion)
                    } else {
                        completion?(image: image)
                    }
            })
        } else {
            self.caches[bucket] = ImageCache(name: "cache_\(bucket)")
            self.downloadImageForKey(key, bucket: bucket, completion: completion)
        }
    }
    
    func storeImageForKey(key: String, bucket: String, image: UIImage) {
        if let cache = self.caches[bucket] {
            cache.storeImage(image, forKey: key)
        } else {
            let cache = ImageCache(name: "cache_\(bucket)")
            self.caches[bucket] = cache
            cache.storeImage(image, forKey: key)
        }
    }
    
    private func downloadImageForKey(key: String, bucket: String, completion: ((image: UIImage?) -> Void)?) {
        if key.hasPrefix("http") {
            if let data = NSData(contentsOfURL: NSURL(string: key)!), let cache = self.caches[bucket] {
                let webImage = UIImage(data: data)
                let squareImage = webImage?.gg_imageByCroppingToSquare()
                print("SQUARE \(squareImage!.size)")
                cache.storeImage(squareImage!, originalData: data, forKey: key)
                completion?(image: squareImage)
            }
        } else {
            AWSS3DownloadManager.sharedInstance.download(
                key,
                userData: nil,
                completion: { (fileURL: NSURL) -> Void in
                    let data: NSData = NSFileManager.defaultManager().contentsAtPath(fileURL.path!)!
                    let image = UIImage(data: data)
                    completion?(image: image)
                    if let cache = self.caches[bucket], let img = image {
                        cache.storeImage(img, originalData: data, forKey: key)
                    }
                },
                bucket: bucket
            )
        }
    }
}

class AWSS3DownloadManager {
   
    let tempFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("download")
    
    class var sharedInstance: AWSS3DownloadManager {
        struct Singleton {
            static let instance = AWSS3DownloadManager()
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
            print("Creating 'download' directory failed. Error: \(error)")
        }
    }
   
    var downloads = Array<S3Download?>()
    var delegate: S3DownloadDelegate?
   
    func download(fileName: String, userData: [String: AnyObject]?, completion: S3DownloadCompletion?, bucket: String = GGSetting.awsS3BucketName) {
        let fileURL = self.tempFolderURL.URLByAppendingPathComponent(fileName)
       
        /*
        let filePath = fileURL.path!
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            self.downloads.append(S3Download(fileURL: fileURL))
        } else {
        */
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.key = fileName
        downloadRequest.bucket = bucket
        downloadRequest.downloadingFileURL = fileURL
        
        self.downloads.append(S3Download(request: downloadRequest, userData: userData))
        self.download(downloadRequest, completion: completion)
    }

    func downloadSynchronous(fileName: String, userData: [String: AnyObject]? = nil) -> NSURL? {
        let fileURL = self.tempFolderURL.URLByAppendingPathComponent(fileName)
    
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.key = fileName
        downloadRequest.bucket = GGSetting.awsS3BucketName
        downloadRequest.downloadingFileURL = fileURL
        
        self.downloads.append(S3Download(request: downloadRequest, userData: userData))
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        let task = transferManager.download(downloadRequest)
       
        if task.error == nil && task.exception == nil && task.result != nil {
            print(task.result)
            if let index = self.indexOfDownloadRequest(downloadRequest) {
                self.downloads[index]!.onSuccess(downloadRequest.downloadingFileURL)
            }
            return downloadRequest.downloadingFileURL
        }
        return nil
    }
    
    func download(downloadRequest: AWSS3TransferManagerDownloadRequest,
        completion: S3DownloadCompletion?) {
            
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
                                downloadRequest.downloadingFileURL,
                                userData: self.downloads[index]!.userData
                            )
                            completion?(downloadRequest.downloadingFileURL)
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
   
    /*
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
    */
    
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
    
    func fileURLOfDownloadKey(downloadKey: String) -> NSURL? {
        for d in self.downloads {
            if d?.key == downloadKey {
                return d?.fileURL
            }
        }
        return nil
    }
}
