//
//  URLCacheConnection.swift
//  URLCache
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/8/17.
//
//
/*

File: URLCacheConnection.h
File: URLCacheConnection.m
Abstract: The NSURL connection class for the URLCache sample.

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

let NSURLResponseUnknownLength = Int64(-1)


@objc(URLCacheConnectionDelegate)
protocol URLCacheConnectionDelegate: NSObjectProtocol {
    
    func connectionDidFail(theConnection: URLCacheConnection)
    func connectionDidFinish(theConnection: URLCacheConnection)
    
}


@objc(URLCacheConnection)
class URLCacheConnection: NSObject, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    weak var delegate: URLCacheConnectionDelegate!
    var receivedData: NSMutableData?
    var lastModified: NSDate?
    var connection: NSURLConnection!
    
    
    /* This method initiates the load request. The connection is asynchronous,
    and we implement a set of delegate methods that act as callbacks during
    the load. */
    
    init(URL theURL: NSURL, delegate theDelegate: URLCacheConnectionDelegate) {
        
        self.delegate = theDelegate
        super.init()
        
        /* Create the request. This application does not use a NSURLCache
        disk or memory cache, so our cache policy is to satisfy the request
        by loading the data from its source. */
        
        let theRequest = NSURLRequest(URL: theURL,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 60)
        
        /* Create the connection with the request and start loading the
        data. The connection object is owned both by the creator and the
        loading system. */
        
        self.connection = NSURLConnection(request: theRequest, delegate: self)
        if self.connection == nil {
            /* inform the user that the connection failed */
            let message = NSLocalizedString ("Unable to initiate request.",
                comment: "NSURLConnection initialization method failed.")
            URLCacheAlertWithMessage(message)
        }
        
    }
    
    
    //MARK: NSURLConnection delegate methods
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        /* This method is called when the server has determined that it has
        enough information to create the NSURLResponse. It can be called
        multiple times, for example in the case of a redirect, so each time
        we reset the data capacity. */
        
        /* create the NSMutableData instance that will hold the received data */
        
        var contentLength = response.expectedContentLength
        if contentLength == NSURLResponseUnknownLength {
            contentLength = 500000
        }
        self.receivedData = NSMutableData(capacity: Int(contentLength))
        
        /* Try to retrieve last modified date from HTTP header. If found, format
        date so it matches format of cached image file modification date. */
        
        if let response = response as? NSHTTPURLResponse {
            let headers = response.allHeaderFields
            if let modified = headers["Last-Modified"] as! String? {
                let dateFormatter = NSDateFormatter()
                
                /* avoid problem if the user's locale is incompatible with HTTP-style dates */
                dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                
                dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                self.lastModified = dateFormatter.dateFromString(modified)
            } else {
                /* default if last modified date doesn't exist (not an error) */
                self.lastModified = NSDate(timeIntervalSinceReferenceDate: 0)
            }
        }
    }
    
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        /* Append the new data to the received data. */
        self.receivedData?.appendData(data)
    }
    
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        URLCacheAlertWithError(error)
        self.delegate.connectionDidFail(self)
    }
    
    
    func connection(connection: NSURLConnection, willCacheResponse cachedResponse: NSCachedURLResponse) -> NSCachedURLResponse? {
        /* this application does not use a NSURLCache disk or memory cache */
        return nil
    }
    
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.delegate.connectionDidFinish(self)
    }
    
    
}