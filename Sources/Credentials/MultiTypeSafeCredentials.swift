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
 A `TypeSafeMiddleware` protocol for using multiple authentication methods on a Codable route. An object conforming to this protocol must contain a static array of the acceptable `TypeSafeCredentials` types and be initializable from the authentication instance that succeeded. If an authentication fails or you reach the end of your array, an unauthorized response is sent.
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
    
    /// An array of authentication types that conform to `TypeSafeCredentials`. Each type will be asked, in turn, to authenticate an incoming request.
    static var authenticationMethods: [TypeSafeCredentials.Type] { get }

    /**
     This initalizer creates an instance of the type conforming to `TypeSafeMultiCredentials` from a successfully authenticated `TypeSafeCredentials` instance.
     ### Usage Example: ###
     ```swift
     init(successfulAuth: TypeSafeCredentials) {
         self.id = successfulAuth.id
         self.provider = successfulAuth.provider
         switch(successAuth.self) {
         case let googleProfile as GoogleTokenProfile:
             self.name = googleProfile.name
         default:
             self.name = nil
         }
     }
     ```
     */
    init(successfulAuth: TypeSafeCredentials)
}

extension TypeSafeMultiCredentials {
    
    /// Static function that iterates through the `authenticationMethods` array of `TypeSafeCredentials` types calling their authenticate function. If a type successfully authenticates and returns onSuccess(Self), `TypeSafeMultiCredentials` will call init(successfulAuth:) with the successful instance. If a type matches its authorization header but fails to authenticate it returns onFailure() and an .unauthorized response is sent. If a type doesn't match its authorization header then it returns onSkip() and the next authentication method is called.
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
