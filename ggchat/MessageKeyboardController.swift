//
//  MessageKeyboardController.swift
//  ggchat
//
//  Created by Gary Chang on 11/18/15.
//  Copyright © 2015 Blub. All rights reserved.
//

import Foundation
import UIKit

protocol MessageKeyboardControllerDelegate {

    /**
     *  Tells the delegate that the keyboard frame has changed.
     *
     *  @param keyboardController The keyboard controller that is notifying the delegate.
     *  @param keyboardFrame      The new frame of the keyboard in the coordinate system of the `contextView`.
     */
    func keyboardController(keyboardController: MessageKeyboardController,
        keyboardDidChangeFrame keyboardFrame: CGRect)
}

class MessageKeyboardController: NSObject {

    static let kMessageKeyboardControllerNotificationKeyboardDidChangeFrame: String = "MessageKeyboardControllerNotificationKeyboardDidChangeFrame"
    static let kMessageKeyboardControllerUserInfoKeyKeyboardDidChangeFrame: String = "MessageKeyboardControllerUserInfoKeyKeyboardDidChangeFrame"

    static let kMessageKeyboardControllerKeyValueObservingContext: UnsafeMutablePointer<Void> = UnsafeMutablePointer<Void>()

    typealias AnimationCompletionBlock = (Bool) -> Void

    var gg_isObserving: Bool = true
    var textView: UITextView!
    var contextView: UIView!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var delegate: MessageKeyboardControllerDelegate!
    var keyboardTriggerPoint: CGPoint
    
    // pragma mark - Initialization
    /**
     *  Creates a new keyboard controller object with the specified textView, contextView, panGestureRecognizer, and delegate.
     *
     *  @param textView             The text view in which the user is editing with the system keyboard. This value must not be `nil`.
     *  @param contextView          The view in which the keyboard will be shown. This should be the parent or a sibling of `textView`. This value must not be `nil`.
     *  @param panGestureRecognizer The pan gesture recognizer responsible for handling user interaction with the system keyboard. This value must not be `nil`.
     *  @param delegate             The object that acts as the delegate of the keyboard controller.
     */
    
    init(
        textView: UITextView,
        contextView: UIView,
        panGestureRecognizer: UIPanGestureRecognizer,
        delegate: MessageKeyboardControllerDelegate) {
        self.textView = textView
        self.contextView = contextView
        self.panGestureRecognizer = panGestureRecognizer
        self.delegate = delegate
        self.gg_isObserving = false
        self.keyboardTriggerPoint = CGPointZero
    }

    // pragma mark - Setters
    var keyboardView: UIView? {
        willSet {
            if (self.keyboardView != nil) {
                self.gg_removeKeyboardFrameObserver()
            }
        }
        didSet {
            if (self.keyboardView != nil && !self.gg_isObserving) {
                self.keyboardView!.addObserver(
                    self,
                    forKeyPath: NSStringFromSelector(Selector("frame")),
                    options: NSKeyValueObservingOptions(rawValue:NSKeyValueObservingOptions.Old.rawValue | NSKeyValueObservingOptions.New.rawValue),
                    context: MessageKeyboardController.kMessageKeyboardControllerKeyValueObservingContext)

                self.gg_isObserving = true
            }
        }
    }

    // pragma mark - Getters

    var keyboardIsVisible: Bool {
        get {
            return self.keyboardView != nil
        }
    }

    func currentKeyboardFrame() -> CGRect {
        if (!self.keyboardIsVisible) {
            return CGRectNull
        }

        return self.keyboardView!.frame
    }

    // pragma mark - Keyboard controller
    
    func beginListeningForKeyboard() {
        if (self.textView.inputAccessoryView == nil) {
            self.textView.inputAccessoryView = UIView()
        }

        self.gg_registerForNotifications()
    }

    func endListeningForKeyboard() {
        self.gg_unregisterForNotifications()

        self.gg_setKeyboardViewHidden(false)
        self.keyboardView = nil
    }

    // pragma mark - Notifications

