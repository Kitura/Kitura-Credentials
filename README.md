<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>

<p align="center">
    <a href="https://ibm-swift.github.io/Kitura-Credentials/index.html">
        <img src="https://img.shields.io/badge/apidoc-KituraCredentials-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Kitura-Credentials">
    <img src="https://travis-ci.org/IBM-Swift/Kitura-Credentials.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>


# Kitura-Credentials

A pluggable framework for validating user credentials in a Swift server using Kitura.

## Summary
Kitura-Credentials is an authentication middleware for Kitura. Kitura-Credentials recognizes that each application has unique authentication requirements. It allows individual authentication mechanisms to be packaged as plugins which it consumes.

Plugins can range from a simple password based authentication or delegated authentication using OAuth (via Facebook OAuth provider, etc.), or federated authentication using OpenID.

There are two main authentication schemes supported by Kitura-Credentials: redirecting and non-redirecting. Redirecting scheme is used, for example, in OAuth2 Authorization Code flow authentication, where the users, that are not logged in, are redirected to a login page. All other types of authentication are non-redirecting, i.e., unauthorized requests are rejected (usually with a 401 Unauthorized HTTP status code). An example of non-redirecting authentication is delegated authentication using an OAuth access token (also called a bearer token) that was independently acquired (say by a mobile app or other client of the Kitura based backend).

Kitura-Credentials middleware checks if the request belongs to a session. If so and the user is logged in, it updates the request's user profile and propagates the request. Otherwise, it loops through the non-redirecting plugins in the order they were registered until a matching plugin is found. The plugin either succeeds to authenticate the request (in that case user profile information is returned) or fails. If a matching plugin is found but it fails to authenticate the request, the HTTP status code in the router response is set to Unauthorized (401), or to the code returned from the plugin, along with HTTP headers, and the request is not propagated. If no matching plugin is found, in case the request belongs to a session and a redirecting plugin exists, the request is redirected. Otherwise, the HTTP status code in the router response is set to Unauthorized (401), or to the first code returned from the plugins along with HTTP headers, and the request is not propagated. In case of successful authentication, the request's user profile is set with user profile information received from the authenticating plugin.

In the scope of an OAuth2 Authorization Code flow, authentication is performed by a specific plugin. Kitura-Credentials tries to login and authenticate the first request by calling the plugin and, if successful, stores the relevant data in the session for authentication of any further requests in that session. The plugin will not be called for other requests within the scope of the session.


## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [List of plugins](#list-of-plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Credentials requires **Swift 4.0** or newer. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

#### Add dependencies

Add the `Kitura-Credentials` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-Credentials` [release](https://github.com/IBM-Swift/Kitura-Credentials/releases).

```swift
.package(url: "https://github.com/IBM-Swift/Kitura-Credentials.git", from: "x.x.x")
```

Add `Credentials` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["Credentials"]),
```
#### Import packages

```swift
import Credentials
```

## Example

### Codable routing

Within Codable routes, you implement a single credentials plugin by defining a Swift type that conforms to the plugin's implementation of `TypeSafeCredentials`. This can then be applied to a codable route by defining it in the route signature:

```swift
router.get("/authenticated") { (userProfile: BasicAuthedUser, respondWith: (BasicAuthedUser?, RequestError?) -> Void) in
    print("authenticated \(userProfile.id) using \(userProfile.provider)")
    respondWith(userProfile, nil)
}
```

To apply multiple authentication methods to a route, you define a type which conforms to `TypeSafeMultiCredentials` and add it to your codable route signature.  The type must define an array of `TypeSafeCredentials` types, that will be queried in order, to attempt to authenticate a user. It must also define an initializer that creates an instance of self from an instance of the `TypeSafeCredentials` type.

If a user can authenticate with either HTTP basic or a token, and has defined the types `BasicAuthedUser` and `TokenAuthedUser`, then an implementation could be as follows:

```swift
public struct MultiAuthedUser : TypeSafeMultiCredentials {

    public let id: String
    public let provider: String

    public static var authenticationMethods: [TypeSafeCredentials.Type] = [BasicAuthedUser.self, TokenAuthedUser.self]

    public init(successfulAuth: TypeSafeCredentials) {
        self.id = successfulAuth.id
        self.provider = successfulAuth.provider
    }
}

router.get("/multiauth") { (userProfile: MultiAuthedUser, respondWith: (MultiAuthedUser?, RequestError?) -> Void) in
    print("authenticated \(userProfile.id) using \(userProfile.provider)")
    respondWith(userProfile, nil)
}
```

### Raw routing

For an OAuth2 Authorization Code flow authentication example please see [Kitura-Sample](https://github.com/IBM-Swift/Kitura-Sample).
<br>


The following is an example of  token-based authentication using Facebook OAuth2 access tokens.This example authenticates post requests using [CredentialsFacebookToken](https://github.com/IBM-Swift/Kitura-CredentialsFacebook) plugin.

First create an instance of `Credentials` and an instance of credentials plugin:

```swift
import Credentials
import CredentialsFacebook

let credentials = Credentials()
let fbCredentialsPlugin = CredentialsFacebookToken()
```
You can also set `options` (a dictionary of options passed to the plugin) either using the designated initializer or by setting them directly.

Now register the plugin:

```swift
credentials.register(fbCredentialsPlugin)
```

Kitura-Credentials framework is `RouterMiddleware`. To connect it to the desired path use one of the `Router` methods. After successful authentication `request.userProfile` will contain an instance of `UserProfile` with user profile information received from OAuth server using the plugin.

```swift
router.post("/collection/:new", middleware: credentials)
router.post("/collection/:new") {request, response, next in
   ...
   let profile = request.userProfile
   let userId = profile.id
   let userName = profile.displayName
   ...
   next()
}
```

> **NOTE**: The credential middleware must be registered before any route handlers, as shown in the example above. Failure to register the credential middleware before other route handlers may cause exposure of unauthorized data on protected routes.

## List of plugins:

* [JWT authentication](https://github.com/IBM-Swift/Kitura-CredentialsJWT)
* [Facebook OAuth2 Authorization Code flow login](https://github.com/IBM-Swift/Kitura-CredentialsFacebook)
* [Facebook OAuth2 token](https://github.com/IBM-Swift/Kitura-CredentialsFacebook)
* [GitHub OAuth2 Authorization Code flow login](https://github.com/IBM-Swift/Kitura-CredentialsGitHub)
* [Google OAuth2 Authorization Code flow login](https://github.com/IBM-Swift/Kitura-CredentialsGoogle)
* [Google OAuth2 token](https://github.com/IBM-Swift/Kitura-CredentialsGoogle)
* [HTTP Basic authentication](https://github.com/IBM-Swift/Kitura-CredentialsHTTP)
* [HTTP Digest authentication](https://github.com/IBM-Swift/Kitura-CredentialsHTTP)
* [Twitter OAuth](https://github.com/jacobvanorder/Kitura-CredentialsTwitter) (Third-party implemented)
* [Discord OAuth](https://github.com/123FLO321/Kitura-CredentialsDiscord) (Third-party implemented)
* [Local authentication](https://github.com/NocturnalSolutions/Kitura-CredentialsLocal) (For credentials stored in e.g. a local database; third-party implemented)

## API documentation

For more information visit our [API reference](http://ibm-swift.github.io/Kitura-Credentials/).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/IBM-Swift/Kitura-Credentials/blob/master/LICENSE.txt).
