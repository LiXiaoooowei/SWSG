//
//  IdeaDetailsTableViewController.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/23/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class IdeaDetailsTableViewController: UITableViewController {
    
    var idea: Idea!
    var containerHeight: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(TeamRegistrationTableViewController.update), name: Notification.Name(rawValue: "commentsForIdeas"), object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "container", let containerViewController = segue.destination as? OverviewViewController else {
            return
        }
        containerViewController.presetInfo(desc: idea.description, images: idea.images, videoLink: idea.videoLink)
        containerViewController.tableView.layoutIfNeeded()
        containerHeight = containerViewController.tableView.contentSize.height
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return 96
        case 3: return containerHeight
        default: return 44
        }
    }
    
    
    
}
