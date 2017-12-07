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
import AuthContracts

// MARK UserProfileDelegate

/// A protocol for `UserProfile` manipulation.
/// The current default implementation only tries to fill in the standard `UserProfile` fields. In case this default behaviour is insufficient,
/// additional data can be stored in `UserProfile.extendedProperties` and filled in using this delegate. An implementation
/// should be passed in the `options` argument with the key `userProfileDelegate` to the corresponding plugin's constructor.
public protocol UserProfileDelegate {
    /// Updates the `UserProfile` instance from the data received from an identity provider.
    ///
    /// - Returns: The `UserProfile` containing the data to update.
    /// - Parameter from dictionary: A Dictionary containing the data.
    func update(userProfile: UserProfile, from dictionary: [String:Any])
}
