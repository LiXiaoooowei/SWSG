//
//  Ideas.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/23/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation
class Ideas {
    private static var ideasInstance = Ideas()
    private var ideas : [Idea] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ideas"), object: self)
            print("saving ideas")
           // Storage.saveTeams(data: teams, fileName: "Teams")
        }
    }
    
    private init() {
        print("reading from storage for ideas")
       // self.ideas = Storage.readTeams(fileName: "Ideas") ?? [Idea]()
        self.ideas = [Idea]()
    }
    
    class func sharedInstance() -> Ideas {
        return ideasInstance
    }
    
    public func addIdea(idea: Idea) {
        ideas.append(idea)
    }
    
    public func retrieveIdeaAt(index: Int) -> Idea {
        return ideas[index]
    }
    
    public func replaceTeamAt(index: Int, with idea: Idea) {
        ideas[index] = idea
    }
    
    public var count: Int {
        get {
            return ideas.count
        }
    }
    
}