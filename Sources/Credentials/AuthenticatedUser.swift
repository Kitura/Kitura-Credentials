import Kitura
import KituraContracts

public final class AuthenticatedUser: Credentials, TypeSafeMiddleware {
    
    private static let credentials = Credentials()
    
    public static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (AuthenticatedUser?, RequestError?) -> Void) {
        // TODO: invoke handle for Credentials
    }
    
    public static func describe() -> String {
        return "TODO"
    }
    
    
    
    
}
