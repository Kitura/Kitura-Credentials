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

import Foundation

// MARK UserProfile

/// User's profile information. Different authentication services provide
/// different user information which is used to fill this structure.
public class UserProfile {
    
    /// User's ID.
    public var id : String
    
    /// The authenticating service used to authenticate the user.
    public var provider : String
    
    /// User's name the way it should be displayed.
    public var displayName : String
    
    /// A structure for user's name.
    public struct UserProfileName {
        
        /// Family/last name of the user.
        public var familyName : String
        
        /// Given/first name of the user.
        public var givenName : String
        
        /// Middle name.
        public var middleName : String
        
        /// Initialize `UserProfileName`.
        ///
        /// - Parameter familyName: family/last name.
        /// - Parameter givenName: given/first name.
        /// - Parameter middleName: middle name.
        /// - Returns: an instance of `UserProfileName`.
        public init(familyName : String, givenName : String, middleName : String) {
            self.familyName = familyName
            self.givenName = givenName
            self.middleName = middleName
        }
    }
    
    /// User's name (optional).
    public var name : UserProfileName?
    
    /// A structure for user's email address.
    public struct UserProfileEmail {

        /// The actual email address.
        public var value : String
        
        /// The type of email address (home, work, etc.).
        public var type : String
        
        /// Initialize `UserProfileEmail`.
        ///
        /// - Parameter value: actual email address.
        /// - Parameter type: type of email address.
        /// - Returns: an instance of `UserProfileEmail`.
        public init(value : String, type : String) {
            self.value = value
            self.type = type
        }
    }
    
    /// An optional array of user's email addresses.
    public var emails : [UserProfileEmail]?
    
    /// A structure for user's photo.
    public struct UserProfilePhoto {

        /// The URL of the image.
        public var value : String
        
        /// Initialize `UserProfilePhoto`.
        ///
        /// - Parameter value: photo's URL.
        /// - Returns: an instance of `UserProfilePhoto`.
        public init(_ value : String) {
            self.value = value
        }
    }
    
    /// An optional array of user's photos.
    public var photos : [UserProfilePhoto]?
    
    /// Initialize `UserProfile`.
    ///
    /// - Parameter id: user's ID.
    /// - Parameter displayName: user's name to display.
    /// - Parameter provider: the authenticating service.
    /// - Parameter name: user's name.
    /// - Parameter emails: user's email addresses.
    /// - Parameter photos: user's photos.
    /// - Returns: an instance of `UserProfile`.
    public init (id: String, displayName: String, provider: String, name: UserProfileName?=nil, emails: [UserProfileEmail]?=nil, photos : [UserProfilePhoto]?=nil) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.name = name
        self.emails = emails
        self.photos = photos
    }
}

