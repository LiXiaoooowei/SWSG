//
//  OverviewViewController.swift
//  SWSG
//
//  Created by Shi Xiyue on 25/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

/**
 TemplateViewController is a UITableViewController, inherits from UITableViewController.
 
 It provides a template layout to display information.
 */
class TemplateViewController: UITableViewController {

    // MARK: IBOutlet
    @IBOutlet private var templateTableView: UITableView!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var video: UIWebView!
    
    // MARK: Property
    fileprivate let imagesRowIndex = 1
    fileprivate let videoRowIndex = 2
    fileprivate var content: TemplateContent!
    fileprivate var photoPageViewController: PhotoPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUptemplateTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Config.images, let photoPageViewController = segue.destination as? PhotoPageViewController else {
            return
        }
        photoPageViewController.images = content.images
        self.photoPageViewController = photoPageViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUp()
    }
    
    private func setUptemplateTableView() {
        templateTableView.tableFooterView = UIView(frame: CGRect.zero)
        templateTableView.allowsSelection = false
        templateTableView.isScrollEnabled = false
        templateTableView.layoutIfNeeded()
    }
    
    func setUp() {
        loadYoutube()
        descriptionLabel.text = content.description
        updateImages()
        templateTableView.reloadData()
    }
    
    func presetInfo(content: TemplateContent) {
        self.content = content
    }
    
    func updateImages() {
        photoPageViewController.images = content.images
        photoPageViewController.setUpPageViewController()
        templateTableView.reloadData()
    }
    
    private func loadYoutube() {
        guard let youtubeURL = URL(string: content.videoLink) else {
            return
        }
        video.loadRequest(URLRequest(url: youtubeURL))
    }

}

// MARK: UITableViewDelegate
extension TemplateViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == imagesRowIndex && content.images.count == 0) || (indexPath.row == videoRowIndex && content.videoLink.isEmpty) {
            return 0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
}
