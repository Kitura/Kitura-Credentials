//
//  KituraKit.swift
//  Kitura-Next
//
//  Created by Aaron Liberatore on 12/6/17.
//

import Foundation
import KituraKit
import SwiftyRequest
import KituraContracts
import AuthContracts

extension KituraKit {

  /// Symmetric Get
  public func get<U: AuthenticatedUser, O: Codable>(_ route: String, respondWith: @escaping CodableAuthArrayResultClosure<U, O>) {
    let url = baseURL.appendingPathComponent(route)
    let request = RestRequest(url: url.absoluteString)
    request.credentials = self.authorization


    request.responseData { response in
      switch response.result {
      case .success(let data):
        guard let authObj = try? JSONDecoder().decode(AuthenticatedObject<U, [O]>.self, from: data) else {
          respondWith(nil, nil, RequestError.clientDeserializationError)
          return
        }
        respondWith(authObj.user, authObj.object, nil)
      case .failure(let error):
        if let restError = error as? RestError {
          respondWith(nil, nil, RequestError(restError: restError))
        } else {
          respondWith(nil, nil, .clientErrorUnknown)
        }
      }
    }
  }
}

/** Possible Request-by-request initializers

 Usage:
  client.authorize(user: "Aaron", password: "Password).get("/") { (returnedArray: [O]?, error: Error?) -> Void in
    print(returnedArray)
  }

  client.authorize(using: .digest(user: "aaron", password: "password)).get("/") { (returnedArray: [O]?, error: Error?) -> Void in
    print(returnedArray)
  }
 */
extension KituraKit {

  /// Mark - Authorization by request methods

  /// Basic auth direct
  public func authorize(user: String, password: String) -> KituraKit {
    self.authorization = Credentials.basicAuthentication(username: user, password: password)
    return self
  }

  /// Basic or digest? through enum
  /// We have to be explicit here because of the `import Credentials` library
  public func authorize(using credentials: Credentials) -> KituraKit {
    self.authorization = credentials
    return self
  }
}
