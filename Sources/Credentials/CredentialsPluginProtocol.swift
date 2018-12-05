/**
 * Copyright IBM Corporation 2016, 2017
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

/// The protocol that defines the API for `Credentials` plugins for authentication of
/// incoming requests.
public protocol CredentialsPluginProtocol {

    /// The name of the plugin.
    var name: String { get }
    
    /// User profile cache.
    var usersCache: NSCache<NSString, BaseCacheElement>? { get set }
    
    /// An indication as to whether the plugin is redirecting or not.
    /// The redirecting scheme is used for web session authentication, where the users,
    /// that are not logged in, are redirected to a login page. All other types of 
    /// authentication are non-redirecting, i.e., unauthorized requests are rejected.
    var redirecting: Bool { get }
    
    /// Authenticate an incoming request.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter options: The dictionary of plugin specific options.
    /// - Parameter onSuccess: The closure to invoke in the case of successful authentication.
    /// - Parameter onFailure: The closure to invoke in the case of an authentication failure.
    /// - Parameter onPass: The closure to invoke when the plugin doesn't recognize the
    ///                     authentication data (usually an authentication token) in the request.
    /// - Parameter inProgress: The closure to invoke to cause a redirect to the login page in the
    ///                     case of redirecting authentication.
    func authenticate (request: RouterRequest, response: RouterResponse,
                       options: [String:Any], onSuccess: @escaping (UserProfile) -> Void,
                       onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       inProgress: @escaping () -> Void)

    /// A delegate for `UserProfile` manipulation.
    var userProfileDelegate: UserProfileDelegate? { get }
}

/// An extention of `CredentialsPluginProtocol`.
extension CredentialsPluginProtocol {
    /// The default (nil) value for `UserProfileDelegate`.
    public var userProfileDelegate: UserProfileDelegate? {
        return nil
    }
}
