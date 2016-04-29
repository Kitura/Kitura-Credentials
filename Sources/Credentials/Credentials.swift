/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import KituraNet
import KituraSession
import LoggerAPI

import Foundation

import SwiftyJSON

public class Credentials : RouterMiddleware {
    
    var tokenPlugins = [CredentialsPluginProtocol]()
    var sessionPlugins = [String : CredentialsPluginProtocol]()
    public var options : [String:AnyObject]
    
    public convenience init () {
        self.init(options: [String:AnyObject]())
    }
    
    public init (options: [String:AnyObject]) {
        self.options = options
    }
    
    public func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        if let session = request.session  {
            if let _ = request.userProfile {
                next()
                return
            }
            else {
                let userProfile = session["userProfile"]
                if  userProfile.type != .Null  {
                    if let name = userProfile["displayName"].string,
                        let provider = userProfile["provider"].string,
                        let id = userProfile["id"].string {
                        request.userProfile = UserProfile(id: id, displayName: name, provider: provider)
                        next()
                        return
                    }
                }
            }
            
            session["returnTo"] = JSON(request.originalUrl ?? request.url)
            self.redirectUnauthorized(response)
            next()
        }
        else {
            var pluginIndex = -1
            
            // Extra variable to get around use of variable in its own initializer
            var callback: (()->Void)? = nil
            
            let callbackHandler = {[unowned request, unowned response, next] () -> Void in
                pluginIndex += 1
                if pluginIndex < self.tokenPlugins.count {
                    let plugin = self.tokenPlugins[pluginIndex]
                    plugin.authenticate(request: request, response: response, options: self.options,
                                        onSuccess: { userProfile in
                                            request.userProfile = userProfile
                                            next()
                        },
                                        onFailure: {
                                            self.redirectUnauthorized(response)
                                            next()
                        },
                                        onPass: {
                                            callback!()
                        },
                                        inProgress: {
                                            self.redirectUnauthorized(response)
                                            next()
                        }
                    )
                }
                else {
                    do {
                        try response.status(HttpStatusCode.UNAUTHORIZED).end()
                    }
                    catch {
                        Log.error("Failed to send response")
                    }
                    next()
                }
            }
            
            callback = callbackHandler
            callbackHandler()
        }
    }
    
    
    public func register (plugin: CredentialsPluginProtocol) {
        switch plugin.type {
        case .Token:
            tokenPlugins.append(plugin)
            tokenPlugins[tokenPlugins.count - 1].usersCache = NSCache()
        case .Session:
            sessionPlugins[plugin.name] = plugin
            sessionPlugins[plugin.name]!.usersCache = NSCache()
        }
    }

    private func redirectUnauthorized (_ response: RouterResponse, path: String?=nil) {
        let redirect : String?
        if let path = path {
            redirect = path
        }
        else {
            redirect = options["failureRedirect"] as? String
        }
        if let redirect = redirect {
            do {
                try response.redirect(redirect)
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
                Log.error("Failed to send response")
            }
        }
    }
    
    
    private func redirectAuthorized (_ response: RouterResponse, path: String?=nil) {
        let redirect : String?
        if let path = path {
            redirect = path
        }
        else {
            redirect = options["successRedirect"] as? String
        }
        if let redirect = redirect {
            do {
               try response.redirect(redirect)
            }
            catch {
                response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Failed to redirect successfuly authorized request"])
            }
        }
    }

    
    public func authenticate (credentialsType: String, successRedirect: String?=nil, failureRedirect: String?=nil) -> RouterHandler {
        return { request, response, next in
            if let plugin = self.sessionPlugins[credentialsType] {
                plugin.authenticate(request: request, response: response, options: self.options,
                                    onSuccess: { userProfile in
                                        if let session = request.session {
                                            var profile = [String:String]()
                                            profile["displayName"] = userProfile.displayName
                                            profile["provider"] = credentialsType
                                            profile["id"] = userProfile.id
                                            session["userProfile"] = JSON(profile)
                                        
                                            var redirect : String?
                                            if session["returnTo"].type != .Null  {
                                                redirect = session["returnTo"].stringValue
                                                session.remove(key: "returnTo")
                                            }
                                            self.redirectAuthorized(response, path: redirect ?? successRedirect)
                                            
                                        }
                                        next()
                    },
                                    onFailure: {
                                        self.redirectUnauthorized(response, path: failureRedirect)
                                        next()
                    },
                                    onPass: {
                                        self.redirectUnauthorized(response, path: failureRedirect)
                                        next()
                    },
                                    inProgress: {
                                        next()
                    }
                )
            }
            else {
                do {
                    try response.status(HttpStatusCode.UNAUTHORIZED).end()
                }
                catch {
                    Log.error("Failed to send response")
                }
                next()
            }
        }
    }
}


public enum CredentialsPluginType {
    case Token
    case Session
}


public protocol CredentialsPluginProtocol {
    var name: String { get }
#if os(OSX)
    var usersCache: NSCache<NSString, BaseCacheElement>? { get set }
#else
    var usersCache: NSCache? { get set }
#endif
    var type: CredentialsPluginType { get }
    
    func authenticate (request: RouterRequest, response: RouterResponse, options: [String:AnyObject], onSuccess: (UserProfile) -> Void, onFailure: () -> Void, onPass: () -> Void, inProgress: () -> Void)
}


public class BaseCacheElement {
    public var userProfile : UserProfile
    
    public init (profile: UserProfile) {
        userProfile = profile
    }
}