     private func gg_registerForNotifications() {
        self.gg_unregisterForNotifications()

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("gg_didReceiveKeyboardDidShowNotification:"),
            name: UIKeyboardDidShowNotification,
            object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("gg_didReceiveKeyboardWillChangeFrameNotification:"),
            name: UIKeyboardWillChangeFrameNotification,
            object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("gg_didReceiveKeyboardDidChangeFrameNotification:"),
            name: UIKeyboardDidChangeFrameNotification,
            object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("gg_didReceiveKeyboardDidHideNotification:"),
            name:UIKeyboardDidHideNotification,
            object:nil)
    }

     private func gg_unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

     private func gg_didReceiveKeyboardDidShowNotification(notification: NSNotification) {
        print("keyboard::didReceiveKeyboardDidShow")
        self.keyboardView = self.textView.inputAccessoryView!.superview
        self.gg_setKeyboardViewHidden(false)

        self.gg_handleKeyboardNotification(notification, completion: { (finished: Bool) in
            self.panGestureRecognizer.addTarget(self,
                action: Selector("gg_handlePanGestureRecognizer:"))
        })
    }

     private func gg_didReceiveKeyboardWillChangeFrameNotification(notification: NSNotification) {
        print("keyboard::didReceiveKeyboardWillChangeFrame")
        self.gg_handleKeyboardNotification(notification, completion:nil)
    }

     private func gg_didReceiveKeyboardDidChangeFrameNotification(notification: NSNotification) {
        print("keyboard::didReceiveKeyboardDidChangeFrame")
        self.gg_setKeyboardViewHidden(false)

        self.gg_handleKeyboardNotification(notification, completion: nil)
    }

     private func gg_didReceiveKeyboardDidHideNotification(notification: NSNotification) {
        print("keyboard::didReceiveKeyboardDidHide")
        self.keyboardView = nil

        self.gg_handleKeyboardNotification(notification, completion: { (finished: Bool) in
            self.panGestureRecognizer.removeTarget(self, action: nil)
        })
    }

     private func gg_handleKeyboardNotification(notification: NSNotification,
        completion: AnimationCompletionBlock?) {
        let userInfo: NSDictionary = notification.userInfo!

        let keyboardEndFrame: CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey]! as! NSValue).CGRectValue()

        if (CGRectIsNull(keyboardEndFrame)) {
            return
        }

        let animationCurve: Int = (userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber).integerValue
        let animationCurveOption = UIViewAnimationOptions(rawValue: UInt(animationCurve) << 16)

        let animationDuration: Double = (userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSNumber).doubleValue

        let keyboardEndFrameConverted: CGRect = self.contextView.convertRect(keyboardEndFrame, fromView:nil)

        UIView.animateWithDuration(
            animationDuration,
            delay:0.0,
            options: animationCurveOption,
            animations: {
                self.gg_notifyKeyboardFrameNotificationForFrame(keyboardEndFrameConverted)
            },
            completion: { (finished: Bool) in
                if (completion != nil) {
                    completion!(finished)
                }
            })
    }

    // pragma mark - Utilities

     private func gg_setKeyboardViewHidden(hidden: Bool) {
        if (self.keyboardView != nil) {
            self.keyboardView!.hidden = hidden
            self.keyboardView!.userInteractionEnabled = !hidden
        }
    }

     private func gg_notifyKeyboardFrameNotificationForFrame(frame: CGRect) {
        self.delegate.keyboardController(self, keyboardDidChangeFrame:frame)

        NSNotificationCenter.defaultCenter().postNotificationName(MessageKeyboardController.kMessageKeyboardControllerNotificationKeyboardDidChangeFrame,
            object: self,
            userInfo: [ MessageKeyboardController.kMessageKeyboardControllerUserInfoKeyKeyboardDidChangeFrame : NSValue(CGRect: frame)])
    }

     private func gg_resetKeyboardAndTextView() {
        self.gg_setKeyboardViewHidden(true)
        self.gg_removeKeyboardFrameObserver()
        self.textView.resignFirstResponder()
    }

    // pragma mark - Key-value observing

    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
        if (context == MessageKeyboardController.kMessageKeyboardControllerKeyValueObservingContext) {

            if (object === self.keyboardView && keyPath! == NSStringFromSelector(Selector("frame"))) {

                let oldKeyboardFrame: CGRect = change![NSKeyValueChangeOldKey]!.CGRectValue
                let newKeyboardFrame: CGRect = change![NSKeyValueChangeNewKey]!.CGRectValue

                if (CGRectEqualToRect(newKeyboardFrame, oldKeyboardFrame) || CGRectIsNull(newKeyboardFrame)) {
                    return
                }
                
                let keyboardEndFrameConverted: CGRect = self.contextView.convertRect(
                    newKeyboardFrame,
                    fromView: self.keyboardView!.superview)
                self.gg_notifyKeyboardFrameNotificationForFrame(keyboardEndFrameConverted)
            }
        }
    }

     private func gg_removeKeyboardFrameObserver() {
        if (!self.gg_isObserving) {
            return
        }

        self.keyboardView!.removeObserver(self,
            forKeyPath: NSStringFromSelector(Selector("frame")),
            context: MessageKeyboardController.kMessageKeyboardControllerKeyValueObservingContext)

        self.gg_isObserving = false
    }

    // pragma mark - Pan gesture recognizer

     private func gg_handlePanGestureRecognizer(pan: UIPanGestureRecognizer) {
        let touch: CGPoint = pan.locationInView(self.contextView.window)

        //  system keyboard is added to a new UIWindow, need to operate in window coordinates
        //  also, keyboard always slides from bottom of screen, not the bottom of a view
        var contextViewWindowHeight: CGFloat = CGRectGetHeight(self.contextView.window!.frame)

        if (UIDevice.gg_isCurrentDeviceBeforeiOS8()) {
            //  handle iOS 7 bug when rotating to landscape
            if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation)) {
                contextViewWindowHeight = CGRectGetWidth(self.contextView.window!.frame)
            }
        }

        let keyboardViewHeight: CGFloat = CGRectGetHeight(self.keyboardView!.frame)

        let dragThresholdY: CGFloat = (contextViewWindowHeight - keyboardViewHeight - self.keyboardTriggerPoint.y)

        var newKeyboardViewFrame = self.keyboardView!.frame

        let userIsDraggingNearThresholdForDismissing: Bool = (touch.y > dragThresholdY)

        self.keyboardView!.userInteractionEnabled = !userIsDraggingNearThresholdForDismissing

        switch (pan.state) {
            case UIGestureRecognizerState.Changed:
                newKeyboardViewFrame.origin.y = touch.y + self.keyboardTriggerPoint.y

                //  bound frame between bottom of view and height of keyboard
                newKeyboardViewFrame.origin.y = min(newKeyboardViewFrame.origin.y, contextViewWindowHeight)
                newKeyboardViewFrame.origin.y = max(newKeyboardViewFrame.origin.y, contextViewWindowHeight - keyboardViewHeight)

                if (CGRectGetMinY(newKeyboardViewFrame) == CGRectGetMinY(self.keyboardView!.frame)) {
                    return
                }

                UIView.animateWithDuration(0.0,
                    delay:0.0,
                    options: UIViewAnimationOptions(rawValue: UIViewAnimationOptions.BeginFromCurrentState.rawValue | UIViewAnimationOptions.TransitionNone.rawValue),
                    animations: {
                        self.keyboardView!.frame = newKeyboardViewFrame
                    },
                    completion: nil)
                break
            case UIGestureRecognizerState.Ended, UIGestureRecognizerState.Cancelled,UIGestureRecognizerState.Failed:
                let keyboardViewIsHidden: Bool = (CGRectGetMinY(self.keyboardView!.frame) >= contextViewWindowHeight)
                if (keyboardViewIsHidden) {
                    self.gg_resetKeyboardAndTextView()
                    return
                }

                let velocity: CGPoint = pan.velocityInView(self.contextView)
                let userIsScrollingDown: Bool = (velocity.y > 0.0)
                let shouldHide: Bool = (userIsScrollingDown && userIsDraggingNearThresholdForDismissing)

                newKeyboardViewFrame.origin.y = shouldHide ? contextViewWindowHeight : (contextViewWindowHeight - keyboardViewHeight)

                UIView.animateWithDuration(0.25,
                    delay:0.0,
                    options: UIViewAnimationOptions(rawValue: UIViewAnimationOptions.BeginFromCurrentState.rawValue | UIViewAnimationOptions.CurveEaseOut.rawValue),
                    animations: {
                        self.keyboardView!.frame = newKeyboardViewFrame
                    },
                    completion: { (Bool) in
                        self.keyboardView!.userInteractionEnabled = !shouldHide
                        if (shouldHide) {
                            self.gg_resetKeyboardAndTextView()
                        }
                    })
                break
            default:
                break
        }
    }
}