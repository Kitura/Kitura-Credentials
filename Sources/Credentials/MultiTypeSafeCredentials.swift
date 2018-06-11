/**
 * Copyright IBM Corporation 2018
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
import LoggerAPI

import Foundation

// MARK TypeSafeMultiCredentials

/**
 A `TypeSafeMiddleware` for authenticating users using multiple authentication methods. A type conforming to `TypeSafeMultiCredentials` must implement a static array of `TypeSafeCredentials` types and an initializer, which takes a `TypeSafeCredentials` instance. The route will attempt to authenticate by iterating through this array of `TypeSafeCredentials` until an authentication succeeds. This returns an instance of the succesful `TypeSafeCredentials` which is used to initialize the `TypeSafeMultiCredentials` instance. If a plugin fails or you reach then end of your `TypeSafeCredentials array` an unauthorized response is sent. The type conforming to `TypeSafeMultiCredentials` can then be used as a middleware in codable routes.
 ### Usage Example: ###
 ```swift
 public final class AuthedUser: TypeSafeMultiCredentials {
 
    public let id: String
    public let provider: String
 
    public let name: String?
 
 } extension TypeSafeMultiCredentials {
    static let authenticationMethods: [TypeSafeCredentials.Type] = [MyBasicAuth.self, GoogleTokenProfile.self]
 
     init(successfulAuth: TypeSafeCredentials) {        
        self.id = successfulAuth.id
        self.provider = successfulAuth.provider
     }
 }
 
 router.get("/protected") { (authedUser: AuthedUser, respondWith: (AuthedUser?, RequestError?) -> Void) in
    print("user: \(authedUser.id) successfully authenticated using: \(authedUser.provider)")
    respondWith(authedUser, nil)
 }
 ```
 */
public protocol TypeSafeMultiCredentials: TypeSafeCredentials {
    
    /// An array of authentication types that conform to `TypeSafeCredentials`. The `authenticate` function for each type will be called in order and, on successfully authenticating, will call `init` using the `TypeSafeCredentials` instance.
    static var authenticationMethods: [TypeSafeCredentials.Type] { get }

    /**
     This initalizer creates an instance of the type conforming to `TypeSafeMultiCredentials` from a successfully authenticated `TypeSafeCredentials` instance.
     ```swift
     ### Usage Example: ###
     init(successfulAuth: TypeSafeCredentials) {
         switch(successAuth.self) {
         case let googleProfile as GoogleTokenProfile:
             self.id = googleProfile.id
             self.provider = googleProfile.provider
             self.name = googleProfile.name
         default:
             self.id = successfulAuth.id
             self.provider = successfulAuth.provider
         }
     }
     ```
     */
    init(successfulAuth: TypeSafeCredentials)
}

extension TypeSafeMultiCredentials {
    
    /// Static function that attempts to create an instance of Self by iterating through an array `TypeSafeCredentials` types and calling `authenticate`. On a successful authentication, an instance of Self is initialized from the `TypeSafeCredentials` instance and returned so it can be used by a `TypeSafeMiddleware` route. On a failed authentication, an unauthorized response is sent immediately. If the authentication header isn't recognised, authenticate is called on the next `TypeSafeCredentials` type.
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter onSuccess: The closure to invoke in the case of successful authentication.
    /// - Parameter onFailure: The closure to invoke in the case of an authentication failure.
    /// - Parameter onSkip: The closure to invoke when the plugin doesn't recognize the
    ///                     authentication data in the request.
    public static func authenticate(request: RouterRequest, response: RouterResponse,
                                    onSuccess: @escaping (Self) -> Void,
                                    onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void,
                                    onSkip: @escaping (HTTPStatusCode?, [String : String]?) -> Void) {
        for authentication in authenticationMethods {
            authentication.authenticate(request: request, response: response,
                    onSuccess: { (successfulAuth) in
                        return onSuccess(Self(successfulAuth: successfulAuth))
                    }, onFailure: { (statusCode, _) in
                        return onFailure(statusCode ?? .unauthorized, nil)
                    }, onSkip: { (_, _) in
                        // Do nothing if skipping authentication
                    })
        }
        onSkip(.unauthorized, nil)
    }
    
}
