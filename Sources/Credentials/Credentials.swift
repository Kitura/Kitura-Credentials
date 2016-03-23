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
import LoggerAPI

import Foundation

public class Credentials : RouterMiddleware {
    
    var plugins = [CredentialsPluginProtocol]()
    public var options : [String:AnyObject]
    
    public convenience init () {
        self.init(options: [String:AnyObject]())
    }
    
    public init (options: [String:AnyObject]) {
        self.options = options
    }
    
    public func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        var pluginIndex = -1
        
        // Extra variable to get around use of variable in its own initializer
        var callback: (()->Void)? = nil
        
        let callbackHandler = {[unowned request, unowned response, next] () -> Void in
            pluginIndex += 1
            if pluginIndex < self.plugins.count {
                let plugin = self.plugins[pluginIndex]
                plugin.authenticate(request, options: self.options,
                    onSuccess: { userProfile in
                        request.userInfo["profile"] = userProfile
                        next()
                    },
                    onFailure: {
                        if let redirect = self.options["failureRedirect"] as? String {
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
                                Log.error("Failed to send response")
                            }
                        }
                        next()
                    },
                    onPass: {
                        callback!()
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
    
    public func register (plugin: CredentialsPluginProtocol) {
        plugins.append(plugin)
        plugins[plugins.count - 1].usersCache = NSCache()
    }
    
}


public class UserProfile {
    public var id : String
    public var name : String
    
    public init (id: String, name: String) {
        self.id = id
        self.name = name
    }
}


public protocol CredentialsPluginProtocol {
    var name: String { get }
    var usersCache: NSCache? { get set }
    
    func authenticate (request: RouterRequest, options: [String:AnyObject], onSuccess: (UserProfile) -> Void, onFailure: () -> Void, onPass: () -> Void)
}


public class BaseCacheElement {
    public var userProfile : UserProfile
    
    public init (profile: UserProfile) {
        userProfile = profile
    }
}
