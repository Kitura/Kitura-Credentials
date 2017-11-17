import Foundation
import Kitura
import KituraContracts
import LoggerAPI

// This typealias would go into KituraContracts
public typealias AuthCodableClosure<U: AuthenticatedUser, I: Codable, O: Codable> = (U, I, @escaping CodableResultClosure<O>) -> Void

extension Router {
    public func post<U: AuthenticatedUser, I: Codable, O: Codable>(_ route: String, handler: @escaping AuthCodableClosure<U, I, O>) {
        postSafely(route, handler: handler)
    }
    
    fileprivate func postSafely<U: AuthenticatedUser, I: Codable, O: Codable>(_ route: String, handler: @escaping AuthCodableClosure<U, I, O>) {
        let creds = U.createCredentials()
        post(route, middleware: creds)
        post(route) { request, response, next in
            Log.verbose("Received POST type-safe authenticated request")
            guard self.isContentTypeJson(request) else {        //inaccessable due to private
                response.status(.unsupportedMediaType)
                next()
                return
            }
            guard !request.hasBodyParserBeenUsed else {             //inaccessable due to internal
                Log.error("No data in request. Codable routes do not allow the use of a BodyParser.")
                response.status(.internalServerError)
                return
            }
            do {
                // Process incoming data from client
                let param = try request.read(as: I.self)
                guard let profile = request.userProfile else {
                    response.status(.unauthorized)
                    next()
                    return
                }
                // Define handler to process result from application
                let resultHandler: CodableResultClosure<O> = { result, error in
                    do {
                        if let err = error {
                            let status = self.httpStatusCode(from: err)   //inaccessable due to private
                            response.status(status)
                        } else {
                            let encoded = try JSONEncoder().encode(result)
                            response.status(.created)
                            response.send(data: encoded)
                        }
                    } catch {
                        // Http 500 error
                        response.status(.internalServerError)
                    }
                    next()
                }
                // Invoke application handler
                handler(U(profile), param, resultHandler)
            } catch {
                // Http 400 error
                //response.status(.badRequest)
                // Http 422 error
                response.status(.unprocessableEntity)
                next()
            }
        }
    }
}