//
//  ChannelViewController.swift
//  SWSG
//
//  Created by Jeremy Jee on 23/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import Photos
import SwiftGifOrigin

/**
    ChannelViewController is a JSQMessagesViewController from the JSQMessagesViewController
    library. It displays the contents of a Channel, and relies on the UI from the library
    to do so.
 
    Specifications:
        - channel: Channel to be displayed
 */

final class ChannelViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var channel: Channel?
    fileprivate var client = System.client
    fileprivate var otherUser: User?
    fileprivate var imagePicker = ImagePickerPopoverViewController()
    fileprivate var iconIV = UIImageView()
    fileprivate var avatarCache = [String: UIImage]()
    fileprivate var tagMap = [Int: String]()
    fileprivate let imageURLNotSetKey = "NOTSET"
    fileprivate var localTyping = false
    fileprivate let notiPusher = NotiPusher()
    fileprivate var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef?.setValue(newValue)
        }
    }
    
    // MARK: JSQ Variables
    fileprivate var messages = [JSQMessage]()
    fileprivate var photoMessageMap = [String: JSQPhotoMediaItem]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    // MARK: Firebase References
    fileprivate var channelRef: FIRDatabaseReference!
    fileprivate var messageRef: FIRDatabaseReference!
    fileprivate var userIsTypingRef: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    
    // MARK: Firebase Handles
    fileprivate var channelRefHandle: FIRDatabaseHandle?
    fileprivate var newMessageRefHandle: FIRDatabaseHandle?
    fileprivate var updatedMessageRefHandle: FIRDatabaseHandle?
    
    // MARK: Firebase Queries
    fileprivate var usersTypingQuery: FIRDatabaseQuery!
    
    // MARK: Initialization Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let uid = client.getUid() else {
            Utility.logOutUser(currentViewController: self)
            return
        }
        
        self.senderId = uid
        setUpFirebase()
        setUpChannelInfo()
        
        let defaultAvatarSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault,
                                       height:kJSQMessagesCollectionViewAvatarSizeDefault )
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = defaultAvatarSize
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = defaultAvatarSize
        
        observeChannel()
        observeMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        observeTyping()
    }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
    private func setUpFirebase() {
        guard let channel = channel, let id = channel.id else {
            return
        }
        
        channelRef = client.getChannelRef(for: id)
        messageRef = client.getMessagesRef(for: channelRef)
        userIsTypingRef = client.getTypingRef(for: channelRef, by: senderId)
        storageRef = client.getStorageRef()
        usersTypingQuery = client.getQuery(at: channelRef!, for: Config.typingIndicator, equal: true)
    }
    
    private func setUpChannelInfo() {
        iconIV.frame.size = CGSize(width: Config.chatIconWidth, height: Config.chatIconWidth)
        iconIV = Utility.roundUIImageView(for: iconIV)
        iconIV.image = Config.placeholderImg
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: iconIV)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconIVTapped))
        iconIV.addGestureRecognizer(tapGesture)
        
        setInfo()
    }
    
    private func setInfo() {
        if let channel = channel, channel.type == .directMessage {
            Utility.getOtherUser(in: channel, completion: { (user) in
                if let user = user, let uid = user.uid {
                    self.title = user.profile.name
                    self.otherUser = user
                    
                    Utility.getProfileImg(uid: uid, completion: { (image) in
                        if let image = image {
                            self.iconIV.image = image
                        }
                    })
                }
            })
        } else {
            title = channel?.name
            
            guard let id = channel?.id else {
                return
            }
            
            Utility.getChatIcon(id: id, completion: { (image) in
                if let image = image {
                    self.iconIV.image = image
                }
            })
        }
    }
    
    func iconIVTapped(sender: UIGestureRecognizer) {
        if channel?.type != .directMessage {
            performSegue(withIdentifier: Config.channelToChannelInfo, sender: self)
        } else {
            guard let otherUser = otherUser else {
                return
            }
            
            performSegue(withIdentifier: Config.chatToProfile, sender: otherUser)
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: Config.themeColor)
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == Config.channelToChannelInfo,
            let dest = segue.destination as? ChannelInfoViewController,
            let channel = channel {
            dest.channel = channel
        } else if segue.identifier == Config.chatToProfile,
            let user = sender as? User, let dest = segue.destination as? ProfileViewController {
            dest.user = user
        }
    }
    
    // MARK: Message Display Methods
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if mediaItem.image == nil {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    func showFullImage(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else {
            return
        }
        
        let message = messages[tag]
        
        if message.isMediaMessage, let mediaData = message.media, let photoData = mediaData as? JSQPhotoMediaItem {
            let fullScreenImageView = UIImageView()
            fullScreenImageView.frame = self.view.frame
            fullScreenImageView.backgroundColor = .black
            fullScreenImageView.contentMode = .scaleAspectFit
            fullScreenImageView.isUserInteractionEnabled = true
            fullScreenImageView.image = photoData.image
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImage))
            fullScreenImageView.addGestureRecognizer(tap)
            self.view.addSubview(fullScreenImageView)
        }
        
    }
    
    func dismissFullScreenImage(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        sender.view?.removeFromSuperview()
    }
    
    // MARK: Message Sending Methods
    override func didPressSend(_ button: UIButton!, withMessageText text: String!,
                               senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            Config.senderId: senderId!,
            Config.senderName: senderDisplayName!,
            Config.text: text!,
            Config.timestamp: Utility.fbDateTimeFormatter.string(from: Date.init())
            ]
        
        itemRef.setValue(messageItem)
        notiPusher.sendMessageNoti(fromUsername: senderDisplayName, fromUserId: senderId, toChannel: channel!)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        isTyping = false
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        let completionHandler: (UIImage?) -> Void = { (image) in
            if let image = image, let key = self.sendPhotoMessage() {
                self.client.saveImage(image: image, completion: { (url, error) in
                    if error != nil {
                        return
                    } else if let url = url {
                        let itemRef = self.messageRef.child(key)
                        itemRef.updateChildValues([Config.image: url])
                    }
                })
            }
        }
        
        imagePicker.modalPresentationStyle = .overCurrentContext
        imagePicker.completionHandler = completionHandler
        
        present(imagePicker, animated: true, completion: nil)
        imagePicker.showImageOptions()
    }
    
    private func sendPhotoMessage() -> String? {
        guard let messageRef = messageRef else {
            return nil
        }
        
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            Config.image: imageURLNotSetKey,
            Config.senderName: senderDisplayName!,
            Config.senderId: senderId!,
            Config.timestamp: Utility.fbDateTimeFormatter.string(from: Date.init())
            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    // MARK: Firebase Observation Methods
    private func observeChannel() {
        channelRefHandle = channelRef.observe(.value, with: { (snapshot) in
            guard let channel = Channel(id: snapshot.key, snapshot: snapshot) else {
                return
            }
            
            self.channel = channel
            self.setInfo()
        })
    }
    
    private func observeMessages() {
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            guard let messageData = snapshot.value as? Dictionary<String, String> else {
                return
            }
            
            if let id = messageData[Config.senderId] as String!,
                let name = messageData[Config.senderName] as String!,
                let text = messageData[Config.text] as String!,
                text.characters.count > 0 {
                
                self.addMessage(withId: id, name: name, text: text)
                self.finishReceivingMessage()
            } else if let id = messageData[Config.senderId] as String!,
                let photoURL = messageData[Config.image] as String! {
                
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    self.fetchImageDataAtURL(photoURL: photoURL, mediaItem: mediaItem, key: snapshot.key)
                }
            }
        })
        
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            guard let messageData = snapshot.value as? [String: String] else {
                return
            }
            
            if let photoURL = messageData[Config.image] as String! {
                if let mediaItem = self.photoMessageMap[key] {
                    self.fetchImageDataAtURL(photoURL: photoURL, mediaItem: mediaItem, key: snapshot.key)
                }
            }
        })
    }
    
    private func fetchImageDataAtURL(photoURL: String, mediaItem: JSQPhotoMediaItem, key: String) {
        self.client.fetchImageDataAtURL(photoURL, completion: { (image, _) in
            guard let image = image else {
                return
            }
            
            mediaItem.image = image
            self.collectionView.reloadData()
            self.photoMessageMap.removeValue(forKey: key)
        })
    }
    
    // MARK: Typing Indicator Methods
    private func observeTyping() {
        userIsTypingRef = client.getTypingRef(for: channelRef, by: senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
}

// MARK: JSQMessagesCollectionView DataSource Methods
extension ChannelViewController {
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        let placeholder = JSQMessagesAvatarImageFactory
            .circularAvatarImage(Config.placeholderImg,
                                 withDiameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        
        if !avatarCache.keys.contains(message.senderId) {
            Utility.getProfileImg(uid: message.senderId, completion: { (image) in
                if let image = image {
                    let avatarImg = JSQMessagesAvatarImageFactory
                        .circularAvatarImage(image,
                                             withDiameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                    self.avatarCache[message.senderId] = avatarImg
                }
                
                self.collectionView.reloadItems(at: [indexPath])
            })
            
            return JSQMessagesAvatarImage(placeholder: placeholder)
        } else {
            let avatarImg = avatarCache[message.senderId]
            
            return JSQMessagesAvatarImage(placeholder: avatarImg)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        if shouldShowNameLabel(index: indexPath.item) {
            return NSAttributedString(string: message.senderDisplayName)
        } else {
            return nil
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        if shouldShowDateLabel(index: indexPath.item) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d/MM HH:mm"
            let dateString = formatter.string(from: message.date)
            
            return NSAttributedString(string: dateString)
        } else {
            return nil
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as?JSQMessagesCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showFullImage))
        cell.tag = indexPath.item
        cell.addGestureRecognizer(tap)
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView,
                                 layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout,
                                 heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        if shouldShowNameLabel(index: indexPath.item) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
                                 heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if shouldShowDateLabel(index: indexPath.item) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
}

// MARK: JSQMessagesCollectionView Delegate Methods
extension ChannelViewController {
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    fileprivate func shouldShowNameLabel(index: Int) -> Bool {
        let message = messages[index]
        
        if index > 0 {
            let previousMessage = messages[index - 1]
            
            if previousMessage.senderId == message.senderId || message.senderId == senderId {
                return false
            }
        }
        
        return true
    }
    
    fileprivate func shouldShowDateLabel(index: Int) -> Bool {
        let message = messages[index]
        
        if index > 0 {
            let previous = messages[index - 1]
            
            if message.date.lessThan(interval: Config.hourInterval, from: previous.date) {
                return false
            }
        }
        
        return true
    }
}
