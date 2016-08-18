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

public protocol CredentialsPluginProtocol {
    var name: String { get }
    #if os(Linux)
    var usersCache: Cache? { get set }
    #else
    var usersCache: NSCache<NSString, BaseCacheElement>? { get set }
    #endif
    var redirecting: Bool { get }
    
    func authenticate (request: RouterRequest, response: RouterResponse,
                       options: [String:Any], onSuccess: @escaping (UserProfile) -> Void,
                       onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                       inProgress: @escaping () -> Void)
}
