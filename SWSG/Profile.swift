//
//  Profile.swift
//  SWSG
//
//  Created by shixiyue on 11/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase

/**
 Profile contains all the description and details about the User for his Profile Page
 
 Specifications:
 - username: The username of the User
 - name: The Name of the User
 - image: The Profile Image for the User
 - job: The User's Job/Position
 - company: The company where the user is currently working
 - country: The country the user is from
 - education: The user's education background
 - skills: The user's skills
 - desc: A short writeup about the user
 */
class Profile {
    public private (set) var username: String
    public private (set) var name: String
    public private (set) var image: UIImage?
    public private (set) var job: String
    public private (set) var company: String
    public private (set) var country: String
    public private (set) var education: String
    public private (set) var skills: String
    public private (set) var desc: String

    init(name: String, username: String, image: UIImage?, job: String, company: String, country: String,
         education: String, skills: String, description: String) {
        self.username = username
        self.name = name
        self.image = image
        self.job = job
        self.company = company
        self.country = country
        self.education = education
        self.skills = skills
        self.desc = description
        
        _checkRep()
    }
    
    init?(snapshotValue: [String: Any]) {
        guard let username = snapshotValue[Config.username] as? String else {
            return nil
        }
        self.username = username
        guard let name = snapshotValue[Config.name] as? String else {
            return nil
        }
        self.name = name
        guard let job = snapshotValue[Config.job] as? String else {
            return nil
        }
        self.job = job
        guard let company = snapshotValue[Config.company] as? String else {
            return nil
        }
        self.company = company
        guard let country = snapshotValue[Config.country] as? String else {
            return nil
        }
        self.country = country
        guard let education = snapshotValue[Config.education] as? String else {
            return nil
        }
        self.education = education
        guard let skills = snapshotValue[Config.skills] as? String else {
            return nil
        }
        self.skills = skills
        guard let desc = snapshotValue[Config.desc] as? String else {
            return nil
        }
        self.desc = desc
        guard let imageURL = snapshotValue[Config.image] as? String else {
            return
        }
        
        System.client.fetchImageDataAtURL(imageURL, completion: { (image, url) in
            if let image = image {
                self.image = image
            }
        })
    }
    
    func updateProfile(username: String,name: String, image: UIImage?, job: String, company: String, country: String, education: String, skills: String, description: String) {
        _checkRep()
        
        self.username = username
        self.name = name
        self.image = image
        self.job = job
        self.company = company
        self.country = country
        self.education = education
        self.skills = skills
        self.desc = description
        
        _checkRep()
    }
    
    func updateProfile(to profile: Profile) {
        updateProfile(username: profile.username, name: profile.name, image: profile.image, job: profile.job, company: profile.company, country: profile.country, education: profile.education, skills: profile.skills, description: profile.desc)
    }
    
    func updateImage(image: UIImage?) {
        _checkRep()
        self.image = image ?? Config.placeholderImg
        _checkRep()
    }
    
    func toDictionary() -> [String: Any] {
        return [Config.username: username, Config.name: name, Config.country: country, Config.job: job, Config.company: company, Config.education: education, Config.skills: skills, Config.desc: desc]
    }
    
    private func _checkRep() {
        #if DEBUG
        assert(!(name.isEmpty || country.isEmpty || job.isEmpty || company.isEmpty || education.isEmpty || skills.isEmpty || desc.isEmpty))
        #endif
    }
}
