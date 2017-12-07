/**
 * Copyright IBM Corporation 2016, 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura

import Foundation
import AuthContracts

// MARK RouterRequest+UserProfile

private let USER_PROFILE_USER_INFO_KEY = "@@Kitura@@UserProfile@@"

/// Extension of the `RouterRequest` class to provide access to `UserProfile`
/// information of authenticated users.
public extension RouterRequest {

    /// `UserProfile` information of authenticated users.
    public internal(set) var userProfile: UserProfile? {
        get {
            if let requestUserProfile = userInfo[USER_PROFILE_USER_INFO_KEY] as? UserProfile {
                return requestUserProfile
            }

            if let session = session,
                let sessionUserProfile = Credentials.restoreUserProfile(from: session) {
                return sessionUserProfile
            }

            return nil
        }
        set {
            userInfo[USER_PROFILE_USER_INFO_KEY] = newValue
        }
    }
}
