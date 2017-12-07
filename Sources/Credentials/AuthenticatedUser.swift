import AuthContracts

public protocol AuthenticatedUser: AuthContracts.AuthenticatedUser {
  static func createCredentials() -> Credentials
}
