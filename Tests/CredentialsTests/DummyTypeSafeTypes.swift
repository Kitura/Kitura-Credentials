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
import LoggerAPI
@testable import Credentials
import Foundation

public struct TypeSafeBasic : TypeSafeCredentials {
    
    public let id: String
    public let provider: String = "HTTPBasic"
    private static let users = ["John" : "123", "Doe" : "456"]
    
    public static func authenticate(request: RouterRequest, response: RouterResponse, onSuccess: @escaping (TypeSafeBasic) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onSkip: @escaping (HTTPStatusCode?, [String : String]?) -> Void) {
        
        guard let authorizationHeader = request.headers["Authorization"]  else {
            return onSkip(.unauthorized, nil)
        }
        let authorizationHeaderComponents = authorizationHeader.components(separatedBy: " ")
        guard authorizationHeaderComponents.count == 2,
            authorizationHeaderComponents[0] == "Basic",
            let decodedData = Data(base64Encoded: authorizationHeaderComponents[1], options: Data.Base64DecodingOptions(rawValue: 0)),
            let userAuthorization = String(data: decodedData, encoding: .utf8)
            else {
                return onSkip(.unauthorized, nil)
        }
        let credentials = userAuthorization.components(separatedBy: ":")
        guard credentials.count >= 2 else {
            return onFailure(.badRequest, nil)
        }
        
        let userid = credentials[0]
        let password = credentials[1]
        
        if users[userid] == password {
            return onSuccess(TypeSafeBasic(id: userid))
        } else {
            return onFailure(.unauthorized, nil)
        }
    }
}

public struct TypeSafeToken : TypeSafeCredentials {
    
    public let id: String
    public let provider: String = "DummyToken"
    private static let users = ["John" : "123", "Doe" : "456"]
    
    public static func authenticate(request: RouterRequest, response: RouterResponse, onSuccess: @escaping (TypeSafeToken) -> Void, onFailure: @escaping (HTTPStatusCode?, [String : String]?) -> Void, onSkip: @escaping (HTTPStatusCode?, [String : String]?) -> Void) {
        
        guard let type = request.headers["X-token-type"], type == "DummyToken" else {
            return onSkip(nil, nil)
        }
        guard let token = request.headers["access_token"], token == "dummyToken123" else {
            return onFailure(nil, nil)
        }
        
        let userProfile = TypeSafeToken(id: token)
        onSuccess(userProfile)
    }
}

public struct MultiTypeSafeOnlyBasic : TypeSafeMultiCredentials {
    
    public let id: String
    public let provider: String
    
    public static var authenticationMethods: [TypeSafeCredentials.Type] = [TypeSafeBasic.self]
    
    public init(successfulAuth: TypeSafeCredentials) {
        self.id = successfulAuth.id
        self.provider = successfulAuth.provider
    }
}

public struct MultiTypeSafeTokenBasic : TypeSafeMultiCredentials {
    
    public let id: String
    public let provider: String
    
    public static var authenticationMethods: [TypeSafeCredentials.Type] = [TypeSafeBasic.self, TypeSafeToken.self]
    
    public init(successfulAuth: TypeSafeCredentials) {
        self.id = successfulAuth.id
        self.provider = successfulAuth.provider
    }
}

public struct User: Codable, Equatable {
    let name: String
    let provider: String
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name && lhs.provider == rhs.provider
    }
}
