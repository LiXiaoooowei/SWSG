//
//  User.swift
//  SWSG
//
//  Created by shixiyue on 11/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation
import Firebase

/**
 User contains the essential information about the user account, such as
 email, type, team as well as optional values depending on the user type like
 mentor
 
 Specifications:
 - email: The email of the User
 - profile: The Profile of the User
 - type: The UserType
 - team: The User's Team
 - mentor: Mentor Specific Variables like ConsultationSlot
 - uid: ID for the User as assigned by Firebase
 - favourites: An array of user IDs that have been favourited by the user
 
 Representation Invariant:
 - Email must be valid
 - Non-Participants must not have teams
 - If not a mentor, the Mentor variable should be nil
 */
class User {
    
    let email: String
    public private (set) var profile: Profile
    public private (set) var type: UserTypes
    public private (set) var team = Config.noTeam
    public private (set) var mentor: Mentor?
    public private (set) var uid: String?
    public private (set) var favourites: [String]?
    
    init(profile: Profile, type: UserTypes, team: String, email: String) {
        self.type = type
        self.team = team
        self.profile = profile
        self.email = email
        
        _checkRep()
    }
    
    convenience init(profile: Profile, type: UserTypes, email: String) {
        self.init(profile: profile, type: type, team: Config.noTeam, email: email)
    }
    
    init?(uid: String, snapshot: FIRDataSnapshot) {
        self.uid = uid
        
        guard let snapshotValue = snapshot.value as? [String: AnyObject] else {
            return nil
        }
        guard let userTypes = snapshotValue[Config.userType] as? [String: Bool], let isParticipant = userTypes[Config.isParticipant], let isSpeaker = userTypes[Config.isSpeaker], let isMentor = userTypes[Config.isMentor], let isOrganizer = userTypes[Config.isOrganizer], let isAdmin = userTypes[Config.isAdmin] else {
            return nil
        }
        self.type = UserTypes(isParticipant: isParticipant, isSpeaker: isSpeaker, isMentor: isMentor, isOrganizer: isOrganizer, isAdmin: isAdmin)

        if let team = snapshotValue[Config.team] as? String {
            self.team = team
        }
        
        guard let profileSnapshot = snapshotValue[Config.profile] as? [String: Any], let profile = Profile(snapshotValue: profileSnapshot) else {
            return nil
        }
        self.profile = profile
        guard let email = snapshotValue[Config.email] as? String else {
            return nil
        }
        self.email = email
        if let mentorSnapshot = snapshotValue[Config.mentor] as? [String: Any], let mentor = Mentor(snapshot: mentorSnapshot) {
            self.mentor = mentor
        }
        if let favourites = snapshotValue[Config.favourites] as? [String] {
            self.favourites = favourites
        }
    }
    
    var hasTeam: Bool {
        return team != Config.noTeam
    }
    
    func setTeamId(id: String) {
        guard type.isParticipant else {
            return
        }
        team = id
    }
    
    func setMentor(mentor: Mentor) {
        guard type.isMentor else {
            return
        }
        self.mentor = mentor
    }
    
    func setFavourites(favourites: [String]?) {
        self.favourites = favourites
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [Config.userType: type.toDictionary(), Config.team: team, Config.email: email, Config.profile: profile.toDictionary()]
        
        
        if let mentor = mentor {
            dict[Config.mentor] = mentor.toDictionary()
        }
        
        if let favourites = favourites {
            dict[Config.favourites] = favourites
        }
        
        return dict
    }
    
    // Assumption: type, profile and team have met their representation invariants.
    private func _checkRep() {
        #if DEBUG
        assert (Utility.isValidEmail(testStr: email))
        if !type.isParticipant {
            assert(team == Config.noTeam)
        }
        if !type.isMentor {
            assert(mentor == nil)
        }
        #endif
    }
    
    // this method is for unit testing with teams only, not called elsewhere
    func setUid(uid: String) {
        self.uid = uid
    }
    
}

extension User: Equatable { }

func ==(lhs: User, rhs: User) -> Bool {
    
    if let lhsId = lhs.uid, let rhsId = rhs.uid {
        return lhsId == rhsId
    }
    return false
}
