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
    
    /// The dictionary of options to pass to the plugins.
    public var options: [String:Any]
    
    /// Initialize a `Credentials` instance.
    public convenience init () {
        self.init(options: [String:Any]())
    }
    
    /// Initialize a `Credentials` instance.
    ///
    /// - Parameter options: The dictionary of options to pass to the plugins.
    public init (options: [String:Any]) {
        self.options = options
    }
    
    /// Handle an incoming request: authenticate the request using the registered plugins.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter next: The closure to invoke to enable the Router to check for
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
                    Log.error("The authentication failed either because the authentication data was not recognized by any non-redirecting plugin, or because a session, required by redirecting authentication, was not configured.")
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
    /// - Parameter plugin: An implementation of `CredentialsPluginProtocol`. The credentials
    ///                 framework invokes registered plugins to authenticate incoming requests.
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
    
    /// Create a `RouterHandler` that invokes the specific redirecting plugin to authenticate incoming requests.
    ///
    /// - Parameter credentialsType: The name of a registered redirecting plugin that will be used for request authentication.
    /// - Parameter successRedirect: The path to redirect to if the authentication is successful.
    /// - Parameter failureRedirect: The path to redirect to if the authentication failed.
    /// - Returns: A `RouterHandler` for request authentication.
    public func authenticate (credentialsType: String, successRedirect: String?=nil, failureRedirect: String?=nil) -> RouterHandler {
        return { request, response, next in
            if let session = request.session {
                if let plugin = self.redirectingPlugins[credentialsType] {
                    plugin.authenticate(request: request, response: response, options: self.options,
                                        onSuccess: { userProfile in
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
            else {
                let error = "The server was not configured properly: no session found for redirecting authentication"
                Log.error(error)
                #if os(Linux)
                    response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
                #else
                    response.error = NSError(domain: "Credentials", code: 1, userInfo: [NSLocalizedDescriptionKey as NSString: error])
                #endif
            }
        }
    }
    
    /// Delete the user profile information from the session and the request.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    public func logOut (request: RouterRequest) {
        if let session = request.session  {
            request.userProfile = nil
            session.remove(key: "userProfile")
        }
    }
}
