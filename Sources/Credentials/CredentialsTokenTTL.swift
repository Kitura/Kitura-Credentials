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

/// Protocol to make it easier to add token TTL to credentials plugins.
public protocol CredentialsTokenTTL {
    var usersCache: NSCache<NSString, BaseCacheElement>? {get}
    var tokenTimeToLive: TimeInterval? {get}
}

public enum CredentialsTokenTTLResult {
    case success(UserProfile)
    case failure(HTTPStatusCode?, [String:String]?)
}

extension CredentialsTokenTTL {

    /// Returns the profile (from cache or generated with the passed closure), or a failure result. After calling this method, you need to call the corresponding onSuccess or onFailure methods of the authentication method.
    ///
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter userProfileGenerator: Called if the token found in the cache has expired or if there is no token in the cache.
    ///
    public func getProfileAndCacheIfNeeded(
        token: String,
        userProfileGenerator: @escaping () -> CredentialsTokenTTLResult) -> CredentialsTokenTTLResult {
        
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        if let cached = usersCache?.object(forKey: key) {
            if let ttl = tokenTimeToLive {
                if Date() < cached.createdAt.addingTimeInterval(ttl) {
                    return .success(cached.userProfile)
                }
                // If current time is later than time to live, continue to standard token authentication.
                // Don't need to evict token, since it will replaced if the token is successfully autheticated.
            } else {
                // No time to live set, use token until it is evicted from the cache
                return .success(cached.userProfile)
            }
        }
        
        // Either the token/profile expired or there was none in the cache. Make one.
        
        let generatedResult = userProfileGenerator()
        
        switch generatedResult {
        case .success(let userProfile):
            let newCacheElement = BaseCacheElement(profile: userProfile)
            #if os(Linux)
                let key = NSString(string: token)
            #else
                let key = token as NSString
            #endif
            
            self.usersCache!.setObject(newCacheElement, forKey: key)
            return generatedResult
            
        case .failure:
            return generatedResult
        }
    }
}
