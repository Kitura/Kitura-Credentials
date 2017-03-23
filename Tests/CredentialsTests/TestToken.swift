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

import Foundation
import XCTest

import Kitura
import KituraNet

@testable import Credentials

class TestToken : XCTestCase {

    static var allTests : [(String, (TestToken) -> () throws -> Void)] {
        return [
            ("testToken", testToken),
            ("testUnauthorized", testUnauthorized)
        ]
    }

    override func tearDown() {
        doTearDown()
    }

    let router = TestToken.setupRouter()

    func testToken() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/user", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body,"<!DOCTYPE html><html><body><b>Dummy User is logged in with DummyToken</b></body></html>\n\n")
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["X-token-type" : "DummyToken", "access_token" : "dummyToken123"])
        }
    }

    func testUnauthorized() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", path:"/private/user", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")
                expectation.fulfill()
                }, headers: ["X-token-type" : "DummyToken", "access_token" : "wrongToken"])
        }
    }


    static func setupRouter() -> Router {
        let router = Router()

        let dummyTokenPlugin = DummyTokenPlugin()
        let credentials = Credentials()
        credentials.register(plugin: dummyTokenPlugin)

        router.all("/private/*", middleware: BodyParser())

        router.all("/private", middleware: credentials)

        router.get("/private/user") { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let profile = request.userProfile {
                    try response.status(.OK).send("<!DOCTYPE html><html><body><b>\(profile.displayName) is logged in with \(profile.provider)</b></body></html>\n\n").end()
                }
            }
            catch {}

            next()
        }


        router.error { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                let errorDescription: String
                if let error = response.error {
                    errorDescription = "\(error)"
                }
                else {
                    errorDescription = ""
                }
                try response.send("Caught the error: \(errorDescription)").end()
            }
            catch {}
            next()
        }
        
        return router
    }
}
