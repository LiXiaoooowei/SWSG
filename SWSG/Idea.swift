//
//  Idea.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/23/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class Idea {
    
    var votes: Int { return upvotes.count - downvotes.count }
    var teamName: String { return "by Team \(Teams.sharedInstance().retrieveTeamAt(index: team).name)" }
    
    public private(set) var name: String
    public private(set) var team: Int
    public private(set) var description: String
    public private(set) var mainImage: UIImage
    public private(set) var images: [UIImage]
    public private(set) var videoLink: String
  
    private var upvotes: Set<String>
    private var downvotes: Set<String>
    
    convenience init(name: String, team: Int, description: String, mainImage: UIImage, images: [UIImage], videoLink: String) {
        self.init(name: name, team: team, description: description, mainImage: mainImage, images: images, videoLink: videoLink, upvotes: Set<String>(), downvotes: Set<String>())
    }
    
    init(name: String, team: Int, description: String, mainImage: UIImage, images: [UIImage], videoLink: String, upvotes: Set<String>, downvotes: Set<String>) {
        self.name = name
        self.team = team
        self.description = description
        self.mainImage = mainImage
        self.images = images
        self.videoLink = videoLink
        self.upvotes = upvotes
        self.downvotes = downvotes
    }
    
    func upvote() {
        let uid = System.client.getUid()
        guard !upvotes.contains(uid) else {
            upvotes.remove(uid)
            updateStorage()
            return
        }
        upvotes.insert(uid)
        if downvotes.contains(uid) {
            downvotes.remove(uid)
        }
        updateStorage()
    }
    
    func downvote() {
        let uid = System.client.getUid()
        guard !downvotes.contains(uid) else {
            downvotes.remove(uid)
            updateStorage()
            return
        }
        downvotes.insert(uid)
        if upvotes.contains(uid) {
            upvotes.remove(uid)
        }
        updateStorage()
    }
    
    private func updateStorage() {
        Ideas.sharedInstance().save()
    }
    
    func getVotingState() -> (upvote: Bool, downvote: Bool) {
        let uid = System.client.getUid()
        return (upvotes.contains(uid), downvotes.contains(uid))
    }
    
    func toDictionary() -> [String: Any] {
        return [Config.ideaName: self.name, Config.ideaTeam: self.team, Config.ideaDescription: self.description, Config.ideaVideo: self.videoLink, Config.upvotes: Array(upvotes), Config.downvotes: Array(downvotes)]
    }
    
    private func _checkRep() {
        assert(upvotes.intersection(downvotes).isEmpty)
    }

}
