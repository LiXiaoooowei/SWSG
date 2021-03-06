//
//  CreateChannelViewController.swift
//  SWSG
//
//  Created by Jeremy Jee on 23/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase

/**
    CreateChannelViewController is a UIViewController that presents a form for
    a user to create a Public or Private Channel
 
    Specifications:
        - isPublic: Bool of whether the channel is a Public or Private channel
 */

class CreateChannelViewController: UIViewController {
    
    //MARK: IBOutlets
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var memberTF: UITextField!
    @IBOutlet weak var addBtn: RoundCornerButton!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var memberList: UITableView!
    @IBOutlet weak var iconIV: UIImageView!
    @IBOutlet weak var headerLbl: UILabel!
    @IBOutlet weak var membersHeaderLbl: UILabel!

    //MARK: Properties
    var isPublic = false
    fileprivate let client = System.client
    fileprivate var members = [User]()
    fileprivate var iconAdded = false
    fileprivate var imagePicker = ImagePickCropperPopoverViewController()
    
    //MARK: Initialization Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        setUpTextFieldAndButtons()
        setUpMemberList()
        setUpIcon()
    }
    
    fileprivate func setUpLayout() {
        if isPublic {
            headerLbl.text = Config.createPublicHeaderLabel
            membersHeaderLbl.isHidden = true
            memberTF.isHidden = true
            addBtn.isHidden = true
            memberList.isHidden = true
        }
    }
    
    fileprivate func setUpTextFieldAndButtons() {
        nameTF.delegate = self
        memberTF.delegate = self
        doneBtn.isEnabled = false
        
        btnNotifier(textField: nameTF, button: doneBtn)
        btnNotifier(textField: memberTF, button: addBtn)
        
        addDoneToolbar(textField: nameTF)
        addDoneToolbar(textField: memberTF)
        
        self.hideKeyboardWhenTappedAround()
    }
    
    fileprivate func setUpMemberList() {
        guard let activeUser = System.activeUser else {
            return
        }
        
        members.append(activeUser)
        
        memberList.delegate = self
        memberList.dataSource = self
        
    }
    
    fileprivate func setUpIcon() {
        iconIV = Utility.roundUIImageView(for: iconIV)
        iconIV.image = Config.placeholderImg
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showImagePicker))
        iconIV.addGestureRecognizer(gestureRecognizer)
        editBtn.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        
    }
    
    fileprivate func addDoneToolbar(textField: UITextField) {
        textField.inputAccessoryView = Utility.getDoneToolbar(done: #selector(donePressed))
    }
    
    func donePressed() {
        self.view.endEditing(true)
    }
    
    //MARK: IBOutlet Methods
    
    /**
        Function to handle Save Button Pressed
     
        Specifications:
            - Check that the Name is not empty
            - Check that if it is a Private Channel there must be more than 1 member
     */
    @IBAction func saveBtnPressed(_ sender: Any) {
        guard let name = nameTF.text else {
            return
        }
        
        guard members.count > 1 || isPublic else {
            Utility.displayDismissivePopup(title: "Not Enough Members", message: "You need at least 1 other member", viewController: self, completion: { _ in })
            return
        }
        
        var memberUIDs = [String]()
        
        for member in members {
            guard let uid = member.uid else {
                continue
            }
            
            memberUIDs.append(uid)
        }
        
        var image: UIImage? = nil
        
        if iconAdded {
            image = iconIV.image
        }
        
        let channel: Channel
         
        if isPublic {
            channel = Channel(id: nil, type: .publicChannel, icon: image, name: name,
                              members: memberUIDs)
        } else {
            channel = Channel(id: nil, type: .privateChannel, icon: image, name: name,
                              members: memberUIDs)
        }
        
        client.createChannel(for: channel, completion: { (channel, error) in
            Utility.popViewController(no: 1, viewController: self)
            
        })
        
    }
    
    @IBAction func addBtnPressed(_ sender: Any) {
        addMember()
    }
    
    /**
        Add a Member to the Channel
     
        Specfications:
            - Check if Username Exists
     */
    fileprivate func addMember() {
        guard let username = memberTF.text else {
            return
        }
        
        client.getUserWith(username: username, completion: { (user, error) in
            guard let user = user, let uid = user.uid else {
                Utility.displayDismissivePopup(title: "Error",
                                               message: "Username does not exist!",
                                               viewController: self, completion: { _ in })
                return
            }
            
            for member in self.members {
                guard member.uid != user.uid else {
                    Utility.displayDismissivePopup(title: "Error",
                                                   message: "Username already added",
                                                   viewController: self, completion: { _ in })
                    return
                }
            }
            
            Utility.getProfileImg(uid: uid, completion: { (image) in
                user.profile.updateImage(image: image)
                self.memberList.reloadData()
            })
            
            self.members.append(user)
            self.memberList.reloadData()
            self.memberTF.text = ""
            self.view.endEditing(true)
        })
    }
    
    func showImagePicker() {
        Utility.showImagePicker(imagePicker: imagePicker, viewController: self, completion: { (image) in
            if let image = image {
                self.iconIV.image = image
                self.iconAdded = true
            }
        })
    }
    
    private func btnNotifier(textField: UITextField, button: Any) {
        guard (button is UIButton || button is UIBarButtonItem) else {
            return
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UITextFieldTextDidChange,
            object: textField, queue: OperationQueue.main) { _ in
                guard var text = textField.text else {
                    return
                }
                text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                if let button = button as? UIButton {
                    if text != "" {
                        button.isEnabled = true
                    } else {
                        button.isEnabled = false
                    }
                } else if let button = button as? UIBarButtonItem {
                    if text != "" {
                        button.isEnabled = true
                    } else {
                        button.isEnabled = false
                    }
                }
                
        }
    }
}

// MARK: UITextFieldDelegate
extension CreateChannelViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == memberTF {
            addMember()
        }
        
        self.view.endEditing(true)
        return false
    }
}

// MARK: UITableViewDataSource
extension CreateChannelViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Config.memberCell,
                                                      for: indexPath) as? MemberCell else {
                                                        return MemberCell()
        }
        
        let index = indexPath.item
        let member = members[index]
        
        cell.iconIV.image = member.profile.image
        cell.iconIV = Utility.roundUIImageView(for: cell.iconIV)
        cell.nameLbl.text = "\(member.profile.name) (@\(member.profile.username))"
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension CreateChannelViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            members.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.item == 0 {
            return false
        } else {
            return true
        }
    }

}


