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

import Foundation

// MARK CredentialsPluginProtocol

/// A protocol that defines credentials plugin for authentication of 
/// incoming requests.
public protocol CredentialsPluginProtocol {
    /// The name of the plugin.
    var name: String { get }
    
    /// Caching of user profile information.
    var usersCache: NSCache<NSString, BaseCacheElement>? { get set }
    
    /// An indication whether the plugin is redirecting or not.
    /// Redirecting scheme is used for web session authentication, where the users, 
    /// that are not logged in, are redirected to a login page. All other types of 
    /// authentication are non-redirecting, i.e., unauthorized requests are rejected.
    var redirecting: Bool { get }
    
    /// Authenticate incoming request.
    ///
    /// - Parameter request: the `RouterRequest` object used to get inormation
    ///                     about the request.
    /// - Parameter response: the `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter options: a dictionary of plugin specific options.
    /// - Parameter onSuccess: a closure to invoke in case of successful authentication.
    /// - Parameter onFailure: a closure to invoke in case of authentication failure.
    /// - Parameter onPass: a closure to invoke when the plugin doesn't recognize the
    ///                     authentication data (usually authentication token) in the request.
    /// - Parameter inProgress: a closure to invoke in the process of redirecting authentication.
    func authenticate (request: RouterRequest, response: RouterResponse,
                       options: [String:Any], onSuccess: @escaping (UserProfile) -> Void,
                       onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       inProgress: @escaping () -> Void)
}
