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

// MARK TypeSafeCredentials

/**
 A `TypeSafeMiddleware` for authenticating users. This protocol is implemented by plugins that identify the user using information supplied by the `RouterRequest`. The plugin must implement a static `authenticate` function which returns an instance of `Self` on success. This instance defines the name of the authentication provider (e.g. "HTTPBasic"), and an `id` that uniquely identifies a user for that provider.
 ### Usage Example: ###
 ```swift
 public final class TypeSafeHTTPBasic : TypeSafeCredentials {
 
     public let id: String
     public let provider: String = "HTTPBasic"
     private static let users = ["John" : "123"]
 
     public static func authenticate(request: RouterRequest, response: RouterResponse, onSuccess: @escaping (TypeSafeHTTPBasic) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onSkip: @escaping (HTTPStatusCode?, [String : String]?) -> Void {
 
         if let user = request.urlURL.user, let password = request.urlURL.password {
             if users[user] == password {
                 return onSuccess(UserHTTPBasic(id: user))
             } else {
                 return onFailure()
             }
         } else {
             return onSkip()
         }
     }
 }
 ```
 */
public protocol TypeSafeCredentials: TypeSafeMiddleware, Codable {
    
    /// An identifier that uniquely identifies a user within the context of an authentication provider.
    var id: String { get }
    
    /// The name of the authentication provider.
    var provider: String { get }
    
    /// Authenticate an incoming request. On success, an instance of `Self` is returned. On failure, the `HTTPStatusCode` and any response headers to be set are returned. On skip (Meaning the plugin didn't recognize the authentication header), the `HTTPStatusCode` and any response headers to be set are returned.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter onSuccess: The closure to invoke in the case of successful authentication.
    /// - Parameter onFailure: The closure to invoke in the case of an authentication failure.
    /// - Parameter onSkip: The closure to invoke when the request does not contain authentication
    ///                     data that this plugin recognises (such as a named token).
    static func authenticate (request: RouterRequest,
                              response: RouterResponse,
                              onSuccess: @escaping (Self) -> Void,
                              onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                              onSkip: @escaping (HTTPStatusCode?, [String:String]?) -> Void
                              )
    }

extension TypeSafeCredentials {
    
    /// Static function that attempts to create an instance of `Self` by calling `authenticate`. On success, this `Self` instance is returned so it can be used by a `TypeSafeMiddleware` route. On failure, an unauthorized response is sent immediately. If the authentication header isn't recognised, `RequestError.unauthorized` is returned to the `TypeSafeMiddleware` route. This means the current route will not be invoked but other routes can still be matched.
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter completion: The closure to invoke once middleware processing
    ///                         is complete. Either an instance of `Self` or a
    ///                         `RequestError` should be provided, indicating a
    ///                         successful or failed attempt to authenticate the request.
    public static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (Self?, RequestError?) -> Void) {
    
        authenticate(request: request,
                     response: response,
                     onSuccess: { selfInstance in
                        completion(selfInstance, nil)
                     },
                     onFailure: { status, headers in
                        fail(response: response, status: status, headers: headers)
                     },
                     onSkip: { status, headers in
                        if let headers = headers {
                            for (key, value) in headers {
                                response.headers.append(key, value: value)
                            }
                        }
                        // if no statusCode has been set, set the code as unauthorized
                        // if a statusCode has been set by a previous route use that code
                        if response.statusCode ==  .unknown {
                            completion(nil, RequestError(rawValue: status?.rawValue ?? 401))
                        } else {
                            let existingStatus = RequestError(rawValue: response.statusCode.rawValue)
                            completion(nil, existingStatus)
                        }
                     }
        )
    }
    
    private static func fail (response: RouterResponse, status: HTTPStatusCode?, headers: [String:String]?) {
        let responseStatus = status ?? .unauthorized
        if let headers = headers {
            for (key, value) in headers {
                response.headers.append(key, value: value)
            }
        }
        do {
            try response.status(responseStatus).end()
        }
        catch {
            Log.error("Failed to send response")
        }
    }
    

}
