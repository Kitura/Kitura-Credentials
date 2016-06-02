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
import LoggerAPI
@testable import Credentials

import SwiftyJSON

import Foundation

public class BadSessionPlugin : CredentialsPluginProtocol {

    private var clientId : String

    private var clientSecret : String

    public var callbackUrl : String

    public var name : String {
        return "BadSession"
    }

    public var redirecting : Bool {
        return true
    }

#if os(OSX)
    public var usersCache : NSCache<NSString, BaseCacheElement>?
#else
    public var usersCache : NSCache?
#endif

    public init (clientId: String, clientSecret : String, callbackUrl : String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.callbackUrl = callbackUrl
    }

    public func authenticate (request: RouterRequest, response: RouterResponse, options: [String:OptionValue], onSuccess: (UserProfile) -> Void, onFailure: (HTTPStatusCode?, [String:String]?) -> Void, onPass: (HTTPStatusCode?, [String:String]?) -> Void, inProgress: () -> Void) {
        if let code = request.queryParams["code"] where code == "123" {
            onFailure(nil, nil)
        }
        else {
            // Log in
            do {
                try response.redirect(callbackUrl + "?code=123")
                inProgress()
            }
            catch {
                onFailure(nil, nil)
            }
        }
    }
}
