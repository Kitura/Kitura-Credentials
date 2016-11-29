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

// MARK UserProfileDelegate

/// A protocol for `UserProfile` manipulation. 
/// The current default implementation only copies UserProfile displayName, id, and provider. In case this default behaviour is insufficient,
/// this protocol should be implemented, and passed as an option to the corresponding plugin's constructor.
public protocol UserProfileDelegate {
 
    /// Creates a Dictionary from the `UserProfile` instance.
    ///
    /// - Parameter userProfile: The user profile to convert to a Dictionary.
    /// - Returns: A Dictionary containing the user profile.
    func userProfileToDictionary(_ userProfile: UserProfile) -> [String:Any]
    
    /// Creates a `UserProfile` instance from the data received from an identity provider.
    ///
    /// - Parameter dictionary: A Dictionary containing the data to convert.
    /// - Returns: A `UserProfile` containing the data. If the conversion fails, i.e., some fields are not found, nil is returned.
    func identityProviderDictionaryToUserProfile(_ dictionary: [String:Any]) -> UserProfile?

    /// Creates a `UserProfile` instance from the dictionary. Used to restore `UserProfile` from a `Session`.
    ///
    /// - Parameter dictionary: A Dictionary containing the data to convert.
    /// - Returns: A `UserProfile` containing the data. If the conversion fails, i.e., some fields are not found, nil is returned.
    func dictionaryToUserProfile(_ dictionary: [String:Any]) -> UserProfile?
}
