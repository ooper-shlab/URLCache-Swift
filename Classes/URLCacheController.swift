//
//  URLCacheController.swift
//  URLCache
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/8/17.
//
//
/*

 File: URLCacheController.h
 File: URLCacheController.m
 Abstract: The view controller for the URLCache sample.

 Version: 1.1

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2008-2010 Apple Inc. All Rights Reserved.

 */

import UIKit

class URLCacheController: UIViewController, URLCacheConnectionDelegate, UIAlertViewDelegate {
    
    var dataPath: String!
    var filePath: String?
    var fileDate: NSDate?
    var urlArray: [NSURL] = []
    var connection: URLCacheConnection?
    
    /* outlets */
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var statusField: UILabel!
    @IBOutlet var dateField: UILabel!
    @IBOutlet var infoField: UILabel!
    @IBOutlet var toolbarItem1: UIBarButtonItem!
    @IBOutlet var toolbarItem2: UIBarButtonItem!
    
    
    /* cache update interval in seconds */
    private let URLCacheInterval = 86400.0
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        /* By default, the Cocoa URL loading system uses a small shared memory cache.
        We don't need this cache, so we set it to zero when the application launches. */
        
        /* turn off the NSURLCache shared cache */
        
        let sharedCache = NSURLCache(memoryCapacity: 0,
            diskCapacity: 0,
            diskPath: nil)
        NSURLCache.setSharedURLCache(sharedCache)
        
        /* prepare to use our own on-disk cache */
        self.initCache()
        
        /* create and load the URL array using the strings stored in URLCache.plist */
        
        //URL contained in the original URLCache.plist:
        //http://www.osei.noaa.gov/IOD/OSEIiod.jpg
        if let url = NSBundle.mainBundle().URLForResource("URLCache", withExtension: "plist") {
            let array = NSArray(contentsOfURL: url)!
            self.urlArray = array.map {element in NSURL(string: element as! String)!}
        }
        
        /* set the view's background to gray pinstripe */
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        /* set initial state of network activity indicators */
        self.stopAnimation()
        
