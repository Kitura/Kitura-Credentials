# Kitura-Credentials
A pluggable framework for validating user credentials in a Swift server using Kitura

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A pluggable framework for validating user credentials in a Swift server using Kitura. A particular plugin for this framework enables authenticating a user in some particular way. For example, Open-Id, Facebook login, Google login, and potentially many others.

Kitura-Credentials loops through the plugins in the order they were registered until a matching plugin is found. The plugin either succeeds to authenticate the request (in that case user profile information is returned) or fails. If no matching plugin is found or the matching plugin fails to authenticate the request, HTTP status code in the router response is set to Unauthorized (401).


## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [List of plugins](#list-of-plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Credentials works with the DEVELOPMENT-SNAPSHOT-2016-03-01-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/).


## Example

This example authenticates post requests using [Kitura-CredentialsFacebookToken](https://github.com/IBM-Swift/Kitura-CredentialsFacebookToken) plugin.

First create an instance of `Credentials` and an instance of credentials plugin:

```swift
import Credentials
import CredentialsFacebookToken

let credentials = Credentials()
let fbCredentialsPlugin = CredentialsFacebookToken()
```
You can also set `options` (a dictionary of options passed to the plugin) either using the designated initializer or by setting them directly.

Now register the plugin:
```swift
credentials.register(fbCredentialsPlugin)
```

Kitura-Credentials framework is `RouterMiddleware`. To connect it to the desired path use one of the `Router` methods. After successful authentication `request.userInfo["profile"]` will contain an instance of `UserProfile` with user profile information received from OAuth server using the plugin.

```swift
router.post("/collection/:new", middleware: credentials)
router.post("/collection/:new") {request, response, next in
   ...
   let profile = request.userInfo["profile"] as! UserProfile
   let userId = profile.id
   let userName = profile.name
   ...
   next()
}
```

## List of plugins:
* [Authentication using an OAuth token from Facebook](https://github.com/IBM-Swift/Kitura-CredentialsFacebookToken)

* [Authentication using an OAuth token from Google](https://github.com/IBM-Swift/Kitura-CredentialsGoogleToken)


## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
