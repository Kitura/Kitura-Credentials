//
//  Credentials.swift
//  Credentials
//
//  Created by Ira Rosen on 20/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import sys
import net
import io
import router

import Foundation

public class Credentials {
    
    var plugins = [CredentialsType : CredentialsPluginProtocol]()
    
    var usersCache = NSCache()
    
    public init() {}
    
    public func authenticate (credentialsType: CredentialsType, options: [String:AnyObject]) -> RouterHandler {
        return { (request: RouterRequest, response: RouterResponse, next: ()->Void) in
            if let plugin = self.plugins[credentialsType] {
                plugin.authenticate(request, options: options, usersCache: self.usersCache.objectForKey(credentialsType.rawValue) as? NSCache) { userProfile in
                    if let userProfile = userProfile {
                        request.userInfo["profile"] = userProfile
                        next()
                    }
                    else {
                        if let redirect = options["failureRedirect"] as? String {
                            do {
                                try response.redirect(HttpStatusCode.UNAUTHORIZED, path: redirect)
                            }
                            catch {
                                response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Failed to redirect unauthorized request"])
                            }
                        }
                        else {
                            do {
                                try response.status(HttpStatusCode.UNAUTHORIZED).end()
                            }
                            catch {
                                response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                            }

                        }
                        next()
                    }
                }
            }
            else {
                do {
                    try response.status(HttpStatusCode.UNAUTHORIZED).end()
                }
                catch {
                    response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Internal error"])
                }
            }
        }
    }
    
    public func register (credentialsType: CredentialsType, plugin: CredentialsPluginProtocol) {
        plugins[credentialsType] = plugin
        usersCache.setValue(NSCache(), forKey: credentialsType.rawValue)
    }
}


public enum CredentialsType : String {
    case FacebookToken
}


public class UserProfile {
    public var id = ""
    public var firstName = ""
    public var lastName = ""
}


public protocol CredentialsPluginProtocol {
    func authenticate (request: RouterRequest, options: [String:AnyObject], usersCache: NSCache?, callback: (UserProfile?) -> Void)
}


class BaseCacheElement {
    var userProfile : UserProfile
    var ttl : Int
    
    init (profile: UserProfile) {
        userProfile = profile
        ttl = 10 // TODO
    }
}