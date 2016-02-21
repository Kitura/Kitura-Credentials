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

import KituraRouter
import KituraNet
import KituraSys

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
