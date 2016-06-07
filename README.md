# Kitura-Credentials
A pluggable framework for validating user credentials in a Swift server using Kitura

[![Build Status - Master](https://travis-ci.org/IBM-Swift/Kitura.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-Credentials)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A pluggable framework for validating user credentials in a Swift server using Kitura. A particular plugin for this framework enables authenticating a user in some particular way. For example, Open-Id, Facebook login, Google login, HTTP authentication, and potentially many others.

There are two main authentication schemes supported by Kitura-Credentials: redirecting and non-redirecting. Redirecting scheme is used for web session authentication, where the users, that are not logged in, are redirected to a login page. All other types of authentication are non-redirecting, i.e., unauthorized requests are rejected (usually with 401 Unauthorized HTTP status code). An example of non-redirecting authentication is authentication with OAuth token that was acquired by a mobile app or other client of the Kitura based backend.

Kitura-Credentials middleware checks if the request belongs to a session. If so and the user is logged in, it updates request's user profile and propagates the request. Otherwise, it loops through the non-redirecting plugins in the order they were registered until a matching plugin is found. The plugin either succeeds to authenticate the request (in that case user profile information is returned) or fails. If a matching plugin is found but it fails to authenticate the request, HTTP status code in the router response is set to Unauthorized (401), or to the code returned from the plugin along with HTTP headers, and the request is not propagated. If no matching plugin is found, in case the request belongs to a session and a redirecting plugin exists, the request is redirected. Otherwise, HTTP status code in the router response is set to Unauthorized (401), or to the first code returned from the plugins along with HTTP headers, and the request is not propagated. In case of successful authentication, request's user profile is set with user profile information received from the authenticating plugin.

In the scope of a web session, authentication is performed by a specific plugin. Kitura-Credentials tries to login and authenticate the first request by calling the plugin and, if successful, stores the relevant data in the session for authentication of the further requests in that session. The plugin will not be called for other requests within the scope of the session.


## Table of Contents
* [Swift version](#swift-version)
* [Example](#example)
* [List of plugins](#list-of-plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Credentials works with the DEVELOPMENT-SNAPSHOT-2016-05-09-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.


## Example

For web session authentication example please see [Kitura-Credentials-Sample](https://github.com/IBM-Swift/Kitura-Credentials-Sample).
<br>


The following is an example of non-redirecting token-based authentication.This example authenticates post requests using [Kitura-CredentialsFacebookToken](https://github.com/IBM-Swift/Kitura-CredentialsFacebookToken) plugin.

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

* [Authentication using HTTP Basic authentication](https://github.com/IBM-Swift/Kitura-CredentialsHttp)

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
