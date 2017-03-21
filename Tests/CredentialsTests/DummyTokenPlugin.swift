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

public class DummyTokenPlugin : CredentialsPluginProtocol {

    public var name : String {
        return "DummyToken"
    }

    public var redirecting : Bool {
        return false
    }

    public init () {}

    public var usersCache : NSCache<NSString, BaseCacheElement>?

    public func authenticate (request: RouterRequest, response: RouterResponse,
                              options: [String:Any], onSuccess: @escaping (UserProfile) -> Void,
                              onFailure: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                              onPass: @escaping (HTTPStatusCode?, [String:String]?) -> Void,
                              inProgress: @escaping () -> Void) {
        if let type = request.headers["X-token-type"], type == name {
            if let token = request.headers["access_token"], token == "dummyToken123" {
                let userProfile = UserProfile(id: "123", displayName: "Dummy User", provider: self.name)
                let newCacheElement = BaseCacheElement(profile: userProfile)
                #if os(OSX)
                    self.usersCache?.setObject(newCacheElement, forKey: token as NSString)
                #else
                    self.usersCache?.setObject(newCacheElement, forKey: NSString(string: token))
                #endif
                onSuccess(userProfile)
            }
            else {
                onFailure(nil, nil)
            }
        }
        else {
            onPass(nil, nil)
        }
    }
}
