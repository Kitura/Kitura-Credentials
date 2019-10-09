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
    
    public static func error(_ error: Swift.Error) -> CredentialsTokenTTLResult {
        return .failure(nil, ["failure": "\(error)"])
    }
}

extension CredentialsTokenTTL {

    /// Calls the completion handler with the profile (from cache or generated with the passed closure), or failure result. After calling getProfileAndCacheIfNeeded, and getting a success or failure result, you need to call the corresponding onSuccess or onFailure methods of the authentication method.
    ///
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter userProfileGenerator: Called if the token found in the cache has expired or if there is no token in the cache. Your closure must call its closure parameter when it is done.
    /// - Parameter completion: Called to return the result.
    ///
    public func getProfileAndCacheIfNeeded(
        token: String,
        userProfileGenerator: @escaping ((CredentialsTokenTTLResult)->()) -> Void,
        completion: @escaping (CredentialsTokenTTLResult) -> Void) {
        
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        if let cached = usersCache?.object(forKey: key) {
            if let ttl = tokenTimeToLive {
                if Date() < cached.createdAt.addingTimeInterval(ttl) {
                    completion(.success(cached.userProfile))
                    return
                }
                // If current time is later than time to live, continue to standard token authentication.
                // Don't need to evict token, since it will replaced if the token is successfully autheticated.
            } else {
                // No time to live set, use token until it is evicted from the cache
                completion(.success(cached.userProfile))
                return
            }
        }
        
        // Either the token/profile expired or there was none in the cache. Make one.
        
        userProfileGenerator() { generatedResult in
            switch generatedResult {
            case .success(let userProfile):
                let newCacheElement = BaseCacheElement(profile: userProfile)
                #if os(Linux)
                    let key = NSString(string: token)
                #else
                    let key = token as NSString
                #endif
                
                self.usersCache!.setObject(newCacheElement, forKey: key)
                completion(generatedResult)
                
            case .failure:
                completion(generatedResult)
            }
        }
    }
}
