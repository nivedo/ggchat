//
//  LocationMediaItem.swift
//  ggchat
//
//  Created by Gary Chang on 11/19/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

typealias LocationMediaItemCompletionBlock = (Void) -> Void

class LocationMediaItem: MediaItem {

    var cachedMapSnapshotImage: UIImage?
    var cachedMapImageView: UIImageView?
    var location_: CLLocation?
    
    // pragma mark - Initialization

    init(location: CLLocation) {
        super.init()
        self.setLocation(location, withCompletionHandler: nil)
    }

    override func clearCachedMediaViews() {
        super.clearCachedMediaViews()
        self.cachedMapImageView = nil
    }

    // pragma mark - Setters

    override var appliesMediaViewMaskAsOutgoing: Bool {
        didSet {
            self.cachedMapSnapshotImage = nil
            self.cachedMapImageView = nil
        }
    }

    // pragma mark - Map snapshot

    func setLocation(location: CLLocation) {
        self.setLocation(location, withCompletionHandler: nil)
    }

    func setLocation(location: CLLocation, withCompletionHandler completion:LocationMediaItemCompletionBlock?) {
        self.setLocation(
            location,
            region: MKCoordinateRegionMakeWithDistance(location.coordinate, 500.0, 500.0),
            withCompletionHandler: completion)
    }

    func setLocation(
        location: CLLocation,
        region: MKCoordinateRegion,
        withCompletionHandler completion: LocationMediaItemCompletionBlock?) {
        self.location_ = (location.copy() as! CLLocation)
        self.cachedMapSnapshotImage = nil
        self.cachedMapImageView = nil
    
        if (self.location_ == nil) {
            return
        }
            
        self.createMapViewSnapshotForLocation(self.location_!,
            coordinateRegion: region,
            withCompletionHandler: completion)
    }

    func createMapViewSnapshotForLocation(location: CLLocation,
        coordinateRegion region: MKCoordinateRegion,
        withCompletionHandler completion: LocationMediaItemCompletionBlock?) {
        
        let options: MKMapSnapshotOptions = MKMapSnapshotOptions()
        options.region = region
        options.size = self.mediaViewDisplaySize()
        options.scale = UIScreen.mainScreen().scale
        
        let snapShotter: MKMapSnapshotter = MKMapSnapshotter(options: options)
        /*
        snapShotter.startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                  completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
                      if (error) {
                          NSLog(@"%s Error creating map snapshot: %@", _PRETTY_FUNCTION_, error)
                          return
                      }
                      
                      MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:nil]
                      CGPoint coordinatePoint = [snapshot pointForCoordinate:location.coordinate]
                      UIImage *image = snapshot.image
                      
                      coordinatePoint.x += pin.centerOffset.x - (CGRectGetWidth(pin.bounds) / 2.0)
                      coordinatePoint.y += pin.centerOffset.y - (CGRectGetHeight(pin.bounds) / 2.0)
                      
                      UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale)
                      {
                          [image drawAtPoint:CGPointZero]
                          [pin.image drawAtPoint:coordinatePoint]
                          self.cachedMapSnapshotImage = UIGraphicsGetImageFromCurrentImageContext()
                      }
                      UIGraphicsEndImageContext()
                      
                      if (completion) {
                          dispatch_async(dispatch_get_main_queue(), completion)
                      }
                  }]
        */
    }

    // pragma mark - MKAnnotation

    var coordinate: CLLocationCoordinate2D {
        return self.location_!.coordinate
    }

    // pragma mark - MessageMediaData protocol

    override func mediaView() -> UIView? {
        if (self.location_ == nil || self.cachedMapSnapshotImage == nil) {
            return nil
        }
        
        if (self.cachedMapImageView == nil) {
            let imageView: UIImageView = UIImageView(image: self.cachedMapSnapshotImage)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            MessageMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(
                imageView,
                isOutgoing: self.appliesMediaViewMaskAsOutgoing)
            self.cachedMapImageView = imageView
        }
        
        return self.cachedMapImageView
    }

    // pragma mark - NSObject

    override func isEqual(_ object: AnyObject?) -> Bool {
        if (!super.isEqual(object)) {
            return false
        }
        
        let locationItem: LocationMediaItem = object as! LocationMediaItem
        
        return self.location_!.isEqual(locationItem.location_)
    }

    override var hash: Int {
        return super.hash ^ self.location_!.hash
    }

    override var description: String {
        return "<\(self.dynamicType): location=\(self.location_), appliesMediaViewMaskAsOutgoing=\(self.appliesMediaViewMaskAsOutgoing)>"
    }

    // pragma mark - NSCoding

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let location: CLLocation = aDecoder.decodeObjectForKey(NSStringFromSelector(Selector("location"))) as! CLLocation
        self.setLocation(location, withCompletionHandler: nil)
    }

    required override init() {
        super.init()
    }

    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.location_,
            forKey: NSStringFromSelector(Selector("location")))
    }

    // pragma mark - NSCopying

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: LocationMediaItem = LocationMediaItem(location: self.location_!)
        copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing
        return copy
    }
}