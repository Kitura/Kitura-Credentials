# Kitura-Credentials
A pluggable framework for validating user credentials in a Swift server using Kitura

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A pluggable framework for validating user credentials in a Swift server using Kitura. A particular plugin for this framework enables authenticating a user in some particular way. For example, Open-Id, Facebook login, Google login, and potentially many others.

There are two main authentication schemes supported by Kitura-Credentials: authentication with OAuth token that was acquired by a mobile app or other client of the Kitura based backend, and session authentication.

In token-based authentication Kitura-Credentials loops through the plugins in the order they were registered until a matching plugin is found. The plugin either succeeds to authenticate the request (in that case user profile information is returned) or fails. If no matching plugin is found or the matching plugin fails to authenticate the request, HTTP status code in the router response is set to Unauthorized (401).

In the web session case authentication is performed for a specific plugin: Kitura-Credentials tries to login and authenticate the first request by calling the plugin, and stores the relevant data in the session for authentication of the further requests in that session.


## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [List of plugins](#list-of-plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Credentials works with the DEVELOPMENT-SNAPSHOT-2016-03-24-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.


## Example

For web session authentication example please see [Kitura-Credentials-Sample](https://github.com/IBM-Swift/Kitura-Credentials-Sample).
<br>


The following is an example of token-based authentication.This example authenticates post requests using [Kitura-CredentialsFacebookToken](https://github.com/IBM-Swift/Kitura-CredentialsFacebookToken) plugin.

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

## List of plugins:
* [Authentication using an OAuth token from Facebook](https://github.com/IBM-Swift/Kitura-CredentialsFacebookToken)

* [Authentication using Facebook web login](https://github.com/IBM-Swift/Kitura-CredentialsFacebook)

* [Authentication using an OAuth token from Google](https://github.com/IBM-Swift/Kitura-CredentialsGoogleToken)

* [Authentication using Google web login](https://github.com/IBM-Swift/Kitura-CredentialsGoogle)


## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
