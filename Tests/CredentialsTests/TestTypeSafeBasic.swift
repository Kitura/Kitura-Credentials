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

import Foundation
import XCTest

import Kitura
import KituraNet

@testable import Credentials

class TestTypeSafeBasic : XCTestCase {
    
    static var allTests : [(String, (TestTypeSafeBasic) -> () throws -> Void)] {
        return [
            ("testTypeSafeNoCredentials", testTypeSafeNoCredentials),
            ("testTypeSafeBadCredentials", testTypeSafeBadCredentials),
            ("testTypeSafeBasic", testTypeSafeBasic),
        ]
    }
    
    let host = "127.0.0.1"
    
    let router = TestTypeSafeBasic.setupTypeSafeRouter()
    
    func testTypeSafeNoCredentials() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/typesafebasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            })
        }
    }
    
    func testTypeSafeBadCredentials() {
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/typesafebasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic QWxhZGRpbjpPcGVuU2VzYW1l"])
        }
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/typesafebasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic"])
        }
    }
    
    func testTypeSafeBasic() {
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/typesafebasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    guard let stringBody = try response?.readString(),
                        let jsonData = stringBody.data(using: .utf8)
                        else {
                            return XCTFail("Did not receive a JSON body")
                    }
                    let decoder = JSONDecoder()
                    let body = try decoder.decode(User.self, from: jsonData)
                    XCTAssertEqual(body, User(name: "John", provider: "HTTPBasic"))
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
                // Basic Sm9objoxMjM= is "John" : "123" base64 encoded.
            }, headers: ["Authorization" : "Basic Sm9objoxMjM="])
        }
    }
    
    static func setupTypeSafeRouter() -> Router {
        let router = Router()
        
        router.get("/private/typesafebasic") { (authedUser: TypeSafeBasic, respondWith: (User?, RequestError?) -> Void) in
            let user = User(name: authedUser.id, provider: authedUser.provider)
            respondWith(user, nil)
        }
        
        return router
    }
    

    
    
}
