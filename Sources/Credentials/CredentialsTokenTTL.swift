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
/// Using this protocol:
/// Step 1) Conform to the protocol
/// Step 2) Call the getProfileAndCacheIfNeeded method-- probably at the end of your authenticate method.
public protocol CredentialsTokenTTL: AnyObject {
    var usersCache: NSCache<NSString, BaseCacheElement>? {get}
    var tokenTimeToLive: TimeInterval? {get}
    
    /// Used by the getProfileAndCacheIfNeeded method to generate a profile if one can't be used from cache.
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter options: The dictionary of plugin specific options.
    func generateNewProfile(token: String, options: [String:Any], completion: @escaping (CredentialsTokenTTLResult) -> Void)
}

/// Enum with cases corresponding to the onSuccess and onFailure closures in the authentication method.
public enum CredentialsTokenTTLResult {
    case success(UserProfile)
    case failure(HTTPStatusCode?, [String:String]?)
    
    /// Helper method to convert an Error to a failure enum
    public static func error(_ error: Swift.Error) -> CredentialsTokenTTLResult {
        return .failure(nil, ["failure": "\(error)"])
    }
}

extension CredentialsTokenTTL {
    func getProfileFromCache(token: String) -> UserProfile? {
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        if let cached = usersCache?.object(forKey: key) {
            if let ttl = tokenTimeToLive {
                if Date() < cached.createdAt.addingTimeInterval(ttl) {
                    return cached.userProfile
                }
                // If current time is later than time to live, continue to standard token authentication.
                // Don't need to evict token, since it will replaced if the token is successfully authenticated.
            } else {
                // No time to live set, use token until it is evicted from the cache
                return cached.userProfile
            }
        }
        
        return nil
    }
    
    func saveProfileToCache(token: String, profile: UserProfile) {
        let newCacheElement = BaseCacheElement(profile: profile)
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        self.usersCache!.setObject(newCacheElement, forKey: key)
    }

    /// Calls the completion handler with the profile (from cache or generated with the protocol generateNewProfile method), or failure result.
    ///
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter options: The dictionary of plugin specific options.
    /// - Parameter onSuccess: From the authentication method.
    /// - Parameter onFailure: From the authentication method.
    ///
    public func getProfileAndCacheIfNeeded(
        token: String,
        options: [String:Any],
        onSuccess: @escaping (UserProfile) -> Void,
        onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void) {
        
        if let profile = getProfileFromCache(token: token) {
            onSuccess(profile)
            return
        }
        
        // Either the token/profile expired or there was none in the cache. Make one.
        
        generateNewProfile(token: token, options: options) {[weak self] generatedResult in
            guard let self = self else {
                onFailure(nil, nil)
                return
            }
            
            switch generatedResult {
            case .success(let profile):
                self.saveProfileToCache(token: token, profile: profile)
                onSuccess(profile)
                
            case .failure(let statusCode, let dict):
                onFailure(statusCode, dict)
            }
        }
    }
}
