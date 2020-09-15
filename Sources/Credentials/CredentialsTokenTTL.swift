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

/// Protocol to make it easier to add token TTL (Time To Live) to credentials plugins.
/// Using this protocol:
/// --------------------
/// Step 1) Conform to the protocol
/// Step 2) Call one of the two getProfileAndCacheIfNeeded methods-- probably at the end of your authenticate method:
///
/// Either: Step 2a) Typical plugins will call the getProfileAndCacheIfNeeded method with the onSuccess and onFailure closures. I.e., typical plugins will either simply fail or succeed when attempting to generate a user profile when generateNewProfile is called. E.g., see https://github.com/crspybits/CredentialsMicrosoft/blob/master/Sources/CredentialsMicrosoft/CredentialsMicrosoftToken.swift
///
/// Or: Step 2b) More complicated plugins will call the getProfileAndCacheIfNeeded method with the single, completion, closure. These plugins (e.g., see https://github.com/Kitura/Kitura-CredentialsJWT/blob/master/Sources/CredentialsJWT/CredentialsJWT.swift) not only either succeed or fail, but they can have a third, unprocessable result.

public protocol CredentialsTokenTTL: AnyObject {
    /// Needed for caching (token, user profile) pairs until their TTL expires or they are evicted from the cache. If nil, no caching of user profiles is carried out.
    var usersCache: NSCache<NSString, BaseCacheElement>? {get}
    
    /// The specific TTL value used by the plugin. If nil, the TTL is not used.
    var tokenTimeToLive: TimeInterval? {get}
    
    /// Used by the getProfileAndCacheIfNeeded method to generate a profile if one can't be used from cache.
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter options: The dictionary of plugin specific options.
    /// Effects: Method you implement needs to generate a new profile for a user given the token, if possible. Your method is *not* reponsible for caching the resulting profile (if successful). Caching is handled by other components of this protocol.
    func generateNewProfile(token: String, options: [String:Any], completion: @escaping (CredentialsTokenTTLResult) -> Void)
}

/// Represents the result of a call to `generateNewProfile()`, and one of the two possible `getProfileAndCacheIfNeeded` methods, with an authentication token.
/// On success, the resulting `UserProfile` is returned. On failure, the plugin may return
/// a status code and headers that should be sent in response. If the plugin cannot
/// process the token provided, then it may choose whether to fail, or to pass `unprocessable` to
/// allow other plugins to handle authentication instead.
public enum CredentialsTokenTTLResult {
    /// Authentication was successful. The `UserProfile` represents the identity of the bearer.
    case success(UserProfile)
    
    /// The token was successfully parsed, but authentication failed. The plugin may provide
    /// a status code and headers to send in response.
    case failure(HTTPStatusCode?, [String:String]?)
    
    /// The token could not be handled by this plugin. It may be malformed, or intended for
    /// another plugin.
    /// This case is only used by the getProfileAndCacheIfNeeded method with the completion
    /// callback and is intended for plugins with more complicated needs.
    case unprocessable(details: String)
    
    /// Helper method to convert an Error to a failure enum
    public static func error(_ error: Swift.Error) -> CredentialsTokenTTLResult {
        return .failure(nil, ["failure": "\(error)"])
    }
}

private enum CredentialsTokenTTLError: Swift.Error {
    case couldNotGetSelf
}

extension CredentialsTokenTTL {
    private func getProfileFromCache(token: String) -> UserProfile? {
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
    
    private func saveProfileToCache(token: String, profile: UserProfile) {
        let newCacheElement = BaseCacheElement(profile: profile)
        #if os(Linux)
            let key = NSString(string: token)
        #else
            let key = token as NSString
        #endif
        
        self.usersCache!.setObject(newCacheElement, forKey: key)
    }

    /// Calls the completion handler with the profile (from cache or generated with the protocol generateNewProfile method), or failure result. This method should be suited to most plugins that use a TTL.
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
        
        getProfileAndCacheIfNeeded(token: token, options: options) { result in
            switch result {
            case .success(let userProfile):
                onSuccess(userProfile)
            case .unprocessable:
                onFailure(nil, nil)
            case .failure(let statusCode, let dict):
                onFailure(statusCode, dict)
            }
        }
    }

    /// Calls the completion handler with the profile (from cache or generated with the protocol generateNewProfile method), or failure result. This method is suited to plugins with more complicated credentials needs. E.g., the Credentials JWT.
    ///
    /// - Parameter token: The Oauth2 token, used as a key in the cache.
    /// - Parameter options: The dictionary of plugin specific options.
    /// - Parameter completion: The detailed credentials TTL result.
    ///
    public func getProfileAndCacheIfNeeded(
        token: String,
        options: [String:Any],
        completion: @escaping (CredentialsTokenTTLResult) -> Void) {
        
        if let profile = getProfileFromCache(token: token) {
            completion(.success(profile))
            return
        }
        
        // Either the token/profile expired or there was none in the cache. Make one.
        
        generateNewProfile(token: token, options: options) {[weak self] generatedResult in
            guard let strongSelf = self else {
                completion(.error(CredentialsTokenTTLError.couldNotGetSelf))
                return
            }
            
            switch generatedResult {
            case .success(let profile):
                strongSelf.saveProfileToCache(token: token, profile: profile)
                completion(.success(profile))
                
            case .unprocessable, .failure:
                completion(generatedResult)
            }
        }
    }
}
