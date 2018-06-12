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

class TestTypeSafeMultiCredentials : XCTestCase {
    
    static var allTests : [(String, (TestTypeSafeMultiCredentials) -> () throws -> Void)] {
        return [
            ("testSingleNoCredentials", testSingleNoCredentials),
            ("testSingleBadCredentials", testSingleBadCredentials),
            ("testSingleBasic", testSingleBasic),
        ]
    }
    
    let host = "127.0.0.1"
    
    let router = TestTypeSafeMultiCredentials.setupTypeSafeRouter()
    
    func testSingleNoCredentials() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/onlybasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            })
        }
    }
    
    func testSingleBadCredentials() {
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/onlybasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic QWxhZGRpbjpPcGVuU2VzYW1l"])
        }
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/onlybasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic"])
        }
    }
    
    func testSingleBasic() {
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/onlybasic", callback: {response in
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
    
    func testTwoNoCredentials() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/tokenbasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            })
        }
    }
    
    func testTwoBadCredentials() {
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic QWxhZGRpbjpPcGVuU2VzYW1l", ])
        }
        
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["X-token-type" : "DummyToken", "access_token" : "WrongToken"])
        }
        
        // Basic authentication fails and so route returns unauthorized immediately
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
            }, headers: ["Authorization" : "Basic QWxhZGRpbjpPcGVuU2VzYW1l", "X-token-type" : "DummyToken", "access_token" : "dummyToken123"])
        }
    }
    
    func testTokenBasic() {
        
        // Authenticate using MultiTypeSafeTokenBasic with basic authentiction
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
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
        
        // Authenticate using MultiTypeSafeTokenBasic with token authentiction
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
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
                    XCTAssertEqual(body, User(name: "dummyToken123", provider: "DummyToken"))
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
                // Basic Sm9objoxMjM= is "John" : "123" base64 encoded.
            }, headers: ["X-token-type" : "DummyToken", "access_token" : "dummyToken123"])
        }
        
        // Authenticate using MultiTypeSafeTokenBasic with both provided
        // meaning basic authentication is used since it is first in the array
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
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
            }, headers: ["Authorization" : "Basic Sm9objoxMjM=", "X-token-type" : "DummyToken", "access_token" : "dummyToken123"])
        }
        
        // Authenticate using MultiTypeSafeTokenBasic with both provided but token is incorrect
        // meaning basic authentication is used since it is first in the array
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/tokenbasic", callback: {response in
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
            }, headers: ["Authorization" : "Basic Sm9objoxMjM=", "X-token-type" : "DummyToken", "access_token" : "WrongToken"])
        }
        
    }
    
    static func setupTypeSafeRouter() -> Router {
        let router = Router()
        
        router.get("/private/onlybasic") { (authedUser: MultiTypeSafeOnlyBasic, respondWith: (User?, RequestError?) -> Void) in
            let user = User(name: authedUser.id, provider: authedUser.provider)
            respondWith(user, nil)
        }
        
        router.get("/private/tokenbasic") { (authedUser: MultiTypeSafeTokenBasic, respondWith: (User?, RequestError?) -> Void) in
            let user = User(name: authedUser.id, provider: authedUser.provider)
            respondWith(user, nil)
        }
        
        return router
    }
    
    struct User: Codable, Equatable {
        let name: String
        let provider: String
        
        static func == (lhs: User, rhs: User) -> Bool {
            return lhs.name == rhs.name && lhs.provider == rhs.provider
        }
    }
    
    
}
