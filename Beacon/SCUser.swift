//
//  SCUser.swift
//  Hand Off Bluetooth Social Media App
//
//  Created by Jake Peterson on 9/30/14.
//  Copyright (c) 2014 Jake Peterson. All rights reserved.
//

import UIKit

var SCUserLoggedOutNotification = "SCUserLoggedOutNotification"
var SCCurrentUserKey = "com.beacon.current_user"

class SCUser: SCObject {
    
    var objectId:Int!
    var profileUrl:NSString?
    var invisibleAreas:NSArray?
    var defaultSCSocialType:NSString?
    var socialUrls:NSArray?
    
    init(json:NSDictionary!) {
        if json.allKeys.count == 0 {
            fatalError("Serious error in object serialization")
        }
        
        self.objectId = json.valueForKey("id") as? Int
        self.profileUrl = json.valueForKey("url") as? NSString
        self.invisibleAreas = json.valueForKey("invisible_areas") as? NSArray
        self.defaultSCSocialType = json.valueForKey("default_social_type") as? NSString
        
        super.init()
    }
    
    class var currentUser:SCUser? {
        set {
            if newValue?.isKindOfClass(SCUser) != nil {
                NSUserDefaults.standardUserDefaults().setObject(newValue?.json(SCUser), forKey: SCCurrentUserKey)
            } else {
                NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: SCCurrentUserKey)
            }
        }
        get {
            var userInfo:NSDictionary? = NSUserDefaults.standardUserDefaults().objectForKey(SCCurrentUserKey) as? NSDictionary
            if userInfo?.allKeys.count > 0 {
                return SCUser(json: userInfo)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(SCUserLoggedOutNotification, object: nil)
            }
            
            return nil
        }
    }
    
    class func getUserProfile(id:Int!, completionHandler:SCRequestResultsBlock) {
        let path = "users/\(String(id))"
        SCNetworking.shared.request(.GET, path: path, params: ["" : ""], completionHandler: { (responseObject, error) -> Void in
            if error != nil {
                completionHandler(responseObject: nil, error: error)
            } else {
                var user:SCUser? = nil
                if let response = responseObject as? NSDictionary {
                    user = SCUser(json: response["user"] as NSDictionary)
                    if user != nil {
                        self.currentUser = user
                    }
                }
                
                completionHandler(responseObject: user, error: nil)
            }
        })
    }
    
    class func delete(invisibleArea:SCInvisibleArea!, completionHandler:SCRequestResultsBlock) {
        if let user = self.currentUser {
            if let areas:NSMutableArray = user.invisibleAreas?.mutableCopy() as? NSMutableArray {
                areas.removeObject(invisibleArea)
            } else {
                fatalError("Serious error")
            }
            
            let path = "users/\(String(user.objectId))/"
            SCNetworking.shared.request(.DELETE, path: path, params: ["user" : user.json(SCUser)], completionHandler: { (responseObject, error) -> Void in
                if error != nil {
                    completionHandler(responseObject: nil, error: error)
                } else {
                    var user:SCUser? = nil
                    if let response = responseObject as? NSDictionary {
                        user = SCUser(json: response["user"] as NSDictionary)
                        if user != nil {
                            self.currentUser = user
                        }
                    }
                    
                    completionHandler(responseObject: user, error: nil)
                }
            })
        }
    }
    
    class func toggleBeacon(completionHandler:SCRequestResultsBlock) {
        var on:Bool = SCBeacon().beaconIsOn()
        if let user = self.currentUser {
            let path = "users/\(String(user.objectId))"
            SCNetworking.shared.request(.PUT, path: path, params: ["user" : ["beacon" : on]], completionHandler: { (responseObject, error) -> Void in
                if error != nil {
                    completionHandler(responseObject: nil, error: error)
                } else {
                    if let response = responseObject as? NSDictionary {
                        on = response["on"] as Bool
                        SCBeacon().updateBeaconState(on)
                    }
                    
                    completionHandler(responseObject: on, error: nil)
                }
            })
        }
    }
    
    class func changeDefaultSocial(type:SCSocialType, completionHandler:SCRequestResultsBlock) {
        if let user = self.currentUser {
            user.defaultSCSocialType = type.description()
            
            let path = "users/\(String(user.objectId))"
            SCNetworking.shared.request(.PUT, path: path, params: ["user" : user.json(SCUser)], completionHandler: { (responseObject, error) -> Void in
                if error != nil {
                    completionHandler(responseObject: nil, error: error)
                } else {
                    var user:SCUser? = nil
                    if let response = responseObject as? NSDictionary {
                        user = SCUser(json: response["user"] as NSDictionary)
                        if user != nil {
                            self.currentUser = user
                        }
                    }
                    
                    completionHandler(responseObject: user, error: nil)
                }
            })
        }
    }
    
    class func create(invisibleArea:SCInvisibleArea!, completionHandler:SCRequestResultsBlock) {
        SCNetworking.shared.request(.POST, path: "invisible_areas", params: ["invisible_area" : invisibleArea.json(SCUser)], completionHandler: { (responseObject, error) -> Void in
            if error != nil {
                completionHandler(responseObject: nil, error: error)
            } else {
                var user:SCUser? = nil
                if let response = responseObject as? NSDictionary {
                    user = SCUser(json: response["user"] as NSDictionary)
                    if user != nil {
                        self.currentUser = user
                    }
                }
                
                completionHandler(responseObject: user, error: nil)
            }
        })
    }
    
    class func update(type:SCSocialType!, link:NSString!, completionHandler:SCRequestResultsBlock) {
        if let user = SCUser.currentUser {
            SCNetworking.shared.request(.PUT, path: "users/\(user.objectId)/social", params: ["type" : type.description(), "link" : link]) { (responseObject, error) -> Void in
                if error != nil {
                    completionHandler(responseObject: nil, error: error)
                } else {
                    var user:SCUser? = nil
                    if let response = responseObject as? NSDictionary {
                        user = SCUser(json: response["user"] as NSDictionary)
                        if user != nil {
                            self.currentUser = user
                        }
                    }
                    
                    completionHandler(responseObject: user, error: nil)
                }
            }
        }
    }
   
    class func login(email:NSString, password:NSString, completionHandler:SCRequestResultsBlock) {
        SCNetworking.shared.request(.POST, path: "sessions", params: ["email" : email, "password" : password]) { (responseObject, error) -> Void in
            if error != nil {
                completionHandler(responseObject: nil, error: error)
            } else {
                var user:SCUser? = nil
                if let response = responseObject as? NSDictionary {
                    user = SCUser(json: response["user"] as NSDictionary)
                    if user != nil {
                        self.currentUser = user
                    }
                }
                
                completionHandler(responseObject: user, error: nil)
            }
        }
    }
    
    class func signUp(email:NSString, password:NSString, passwordConfirmation:NSString, completionHandler:SCRequestResultsBlock) {
        let params = ["email" : email, "password" : password, "password_confirmation" : passwordConfirmation]
        SCNetworking.shared.request(.POST, path: "registrations", params: ["user" : params]) { (responseObject, error) -> Void in
            if error != nil {
                completionHandler(responseObject: nil, error: nil)
            } else {
                var user:SCUser? = nil
                if let response = responseObject as? NSDictionary {
                    user = SCUser(json: response["user"] as NSDictionary)
                    if user != nil {
                        self.currentUser = user
                    }
                }
                
                completionHandler(responseObject: user, error: nil)
            }
        }
    }
    
    class func getUserState(email:NSString, completionHandler:SCRequestResultsBlock) {
        SCNetworking.shared.request(.GET, path: "email/new", params: ["email" : email]) { (responseObject, error) -> Void in
            if error != nil {
                completionHandler(responseObject: nil, error: error)
            } else {
                var response = responseObject as NSDictionary
                var state:NSNumber = response.objectForKey("state") as NSNumber
                completionHandler(responseObject: state, error: nil)
            }
        }
    }
}
