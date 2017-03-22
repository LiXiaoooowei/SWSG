//
//  User.swift
//  SWSG
//
//  Created by shixiyue on 11/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation

/// `User` represents a User of SWSG App.
protocol User: NSCoding {
    
    var type: UserTypes { get }
    
    var profile: Profile { get }
    
    var password: String { get set }
    
    var email: String { get }
    
    func setPassword(newPassword: String) -> Bool
    
}

extension User {
    
    func setPassword(newPassword: String) -> Bool {
        _checkRep()
        password = newPassword
        _checkRep()
        // Cominucate with backend...
        return true
    }
    
    //TODO: Add type and team
    func toDictionary() -> [String: Any] {
        return [Config.email: email, Config.password: password, Config.profile: profile.toDictionary()]
    }
    
    internal func _checkRep() {
        // Assumption: type, profile and team have met their representation invariants.
        assert (Utility.isValidEmail(testStr: email) && Utility.isValidPassword(testStr: password))
    }
    
}
