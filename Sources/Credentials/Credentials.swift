//
//  Credentials.swift
//  Credentials
//
//  Created by Ira Rosen on 20/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import sys
import net
import router

import Foundation

public class Credentials {
    
    var plugins = [String : CredentialsPluginProtocol]()
    
    public init() {}
    
    public func authenticate (credentialsType: String, options: [String:AnyObject]) -> RouterHandler {
        return { request, response, next in
            if let plugin = self.plugins[credentialsType] {
               plugin.authenticate(request, options: options) { userProfile in
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
    
    public func register (plugin: CredentialsPluginProtocol) {
        // TODO: Configure cache
        plugins[plugin.name] = plugin
        plugins[plugin.name]!.usersCache = NSCache()
    }
}


public class UserProfile {
    public var id : String
    public var firstName : String
    public var lastName : String
    
    public init (id: String, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}


public protocol CredentialsPluginProtocol {
    var name: String { get }
    var usersCache: NSCache? { get set }
    
    func authenticate (request: RouterRequest, options: [String:AnyObject], callback: (UserProfile?) -> Void)
}


public class BaseCacheElement {
    public var userProfile : UserProfile
    public var ttl : Int
    
    public init (profile: UserProfile) {
        userProfile = profile
        ttl = 10 // TODO
    }
}