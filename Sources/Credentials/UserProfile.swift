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

public class UserProfile {
    public var id : String
    public var provider : String
    public var displayName : String
    
    public struct UserProfileName {
        public var familyName : String
        public var givenName : String
        public var middleName : String
    }
    public var name : UserProfileName?
    
    public struct UserProfileEmail {
        /// The actual email address.
        public var value : String
        /// The type of email address (home, work, etc.).
        public var type : String
    }
    public var emails : [UserProfileEmail]?
    
    public struct UserProfilePhoto {
        /// The URL of the image.
        public var value : String
    }
    public var photos : [UserProfilePhoto]?
    
    public init (id: String, displayName: String, provider: String, name: UserProfileName?=nil, emails: [UserProfileEmail]?=nil, photos : [UserProfilePhoto]?=nil) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.name = name
        self.emails = emails
        self.photos = photos
    }
}

