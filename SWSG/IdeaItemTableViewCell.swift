//
//  IdeaItemTableViewCell.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/23/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

/**
 IdeaItemCell is a UITableViewCell that is used in IdeaListViewController
 to display information about a Idea
 
 It has a Name Label, a Idea Image View, a Description Label, a User Label,
 a Votes Label, an UpvoteButton and a DownVoteButton.
 */
class IdeaItemTableViewCell: UITableViewCell {
    
    // MARK: IBOutlets
    @IBOutlet private var name: UILabel!
    @IBOutlet private var desc: UILabel!
    @IBOutlet private var user: UILabel!
    @IBOutlet private var ideaImageView: UIImageView!
    @IBOutlet private var votes: UILabel!
    @IBOutlet private var upvoteButton: UIButton!
    @IBOutlet private var downvoteButton: UIButton!
    
    // MARK: Properties
    private var idea: Idea!
    
    // MARK: Set up the content of the cell
    func setIdea(_ idea: Idea) {
        self.idea = idea
        name.text = idea.name
        desc.text = idea.description
        ideaImageView.image = idea.mainImage
        Utility.getUserFullName(uid: idea.user, label: user, prefix: Config.ideaUserNamePrefix)
        Utility.updateVotes(idea: idea, votesLabel: votes, upvoteButton: upvoteButton, downvoteButton: downvoteButton)
    }
    
    // MARK: Handle upvote action
    @IBAction func upvote(_ sender: UIButton) {
        guard System.client.isConnected else {
            UIApplication.shared.keyWindow?.rootViewController?.present(Utility.getNoInternetAlertController(),
                                                                        animated: true, completion: nil)
            return
        }
        idea.upvote()
    }
    
    // MARK: Handle downvote action
    @IBAction func downvote(_ sender: UIButton) {
        guard System.client.isConnected else {
            UIApplication.shared.keyWindow?.rootViewController?.present(Utility.getNoInternetAlertController(), animated: true, completion: nil)
            return
        }
        idea.downvote()
    }
    
}
