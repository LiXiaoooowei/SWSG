//
//  EventDetailsTableViewController.swift
//  SWSG
//
//  Created by Li Xiaowei on 3/16/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase

/**
    EventDetailsTableViewController is a UITableViewController that displays
    the details of an event.
 
    Specifications:
        - event: The Event to be displayed
 */

class EventDetailsTableViewController: UITableViewController {

    //MARK: IBOutlets
    @IBOutlet weak var eventDetailsTableView: UITableView!
    @IBOutlet weak var titleImageIV: UIImageView!
    
    //MARK: Properties
    public var event : Event?
    fileprivate var containerHeight: CGFloat!
    fileprivate var imageIVSize: CGSize!
    fileprivate var events = Events.instance
    fileprivate var commenters = [Int: User]()
    
    //MARK: Firebase References
    private var eventRef: FIRDatabaseReference!
    private var eventChangedHandle: FIRDatabaseHandle?
    
    //MARK: Initialization Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        hideKeyboardWhenTappedAround()
        observeEvent()
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: Notification.Name(rawValue: "comments"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpImageView()
    }
    
    private func setUpTable() {
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        imageIVSize = self.titleImageIV.frame.size
        self.titleImageIV.frame.size = CGSize.zero
    }
    
    private func setUpImageView() {
        guard let event = event, let id = event.id else {
            return
        }
        
        Utility.getEventIcon(id: id, completion: { (image) in
            if let img = image {
                self.titleImageIV.image = img
                self.titleImageIV.isHidden = false
                self.titleImageIV.frame.size = self.imageIVSize
                self.eventDetailsTableView.reloadData()
            }
        })
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == Config.eventToProfile, let user = sender as? User {
            guard let profileVC = segue.destination as? ProfileViewController else {
                return
            }
            profileVC.user = user
        }
    }
    
    //MARK: Firebase Functions
    private func observeEvent() {
        guard let event = event else {
            return
        }
        
        eventRef = System.client.getEventRef(event: event)
        eventChangedHandle = eventRef.observe(.value, with: { (snapshot) in
            guard let event = Event(id: snapshot.key, snapshot: snapshot) else {
                return
            }
            self.event = event
            self.setUpImageView()
            self.eventDetailsTableView.reloadData()
            
        })
    }
    
    //MARK: User Interaction Functions
    @IBAction func onAddCalendarBtnClicked(_ sender: Any) {
        guard let event = event else{
            return
        }
        Utility.addEventToCalendar(title: event.name, description: event.description, startDate: event.startDateTime, endDate: event.endDateTime)
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func hideNavBarTapHandler(recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            self.navigationItem.hidesBackButton = !self.navigationItem.hidesBackButton
            self.navigationController?.setNavigationBarHidden(self.navigationItem.hidesBackButton, animated: true)
        }
    }
    
    func showProfile(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else {
            return
        }
        let tag = view.tag
        performSegue(withIdentifier: Config.eventToProfile, sender: commenters[tag])
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// UITableViewDelegate methods
extension EventDetailsTableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventHeader") as! EventHeaderTableViewCell
            cell.eventHeaderLabel.text = self.event?.name
            return cell.contentView
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsHeader")
            return cell?.contentView
        }
    }
}

// UITableViewDataSource methods
extension EventDetailsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 5
        } else {
            guard let event = event else {
                return 1
            }
            return event.comments.count + 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let event = event else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "EventTime", for: indexPath) as! EventTimeTableViewCell
                let formatter = Utility.fbTimeFormatter
                let startString = formatter.string(from: event.startDateTime)
                let endString = formatter.string(from: event.endDateTime)
                cell.timeLabel.text = "\(startString) to \(endString)"
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "EventVenue", for: indexPath) as! EventVenueTableViewCell
                cell.venueLabel.text = event.venue
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "EventDetail", for: indexPath) as! EventDetailTableViewCell
                cell.detailsLabel.text = event.description
                return cell
            default:
                return UITableViewCell()
            }
        } else {
            if indexPath.row == event.comments.count ||
                (indexPath.row == 0 && event.comments.count == 0) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsInput", for: indexPath) as! CommentsInputTableViewCell
                cell.commentInputField.delegate = self
                cell.event = event
                cell.commentInputField.setPlaceholder("Add a Comment")
                cell.commentInputField.delegate = cell
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Comments", for: indexPath) as! CommentsTableViewCell
                let comment = event.comments[indexPath.row]
                
                cell.usernameLabel.text = ""
                cell.profileIV = Utility.roundUIImageView(for: cell.profileIV)
                cell.profileIV.image = Config.placeholderImg
                cell.profileIV.tag = indexPath.row
                cell.profileIV.isUserInteractionEnabled = true
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showProfile))
                cell.profileIV.addGestureRecognizer(tapGesture)
                
                System.client.getUserWith(uid: comment.authorID, completion: { (user, error) in
                    guard let user = user, let uid = user.uid else {
                        return
                    }
                    
                    self.commenters[indexPath.row] = user
                    let dateString = Utility.niceDateTimeFormatter.string(from: comment.timestamp)
                    cell.usernameLabel.text = "\(user.profile.username) on \(dateString)"
                    
                    Utility.getProfileImg(uid: uid, completion: { (image) in
                        guard let image = image else {
                            return
                        }
                        
                        cell.profileIV.image = image
                    })
                })
                cell.commentsLabel.text = comment.text
                
                return cell
            }
        }
    }

}

extension EventDetailsTableViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textView.translatesAutoresizingMaskIntoConstraints = true
        var size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        guard size.height != textView.frame.size.height else {
            return
        }
        size.width = size.width > textView.frame.size.width ? size.width : textView.frame.size.width
        textView.frame.size = size
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard let textView = textView as? GrayBorderTextView, let currentText = textView.text else {
            return false
        }
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        if updatedText.isEmpty {
            textView.setPlaceholder()
            return false
        } else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.removePlaceholder()
        }
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard view.window != nil, textView.textColor == UIColor.lightGray else {
            return
        }
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
    }
    
}
