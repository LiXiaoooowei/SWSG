//
//  ProfileViewController.swift
//  SWSG
//
//  Created by shixiyue on 17/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class ProfileViewController: ImagePickerViewController {

    @IBOutlet private var profileImgButton: UIButton!
    @IBOutlet private var nameLbl: UILabel!
    @IBOutlet private var usernameLbl: UILabel!
    @IBOutlet private var teamLbl: UILabel!
    @IBOutlet fileprivate var profileList: UITableView!

    private let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setUpProfileList()
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        profileList.reloadData()
        setUpUserInfo()
    }
    
    private func setUpProfileList() {
        profileList.tableFooterView = UIView(frame: CGRect.zero)
        profileList.allowsSelection = false
    }
    
    private func setUpUserInfo() {
        guard let user = System.activeUser else {
            Utility.logOutUser(currentViewController: self)
            return
        }
        
        profileImgButton.setImage(user.profile.image, for: .normal)
        profileImgButton.addTarget(self, action: #selector(showImageOptions), for: .touchUpInside)
        alertControllerPosition = CGPoint(x: view.frame.width / 2, y: profileImgButton.bounds.maxY)
        
        nameLbl.text = user.profile.name
        usernameLbl.text = "@\(user.profile.username)"
        
        guard user.profile.type.isParticipant else {
            teamLbl.text = user.profile.type.toString()
            return
        }
        if user.profile.team != -1 {
            teamLbl.text = Teams.sharedInstance().retrieveTeamAt(index: user.profile.team).name
        } else {
            teamLbl.text = Config.noTeamLabel
        }
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    
    override func updateImage(_ notification: NSNotification) {
        guard let image = notification.userInfo?[Config.image] as? UIImage else {
            return
        }
        
        guard let user = System.activeUser else {
            Utility.logOutUser(currentViewController: self)
            return
        }
        user.profile.updateImage(image: image)
        System.updateActiveUser()
        // Error handling?
        System.client.updateProfile(newProfile: user.profile)
        
        NotificationCenter.default.removeObserver(self)
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProfileItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.item
        let (field, content) = ProfileItems.items[index]
        
        guard let cell = profileList.dequeueReusableCell(withIdentifier: Config.profileCell, for: indexPath) as? ProfileTableViewCell else {
            return ProfileTableViewCell()
        }
        
        cell.field.text = field
        cell.content.text = content
        return cell
    }
    
}
