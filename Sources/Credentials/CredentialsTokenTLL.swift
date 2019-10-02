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

/// Protocol to make it easier to add token TLL to credentials plugins.
public protocol CredentialsTokenTLL {
    var usersCache: NSCache<NSString, BaseCacheElement>? {get}
    var tokenTimeToLive: TimeInterval? {get}
}

extension CredentialsTokenTLL {
    /// Returns true iff the token/UserProfile was found in the cache and onSuccess was called.
    ///
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter onSuccess: The callback used in the authenticate method.
    ///
    public func useTokenInCache(token: String, onSuccess: @escaping (UserProfile) -> Void) -> Bool {
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        if let cached = usersCache?.object(forKey: key) {
            if let ttl = tokenTimeToLive {
                if Date() < cached.createdAt.addingTimeInterval(ttl) {
                    onSuccess(cached.userProfile)
                    return true
                }
                // If current time is later than time to live, continue to standard token authentication.
                // Don't need to evict token, since it will replaced if the token is successfully autheticated.
            } else {
                // No time to live set, use token until it is evicted from the cache
                onSuccess(cached.userProfile)
                return true
            }
        }
        
        return false
    }
}
