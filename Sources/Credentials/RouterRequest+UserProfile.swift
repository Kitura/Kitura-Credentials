/**
 * Copyright IBM Corporation 2016
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

// MARK RouterRequest+UserProfile

private let USER_PROFILE_USER_INFO_KEY = "@@Kitura@@UserProfile@@"

/// Extension of `RouterRequest` with `UserProfile` information.
public extension RouterRequest {
    
    /// User profile info.
    public internal(set) var userProfile: UserProfile? {
        get {
            return userInfo[USER_PROFILE_USER_INFO_KEY] as? UserProfile
        }
        set {
            userInfo[USER_PROFILE_USER_INFO_KEY] = newValue
        }
    }
}
