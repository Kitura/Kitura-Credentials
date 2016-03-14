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
                                Log.error("Failed to send response")
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
                    Log.error("Failed to send response")
                }
            }
            next()
        }
    }
    
    public func register (plugin: CredentialsPluginProtocol) {
        plugins[plugin.name] = plugin
        plugins[plugin.name]!.usersCache = NSCache()
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
    
    func authenticate (request: RouterRequest, options: [String:AnyObject], callback: (UserProfile?) -> Void)
}


public class BaseCacheElement {
    public var userProfile : UserProfile
    
    public init (profile: UserProfile) {
        userProfile = profile
    }
}
