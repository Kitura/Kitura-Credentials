// https://stackoverflow.com/questions/27814519/swift-require-classes-implementing-protocol-to-be-subclasses-of-a-certain-cla

/// Authenticated User - Protocol defining conformance to the user profile
/// This has to be codable so we can send it to the user for symmetry

public protocol AuthenticatedUser: Codable {
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

/// Wrapper holder the user profile and the codable object to be passed to the client
public struct AuthenticatedObject<U: AuthenticatedUser, T: Codable>: Codable {
  public let user: U?
  public let object: T?
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

  required convenience public init(_ profile: UserProfile) {
    self.init(id: profile.id, displayName: profile.displayName,
              provider: profile.provider, name: profile.name,
              emails: profile.emails, photos: profile.photos,
              extendedProperties: profile.extendedProperties)
  }
}
