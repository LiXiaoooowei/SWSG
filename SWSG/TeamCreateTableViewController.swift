//
//  TeamCreateTableViewController.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/18/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class TeamCreateTableViewController: UITableViewController {

    @IBOutlet weak var teamName: UITextField!
    @IBOutlet weak var lookingFor: PlaceholderTextView!
    @IBOutlet weak var tag: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var lookingForCellHeight = CGFloat(100)
    fileprivate var tags = [String]() {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tags"), object: self)
        }
    }
    fileprivate var sizingCell: TagCell?
    
    private let teamCreateErrorMsg = "Sorry, only participants of SWSG can create a team!"
    private let emptyFieldErrorMsg = "Fields cannot be empty!"
    private let mtplTeamErrorMsg = "You can not join more than 1 team!"
    private let emptyTagFieldErrorMsg = "Tag field cannot be empty!"
    private let emptySkillFieldErrorMsg =  "You must add a skill tag!"
    
    private let teams = Teams()
    private var containerHeight = CGFloat(100)
    
    @IBAction func onSaveBtnClick(_ sender: Any) {
        guard let tagToAdd = tag.text?.trim(), !tagToAdd.isEmpty else {
            present(Utility.getFailAlertController(message: emptyTagFieldErrorMsg), animated: true, completion: nil)
            return
        }
        tags.append(tagToAdd)
        tag.text = ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        collectionView.delegate = self
        lookingFor.setPlaceholder("Skills looking for...")
        lookingFor.delegate = self
        tableView.separatorStyle = .none
        let cellNib = UINib(nibName: "TagCell", bundle: nil)
        self.collectionView.register(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.collectionView.backgroundColor = UIColor.clear
        self.sizingCell = (cellNib.instantiate(withOwner: nil, options: nil) as NSArray).firstObject as! TagCell?
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name(rawValue: "tags"), object: nil)
        self.hideKeyboardWhenTappedAround()
        teamName.inputAccessoryView = Utility.getDoneToolbar(done: #selector(donePressed))
        tag.inputAccessoryView = Utility.getDoneToolbar(done: #selector(donePressed))
        lookingFor.inputAccessoryView = Utility.getDoneToolbar(done: #selector(donePressed))
    }
    
    @IBAction func onDoneButtonClick(_ sender: Any) {
        guard let user = System.activeUser, user.type.isParticipant else {
            self.present(Utility.getFailAlertController(message: teamCreateErrorMsg), animated: true, completion: nil)
            return
        }
        guard System.activeUser?.team == Config.noTeam else {
            self.present(Utility.getFailAlertController(message: mtplTeamErrorMsg),animated: true, completion: nil)
            return
        }
        guard let name = teamName.text, let looking = lookingFor.text, !name.isEmpty, !looking.isEmpty else {
            self.present(Utility.getFailAlertController(message: emptyFieldErrorMsg),animated: true, completion: nil)
            return
        }
        guard !tags.isEmpty else {
            self.present(Utility.getFailAlertController(message: emptySkillFieldErrorMsg),animated: true, completion: nil)
            return
        }
        guard let uid = user.uid else {
            return
        }
        let team = Team(id: "", members: [uid], name: name, lookingFor: looking, isPrivate: false, tags: tags)
        System.client.createTeam(_team: team, completion: { (error) in
            if let firebaseError = error {
                self.present(Utility.getFailAlertController(message: firebaseError.errorMessage), animated: true, completion: nil)
                return
            }
        })
        teams.addTeam(team: team)
        guard let teamId = team.id else {
            return
        }
        user.setTeamId(id: teamId)
        System.client.updateUser(newUser: user)
        System.activeUser = user
        Utility.popViewController(no: 1, viewController: self)
    }

    @IBAction func onBackBtnClick(_ sender: Any) {
        Utility.onBackButtonClick(tableViewController: self)
    }
    
    @objc private func reload() {
        self.tableView.beginUpdates()
        if collectionView.contentSize.height > containerHeight {
            containerHeight = collectionView.contentSize.height
        }
        collectionView.reloadData()
        self.tableView.endUpdates()
    }
    
    @objc private func donePressed() {
        self.view.endEditing(true)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return 150
        }else if indexPath.item == 2 {
            return CGFloat(containerHeight)
        } else if indexPath.item == 3 {
            return lookingForCellHeight
        }else {
            return 60
        }
    }
    
}

extension TeamCreateTableViewController: UICollectionViewDelegate {
}

extension TeamCreateTableViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        self.configureCell(cell: cell, forIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: TagCell, forIndexPath indexPath: IndexPath) {
        let tag = tags[indexPath.row]
        cell.tagName.text = tag
    }
   }

extension TeamCreateTableViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        self.configureCell(cell: self.sizingCell!, forIndexPath: indexPath)
        let size = self.sizingCell!.tagName.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        return CGSize(width: size.width, height: size.height*2)
    }
}

extension TeamCreateTableViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textView = textView as? PlaceholderTextView, let currentText = textView.text else {
            return false
        }
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        if updatedText.isEmpty {
            textView.setPlaceholder()
            return false
        } else if textView.textColor == Config.placeholderColor && !text.isEmpty {
            textView.removePlaceholder()
        }
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard view.window != nil, textView.textColor == Config.placeholderColor else {
            return
        }
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.tableView.beginUpdates()
        if textView.contentSize.height > CGFloat(60) {
            self.lookingForCellHeight = textView.contentSize.height
        }
        self.tableView.endUpdates()
    }
}




