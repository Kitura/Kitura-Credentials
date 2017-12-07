import Foundation
import KituraContracts

// This typealias would go into KituraContracts
public typealias AuthCodableClosure<U: AuthenticatedUser, I: Codable, O: Codable> = (U, I, @escaping CodableResultClosure<O>) -> Void
public typealias AuthCodableGetClosure<U: AuthenticatedUser, O: Codable> = (U, @escaping CodableAuthArrayResultClosure<U, O>) -> Void
public typealias CodableAuthArrayResultClosure<U: AuthenticatedUser, O: Codable> = (U?, [O]?, RequestError?) -> Void

// https://stackoverflow.com/questions/27814519/swift-require-classes-implementing-protocol-to-be-subclasses-of-a-certain-cla
public protocol AuthenticatedUser: Codable {
    init(_ profile: UserProfile)

    // These are the properties defined in UserProfile
    var id: String { get }
    var provider: String { get }
    var displayName: String { get }
    var name: UserProfile.UserProfileName? { get }
    var emails: [UserProfile.UserProfileEmail]? { get }
    var photos: [UserProfile.UserProfilePhoto]? { get }
    var extendedProperties: [String:Any] { get }
}

public struct AuthenticatedObject<U: AuthenticatedUser, T: Codable>: Codable {
  public let user: U?
  public let object: T?

  public init(user: U?, object: T?) {
    self.user = user
    self.object = object
  }
}
