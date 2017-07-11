/**
 * Copyright IBM Corporation 2016, 2017
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
import KituraSession

@testable import Credentials

class TestUnauthorizedSession : XCTestCase {

    static var allTests : [(String, (TestUnauthorizedSession) -> () throws -> Void)] {
        return [
                ("testRedirect", testRedirect),
                ("testNoRedirect", testNoRedirect)
        ]
    }

    override func tearDown() {
        doTearDown()
    }

    let host = "127.0.0.1"

    static let credentials = Credentials()
    let router = TestUnauthorizedSession.setupRouter()

    func testRedirect() {
        TestUnauthorizedSession.credentials.options["failureRedirect"] = "/login"
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/data", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")

                expectation.fulfill()
            })
        }
    }

    func testNoRedirect() {
        TestUnauthorizedSession.credentials.options["failureRedirect"] = nil
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/data", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.unauthorized, "HTTP Status code was \(String(describing: response?.statusCode))")

                expectation.fulfill()
            })
        }
    }


    static func setupRouter() -> Router {
        let router = Router()

        router.all(middleware: Session(secret: "Very very secret....."))

        let badSessionPlugin = BadSessionPlugin(clientId: "dummyClientId", clientSecret: "dummyClientSecret", callbackUrl: "/login/callback")
        credentials.register(plugin: badSessionPlugin)
        credentials.options["failureRedirect"] = "/login"
        credentials.options["successRedirect"] = "/private/data"

        router.all("/private/*", middleware: BodyParser())

        router.all("/private", middleware: credentials)

        router.get("/private/data") { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let profile = request.userProfile {
                    try response.status(.OK).send("<!DOCTYPE html><html><body><b>\(profile.displayName) is logged in with \(profile.provider)</b></body></html>\n\n").end()
                }
             }
            catch {}

            next()
        }

        router.get("/login",
                   handler: credentials.authenticate(credentialsType: badSessionPlugin.name))
        router.get("/login/callback",
                   handler: credentials.authenticate(credentialsType: badSessionPlugin.name, failureRedirect: "/login/failure"))
        router.get("/login/failure") { _, response, next in
            do {
                try response.status(.unauthorized).end()
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
