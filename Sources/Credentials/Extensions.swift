// https://stackoverflow.com/questions/27814519/swift-require-classes-implementing-protocol-to-be-subclasses-of-a-certain-cla
public protocol AuthenticatedUser {
    init(_ profile: UserProfile)
    static func createCredentials() -> Credentials
    // These are the properties defined in UserProfile
    var id: String { get }
    var provider: String { get }
    var displayName: String { get }
    var name: UserProfile.UserProfileName? { get }
    var emails: [UserProfile.UserProfileEmail]? { get }
    var photos: [UserProfile.UserProfilePhoto]? { get }
    var extendedProperties: [String:Any] { get }
}

// Example of what a developer would need to in order to create an instance of AuthenticatedUser
// This would be defined in the application code
class User: UserProfile, AuthenticatedUser {
    public static func createCredentials() -> Credentials {
        // Configuration of Credentials object would go here
        return Credentials()
    }

    // Child extension (via inheritance)
    public var xyz: String? {
        return extendedProperties["xyz"] as? String
    }

    public var abc: Int? {
        return extendedProperties["abc"] as? Int
    }

}

