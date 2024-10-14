//
//  UserSession.swift
//  swiftFrontEnd
//
//  Created by Mohammed Ali on 10/13/24.
//

import Foundation

class UserSession {
    // The shared instance (singleton)
    static let shared = UserSession()
    
    // Private initializer to prevent creating multiple instances
    private init() {}
    
    // Variable to store the username
    var username: String?
}
