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

/// The user's profile information. Different authentication services provide
/// different user information which is used to fill instances of this class.
public class UserProfile {
    
    /// The user's ID.
    public var id: String
    
    /// The authenticating service used to authenticate the user.
    public var provider: String
    
    /// The user's name the way it should be displayed.
    public var displayName: String
    
    /// A structure for the user's name.
    public struct UserProfileName {
        
        /// The family/last name of the user.
        public var familyName: String
        
        /// The given/first name of the user.
        public var givenName: String
        
        /// The middle name of the user.
        public var middleName: String
        
        /// Initialize a `UserProfileName` instance.
        ///
        /// - Parameter familyName: The family/last name of the user.
        /// - Parameter givenName: The given/first name of the user.
        /// - Parameter middleName: The middle name of the user.
        public init(familyName: String, givenName: String, middleName: String) {
            self.familyName = familyName
            self.givenName = givenName
            self.middleName = middleName
        }
    }
    
    /// The user's name (optional).
    public var name: UserProfileName?
    
    /// A structure for user's email address.
    public struct UserProfileEmail {

        /// The actual email address.
        public var value: String
        
        /// The type of email address (home, work, etc.).
        public var type: String
        
        /// Initialize a `UserProfileEmail` instance.
        ///
        /// - Parameter value: The actual email address.
        /// - Parameter type: The type of the email address.
        public init(value: String, type: String) {
            self.value = value
            self.type = type
        }
    }
    
    /// An optional array of the user's email addresses.
    public var emails: [UserProfileEmail]?
    
    /// A structure for the user's photo.
    public struct UserProfilePhoto {

        /// The URL of the image.
        public var value: String
        
        /// Initialize a `UserProfilePhoto` instance.
        ///
        /// - Parameter value: The photo's URL.
        public init(_ value: String) {
            self.value = value
        }
    }
    
    /// An optional array of the user's photos.
    public var photos: [UserProfilePhoto]?

    /// A dictionary of additional properties if needed. 
    public var extendedProperties: [String:Any]?
    
    /// Initialize a `UserProfile` instance.
    ///
    /// - Parameter id: The user's ID.
    /// - Parameter displayName: The user's name to display.
    /// - Parameter provider: The authenticating service.
    /// - Parameter name: The user's name.
    /// - Parameter emails: The user's email addresses.
    /// - Parameter photos: The user's photos.
    /// - Parameter extendedProperties: A dictionary of additional properties if needed.
    public init (id: String, displayName: String, provider: String, name: UserProfileName?=nil, emails: [UserProfileEmail]?=nil, photos: [UserProfilePhoto]?=nil, extendedProperties: [String:Any]?=nil) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.name = name
        self.emails = emails
        self.photos = photos
        self.extendedProperties = extendedProperties
    }
}

