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
import KituraNet
import KituraContracts
import LoggerAPI

import Foundation

public protocol TypeSafeCredentialsPluginProtocol: TypeSafeMiddleware {
    
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
    static func authenticate (request: RouterRequest, response: RouterResponse,
                              onSuccess: @escaping (Self) -> Void,
                              onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                              onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                              inProgress: @escaping () -> Void)

}

extension TypeSafeCredentialsPluginProtocol {
    
    /// Handle an incoming request: authenticate the request using the registered plugins.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter next: The closure to invoke to enable the Router to check for
    ///                  other handlers or middleware to work with this request.
    public static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (Self?, RequestError?) -> Void) {
        
        var passStatus : HTTPStatusCode?
        var passHeaders : [String:String]?
        
        var callback: (()->Void)? = nil
        let callbackHandler = {[request, response, completion] () -> Void in
            authenticate(request: request, response: response,
                         onSuccess: { selfInstance in
                            completion(selfInstance, nil)
            },
                         onFailure: { status, headers in
                            fail(response: response, status: status, headers: headers)
                            completion(nil, .unauthorized)
            },
                         onPass: { status, headers in
                            if let status = status, passStatus == nil {
                                passStatus = status
                                passHeaders = headers
                            }
                            completion(nil, .unauthorized)
            },
                         inProgress: {
                            completion(nil, .unauthorized)
            }
            )
        }
        callback = callbackHandler
        callbackHandler()
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