        /* initialize the user interface */
        self.initUI()
    }
    
    
    /*
    ------------------------------------------------------------------------
    Action methods that respond to UI events or change the UI
    ------------------------------------------------------------------------
    */
    
    //MARK: -
    //MARK: IBAction methods
    
    /* Action method for the Display Image button. */
    
    @IBAction func onDisplayImage(_: AnyObject) {
        self.initUI()
        self.displayImageWithURL(urlArray[0])
    }
    
    
    /* Action method for the Clear Cache button. */
    
    @IBAction func onClearCache(_: AnyObject) {
        let message = NSLocalizedString("Do you really want to clear the cache?",
            comment: "Clear Cache alert message")
        
        URLCacheAlertWithMessageAndDelegate(message, self)
        
        /* We handle the user response to this alert in the UIAlertViewDelegate
        method alertView:clickedButtonAtIndex: at the end of this file. */
    }
    
    
    /*
    ------------------------------------------------------------------------
    Private methods used only in this file
    ------------------------------------------------------------------------
    */
    
    //MARK: -
    //MARK: Private methods
    
    /* initialize fields in the user interface */
    
    private func initUI() {
        imageView.image = nil
        statusField.text = ""
        dateField.text = ""
        infoField.text = ""
    }
    
    
    /* show the user that loading activity has started */
    
    private func startAnimation() {
        self.activityIndicator.startAnimating()
        let application = UIApplication.sharedApplication()
        application.networkActivityIndicatorVisible = true
    }
    
    
    /* show the user that loading activity has stopped */
    
    private func stopAnimation() {
        self.activityIndicator.stopAnimating()
        let application = UIApplication.sharedApplication()
        application.networkActivityIndicatorVisible = false
    }
    
    
    /* enable or disable all toolbar buttons */
    
    private func buttonsEnabled(flag: Bool) {
        toolbarItem1.enabled = flag
        toolbarItem2.enabled = flag
    }
    
    
    private func initCache() {
        /* create path to cache directory inside the application's Documents directory */
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        self.dataPath = (paths[0] as NSString).stringByAppendingPathComponent("URLCache")
        
        /* check for existence of cache directory */
        if NSFileManager.defaultManager().fileExistsAtPath(dataPath) {
            return
        }
        
        /* create a new cache directory */
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(dataPath,
                withIntermediateDirectories: false,
                attributes: nil)
        } catch let error as NSError {
            URLCacheAlertWithError(error)
            return
        }
    }
    
    
    /* removes every file in the cache directory */
    
    private func clearCache() {
        /* remove the cache directory and its contents */
        do {
            try NSFileManager.defaultManager().removeItemAtPath(dataPath)
        } catch let error as NSError {
            URLCacheAlertWithError(error)
            return
        }
        
        /* create a new cache directory */
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(dataPath,
                withIntermediateDirectories: false,
                attributes: nil)
        } catch let error as NSError {
            URLCacheAlertWithError(error)
            return
        }
        
        self.initUI()
    }
    
    
    /* get modification date of the current cached image */
    
    private func getFileModificationDate() {
        /* default date if file doesn't exist (not an error) */
        guard let filePath = self.filePath else {return}
        self.fileDate = NSDate(timeIntervalSinceReferenceDate: 0)
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            /* retrieve file attributes */
            do {
                let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
                self.fileDate = (attributes as NSDictionary).fileModificationDate()
            } catch let error as NSError {
                URLCacheAlertWithError(error)
            }
        }
    }
    
    
    /* display new or existing cached image */
    
    private func displayImageWithURL(theURL: NSURL) {
        /* get the path to the cached image */
        
        let fileName = theURL.lastPathComponent!
        filePath = (dataPath as NSString).stringByAppendingPathComponent(fileName)
        
        /* apply daily time interval policy */
        
        /* In this program, "update" means to check the last modified date
        of the image to see if we need to load a new version. */
        
        self.getFileModificationDate()
        /* get the elapsed time since last file update */
        let time = abs(fileDate!.timeIntervalSinceNow)
        if time > URLCacheInterval {
            /* file doesn't exist or hasn't been updated for at least one day */
            self.initUI()
            self.buttonsEnabled(false)
            self.startAnimation()
            self.connection = URLCacheConnection(URL: theURL, delegate: self)
        } else {
            statusField.text = NSLocalizedString ("Previously cached image",
                comment: "Image found in cache and updated in last 24 hours.")
            self.displayCachedImage()
        }
    }
    
    
    /* display existing cached image */
    
    private func displayCachedImage() {
        infoField.text = NSLocalizedString("The cached image is updated if 24 hours has elapsed since the last update and you press the Display Image button.", comment: "Information about updates.")
        
        /* retrieve file attributes */
        
        self.getFileModificationDate()
        
        /* format the file modification date for display in Updated field */
        /* NSDateFormatterStyle options give meaningful results in all locales */
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateStyle = .MediumStyle
        dateField.text = "Updated: \(dateFormatter.stringFromDate(fileDate!))"
        
        /* display the file as an image */
        
        if let theImage = UIImage(contentsOfFile: filePath!) {
            imageView.image = theImage
        }
    }
    
    
    /*
    ------------------------------------------------------------------------
    URLCacheConnectionDelegate protocol methods
    ------------------------------------------------------------------------
    */
    
    //MARK: -
    //MARK: URLCacheConnectionDelegate methods
    
    func connectionDidFail(theConnection: URLCacheConnection) {
        self.stopAnimation()
        self.buttonsEnabled(true)
    }
    
    
    func connectionDidFinish(theConnection: URLCacheConnection) {
        if NSFileManager.defaultManager().fileExistsAtPath(filePath!) {
            
            /* apply the modified date policy */
            
            self.getFileModificationDate()
            let result = theConnection.lastModified!.compare(fileDate!)
            if result == .OrderedDescending {
                /* file is outdated, so remove it */
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath!)
                } catch let error as NSError {
                    URLCacheAlertWithError(error)
                }
                
            }
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(filePath!) {
            /* file doesn't exist, so create it */
            NSFileManager.defaultManager().createFileAtPath(filePath!,
                contents: theConnection.receivedData,
                attributes: nil)
            
            statusField.text = NSLocalizedString("Newly cached image",
                comment: "Image not found in cache or new image available.")
        } else {
            statusField.text = NSLocalizedString("Cached image is up to date",
                comment: "Image updated and no new image available.")
        }
        
        /* reset the file's modification date to indicate that the URL has been checked */
        
        let dict: [String: AnyObject] = [NSFileModificationDate : NSDate()]
        do {
            try NSFileManager.defaultManager().setAttributes(dict, ofItemAtPath: filePath!)
        } catch let error as NSError {
            URLCacheAlertWithError(error)
        }
        
        self.stopAnimation()
        self.buttonsEnabled(true)
        self.displayCachedImage()
    }
    
    /*
    ------------------------------------------------------------------------
    UIAlertViewDelegate protocol method
    ------------------------------------------------------------------------
    */
    
    //MARK: -
    //MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            /* the user clicked the Cancel button */
            return
        }
        
        self.clearCache()
    }
    
}
@available(iOS 8.0, *)
extension URLCacheController: UIAlertControllerDelegate {
    func alertController(alertController: UIAlertController, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            return
        }
        self.clearCache()
    }
}