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

// MARK Credentials

/// A pluggable framework for validating user credentials.
public class Credentials : RouterMiddleware {
    var nonRedirectingPlugins = [CredentialsPluginProtocol]()
    var redirectingPlugins = [String : CredentialsPluginProtocol]()
    
    /// A dictionary of options passed to the plugins.
    public var options : [String:Any]
    
    /// Initialize a `Credentials`.
    ///
    /// - Returns: a `Credentials` instance.
    public convenience init () {
        self.init(options: [String:Any]())
    }
    
    /// Initialize a `Credentials`.
    ///
    /// - Parameter options: a dictionary of options to pass to the plugins.
    /// - Returns: a `Credentials `instance.
    public init (options: [String:Any]) {
        self.options = options
    }
    
    /// Handle an incoming request: authenticate the request using registered plugins.
    ///
    /// - Parameter request: the `RouterRequest` object used to get inormation
    ///                     about the request.
    /// - Parameter response: the `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter next: the closure to invoke to enable the Router to check for
    ///                  other handlers or middleware to work with this request.
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        if let session = request.session  {
            if let _ = request.userProfile {
                next()
                return
            }
            else {
                let userProfile = session["userProfile"]
                if  userProfile.type != .null  {
                    if let name = userProfile["displayName"].string,
                        let provider = userProfile["provider"].string,
                        let id = userProfile["id"].string {
                        request.userProfile = UserProfile(id: id, displayName: name, provider: provider)
                        next()
                        return
                    }
                }
            }
        }

        var pluginIndex = -1
        var passStatus : HTTPStatusCode?
        var passHeaders : [String:String]?
        
        // Extra variable to get around use of variable in its own initializer
        var callback: (()->Void)? = nil
        
        let callbackHandler = {[unowned request, unowned response, next] () -> Void in
            pluginIndex += 1
            if pluginIndex < self.nonRedirectingPlugins.count {
                let plugin = self.nonRedirectingPlugins[pluginIndex]
                plugin.authenticate(request: request, response: response, options: self.options,
                                    onSuccess: { userProfile in
                                        request.userProfile = userProfile
                                        next()
                    },
                                    onFailure: { status, headers in
                                        self.fail(response: response, status: status, headers: headers)
                    },
                                    onPass: { status, headers in
                                        // First pass parameters are saved
                                        if let status = status, passStatus == nil {
                                            passStatus = status
                                            passHeaders = headers
                                        }
                                        callback!()
                    },
                                    inProgress: {
                                        self.redirectUnauthorized(response: response)
                                        next()
                    }
                )
            }
            else {
                // All the plugins passed
                if let session = request.session, !self.redirectingPlugins.isEmpty {
                    session["returnTo"] = JSON(request.originalURL)
                    self.redirectUnauthorized(response: response)
                }
                else {
                    self.fail(response: response, status: passStatus, headers: passHeaders)
                }
            }
        }
        
        callback = callbackHandler
        callbackHandler()
    }
    
    private func fail (response: RouterResponse, status: HTTPStatusCode?, headers: [String:String]?) {
        let responseStatus = status ?? .unauthorized
        if let headers = headers {
            for (key, value) in headers {
                response.headers.append(key, value: value)
            }
        }
        do {
            try response.status(responseStatus).end()
        }
        catch {
            Log.error("Failed to send response")
        }
    }

    /// Register a plugin implementing `CredentialsPluginProtocol`.
    ///
    /// - Parameter plugin: an implementation of `CredentialsPluginProtocol`. Credentials
    ///                 framework calls registered plugins to authenticate incoming requests.
    public func register (plugin: CredentialsPluginProtocol) {
        if plugin.redirecting {
            redirectingPlugins[plugin.name] = plugin
        }
        else {
            nonRedirectingPlugins.append(plugin)
            nonRedirectingPlugins[nonRedirectingPlugins.count - 1].usersCache = NSCache()
        }
    }
    
    private func redirectUnauthorized (response: RouterResponse, path: String?=nil) {
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
#if os(Linux)
                response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Failed to redirect unauthorized request"])
#else
                response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey as NSString:"Failed to redirect unauthorized request"])
#endif
            }
        }
        else {
            do {
                try response.status(.unauthorized).end()
            }
            catch {
                Log.error("Failed to send response")
            }
        }
    }

    private func redirectAuthorized (response: RouterResponse, path: String?=nil) {
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
#if os(Linux)
                    response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey:"Failed to redirect successfuly authorized request"])
#else
                    response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey as NSString:"Failed to redirect successfuly authorized request"])
#endif
            }
        }
    }

    /// Create a `RouterHandler` that calls the specific redirecting plugin to authenticate incoming requests.
    ///
    /// - Parameter credentialsType: a name of registered redirecting plugin that will be used for request authentication.
    /// - Parameter successRedirect: a path to redirect to in case of successful authentication.
    /// - Parameter failureRedirect: a path to redirect to in the case that the authentication failed.
    /// - Returns: a `RouterHandler` for request authentication.
    public func authenticate (credentialsType: String, successRedirect: String?=nil, failureRedirect: String?=nil) -> RouterHandler {
        return { request, response, next in
            if let plugin = self.redirectingPlugins[credentialsType] {
                plugin.authenticate(request: request, response: response, options: self.options,
                                    onSuccess: { userProfile in
                                        if let session = request.session {
                                            var profile = [String:String]()
                                            profile["displayName"] = userProfile.displayName
                                            profile["provider"] = credentialsType
                                            profile["id"] = userProfile.id
                                            session["userProfile"] = JSON(profile)
                                        
                                            var redirect : String?
                                            if session["returnTo"].type != .null  {
                                                redirect = session["returnTo"].stringValue
                                                session.remove(key: "returnTo")
                                            }
                                            self.redirectAuthorized(response: response, path: redirect ?? successRedirect)
                                            
                                        }
                                        next()
                    },
                                    onFailure: { _, _ in
                                        self.redirectUnauthorized(response: response, path: failureRedirect)
                    },
                                    onPass: { _, _ in
                                        self.redirectUnauthorized(response: response, path: failureRedirect)
                    },
                                    inProgress: {
                                        next()
                    }
                )
            }
            else {
                do {
                    try response.status(.unauthorized).end()
                }
                catch {
                    Log.error("Failed to send response")
                }
                next()
            }
        }
    }
    
    /// Delete user profile info from session and request.
    ///
    /// - Parameter request: the `RouterRequest` object used to get inormation
    ///                     about the request.
    public func logOut (request: RouterRequest) {
        if let session = request.session  {
            request.userProfile = nil
            session.remove(key: "userProfile")
        }
    }
}
