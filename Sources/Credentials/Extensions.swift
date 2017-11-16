protocol AuthenticatedUser {
    init(_ profile: UserProfile)
    static func createCredentials() -> Credentials
    var id: String { get }
    var provider: String { get }
    var displayName: String { get }
    // we would add here all of the fields exposed through UserProfile
}

class MyUser: UserProfile, AuthenticatedUser {
    public static func createCredentials() -> Credentials {
        return Credentials()
    }

    public var xyz: String? {
        return extendedProperties["xyz"] as? String
    }
    public var abc: Int? {
        return extendedProperties["abc"] as? Int
    }

}

//https://stackoverflow.com/questions/27814519/swift-require-classes-implementing-protocol-to-be-subclasses-of-a-certain-cla

// public class AuthenticatedUser: AuthenticatedUser {

//     func static createCredentials() -> Credentials {
//         return Credentials()
//     }
// }

func test() {
   // let userProfile = UserProfile()
    
}