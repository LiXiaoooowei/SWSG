//
//  FirebaseClient.swift
//  SWSG
//
//  Created by dinhvt on 25/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation
import Firebase
import FacebookCore
import FacebookLogin
import OneSignal

class FirebaseClient {
    
    typealias CreateUserCallback = (FirebaseError?) -> Void
    typealias SignInCallback = (FirebaseError?) -> Void
    typealias UserAuthCallback = (FirebaseError?) -> Void
    typealias GetFBUserCallback = (FBUser?, FirebaseError?) -> Void
    typealias GetUserCallback = (User?, FirebaseError?) -> Void
    typealias CheckEmailCallback = ([String]?, FirebaseError?) -> Void
    typealias GetMentorsCallback = ([User], FirebaseError?) -> Void
    typealias CreateTeamCallback = (FirebaseError?) -> Void
    typealias CreateEventCallback = (FirebaseError?) -> Void
    typealias GeneralIdeaCallback = (FirebaseError?) -> Void
    typealias GetChannelCallback = (Channel?, FirebaseError?) -> Void
    typealias GetMessageCallback = (Message, FirebaseError?) -> Void
    typealias GetEventCallback = (Event, FirebaseError?) -> Void
    typealias GetEventByDayCallback = ([Event], FirebaseError?) -> Void
    typealias ImageURLCallback = (String?, FirebaseError?) -> Void
    typealias ImageCallback = (UIImage?, String?) -> Void
    
    var isConnected: Bool = false
    
    private let usersRef = FIRDatabase.database().reference(withPath: "users")
    private let teamsRef = FIRDatabase.database().reference(withPath: "teams")
    private let eventsRef = FIRDatabase.database().reference(withPath: "events")
    private let ideasRef = FIRDatabase.database().reference(withPath: "ideas")
    private let storageRef = FIRStorage.storage().reference(forURL: Config.appURL)
    private let auth = FIRAuth.auth()
    
    init() {
        let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                self.isConnected = true
            } else {
                self.isConnected = false
            }
        })
    }
    
    public func createNewUser(_ user: User, email: String, password: String, completion: @escaping CreateUserCallback) {
        auth?.createUser(withEmail: email, password: password, completion: {(firUser, err) in
            if err == nil, let uid = firUser?.uid {
                self.createUserAccount(uid: uid, user: user, completion: completion)
            }
            completion(self.checkError(err))
        })
        
    }
    
    public func createNewUser(_ user: User, credential: FIRAuthCredential, completion: @escaping CreateUserCallback) {
        auth?.signIn(with: credential) { (firUser, err) in
            if err == nil, let uid = firUser?.uid {
                self.createUserAccount(uid: uid, user: user, completion: completion)
            }
            completion(self.checkError(err))
        }
    }
    
    public func signIn(email: String, password: String, completion: @escaping SignInCallback) {
        auth?.signIn(withEmail: email, password: password, completion: {(user, err) in
            OneSignal.syncHashedEmail(email)
            completion(self.checkError(err))
        })
    }
    
    public func signIn(credential: FIRAuthCredential, completion: @escaping SignInCallback) {
        auth?.signIn(with: credential) { (user, err) in
            completion(self.checkError(err))
        }
    }
    
    public func createUserAccount(uid: String, user: User, completion: @escaping CreateUserCallback) {
        let userRef = self.usersRef.child(uid)
        userRef.setValue(user.toDictionary() as Any)
        
        if let img = user.profile.image {
            self.saveImage(image: img, completion: { (photoURL, error) in
                userRef.child(Config.profile).child(Config.image).setValue(photoURL)
                completion(nil)
            })
        }
        
        completion(nil)
    }
    
    public func fbSignIn(completion: @escaping SignInCallback){
        guard let token = AccessToken.current else {
            return
        }
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
        
        signIn(credential: credential, completion: { (error) in
            completion(error)
        })
    }
    
    public func getFBProfile(completion: @escaping GetFBUserCallback) {
        let connection = GraphRequestConnection()
        connection.add(FBRequest()) { response, result in
            switch result {
            case .success(let response):
                completion(response.user, nil)
            case .failed(let error):
                print("Custom Graph Request Failed: \(error)")
                completion(nil, nil)
            }
        }
        connection.start()
    }
    
    public func alreadySignedIn() -> Bool {
        if let _ = auth?.currentUser {
            return true
        } else if let _ = AccessToken.current {
            return true
        } else {
            return false
        }
    }
    
    //TEMP SOLUTION
    public func signOut() {
        do {
            try auth?.signOut()
        } catch {
            return
        }
    }
    
    public func checkIfEmailAlreadyExists(email: String, completion: @escaping CheckEmailCallback) {
        auth?.fetchProviders(forEmail: email, completion: { (arr, err) in
            completion(arr, nil)
        })
    }
    
    func reauthenticateUser(email: String, password: String, completion: @escaping UserAuthCallback) {
        let user = auth?.currentUser
        let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
        
        user?.reauthenticate(with: credential) { error in
            completion(self.checkError(error))
        }
    }
    
    func changePassword(newPassword: String, completion: @escaping UserAuthCallback) {
        auth?.currentUser?.updatePassword(newPassword) { error in
            completion(self.checkError(error))
        }
    }
    
    public func getMentors(completion: @escaping GetMentorsCallback) {
        let mentorRef = usersRef.queryOrdered(byChild: "\(Config.userType)/\(Config.isMentor)")
                                .queryEqual(toValue: true)
        mentorRef.observeSingleEvent(of: .value, with: {(snapshot) in
            var mentors = [User]()
            for mentor in snapshot.children {
                guard let mentor = mentor as? FIRDataSnapshot, let user = User(snapshot: mentor) else {
                    continue
                }
                
                user.setUid(uid: mentor.key)
                mentors.append(user)
            }
            completion(mentors, nil)
        })
    }
    
    public func getCurrentUser(completion: @escaping GetUserCallback) {
        guard let uid = auth?.currentUser?.uid else {
            completion(nil, nil)
            return
        }
        getUserWith(uid: uid, completion: completion)
    }

    public func getUserWith(uid: String, completion: @escaping GetUserCallback) {
        let userRef = usersRef.child(uid)
        // TODO: handle error
        userRef.observeSingleEvent(of: .value, with: {(snapshot) in
            guard let user = User(snapshot: snapshot) else {
                completion(nil, nil)
                return
            }
            user.setUid(uid: uid)
            completion(user, nil)
        })
    }
    
    public func getUserWith(username: String, completion: @escaping GetUserCallback) {
        let userRef = usersRef
            .queryOrdered(byChild: "\(Config.profile)/\(Config.username)").queryEqual(toValue: username)
        userRef.observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.children.allObjects.count == 0 {
                completion(nil, nil)
            } else {
                var userAcct: User?
                for userSnapshot in snapshot.children {
                    guard let userSnapshot = userSnapshot as? FIRDataSnapshot,
                        let user = User(snapshot: userSnapshot) else {
                        continue
                    }
                    
                    user.setUid(uid: userSnapshot.key)
                    userAcct = user
                }
                
                completion(userAcct, nil)
            }
        })
    }
    
    public func updateUser(newUser: User) {
        guard let uid = auth?.currentUser?.uid else {
            return
        }
        let userRef = usersRef.child(uid)
        userRef.setValue(newUser.toDictionary() as Any)
        
        if let img = newUser.profile.image {
            self.saveImage(image: img, completion: { (photoURL, error) in
                userRef.child(Config.profile).child(Config.image).setValue(photoURL)
            })
        }
    }
    
    public func createEvent(_ event: Event, completion: @escaping CreateEventCallback) {
        let dayString = event.getDayString()
        let eventId = UUID().uuidString
        let eventRef = eventsRef.child(dayString).child(eventId)
     //   eventRef.setValue(event.toAnyObject(), withCompletionBlock: { (err, _) in
       //     completion(self.checkError(err))
       // })
    }
    
    public func getEventWithId(_ eventId: String, completion: @escaping GetEventCallback) {
        // TODO
    }
    
    public func getEventByDay(_ day: Date, completion: @escaping GetEventByDayCallback) {
        let dayString = day.string(format: Config.dateTimeFormatDayString)
        let dayRef = eventsRef.child(dayString)
        dayRef.observeSingleEvent(of: .value, with: {(snapshot) in
            var events = [Event]()
            for event in snapshot.children {
                events.append(Event(snapshot: event as! FIRDataSnapshot)!)
            }
            completion(events, nil)
        })
    }
    
    func createIdea(idea: Idea, completion: @escaping GeneralIdeaCallback) {
        let ideaRef = ideasRef.childByAutoId()
        idea.id = ideaRef.key
        
        ideaRef.setValue(idea.toDictionary(), withCompletionBlock: { (err, _) in
            completion(self.checkError(err))
        })
    }
    
    func updateIdeaContent(for idea: Idea) {
        guard let id = idea.id else {
            return
        }
        
        let ideaRef = getIdeaRef(for: id)
        ideaRef.updateChildValues(idea.toDictionary())
    }
    
    func updateIdeaVote(for id: String, user: String, vote: Bool) {
        let ideaRef = getIdeaRef(for: id)
        ideaRef.child(Config.votes).child(user).setValue(vote)
    }
    
    public func createChannel(for channel: Channel, completion: @escaping GetChannelCallback) {
        if channel.type == .directMessage {
            getChannel(with: channel.members, completion: { (existingChannel, error) in
                if let existingChannel = existingChannel {
                    completion(existingChannel, error)
                } else {
                    self.createNewChannel(for: channel, completion: { (channel, error) in
                        completion(channel, error)
                    })
                }
            })
        } else {
            createNewChannel(for: channel, completion: { (channel, error) in
                completion(channel, error)
            })
        }
    }
    
    public func createNewChannel(for channel: Channel, completion: @escaping GetChannelCallback) {
        let channelRef = getChannelsRef().childByAutoId()
        channel.id = channelRef.key
        
        channelRef.setValue(channel.toDictionary())
        
        guard let icon = channel.icon else {
            completion(channel, nil)
            return
        }
        
        saveImage(image: icon, completion: { (imageURL, firError) in
            guard firError == nil else {
                return
            }
            channelRef.child(Config.image).setValue(imageURL)
            
        })
        
        completion(channel, nil)
    }
    
    public func updateChannel(icon: UIImage, for channel: Channel) {
        guard let id = channel.id else {
            return
        }
        
        let channelRef = getChannelRef(for: id)
        
        saveImage(image: icon, completion: { (imageURL, firError) in
            guard firError == nil else {
                return
            }
            channelRef.child(Config.image).setValue(imageURL)
            
        })
    }
    
    public func updateChannel(name: String, for channel: Channel) {
        guard let id = channel.id else {
            return
        }
        
        let channelRef = getChannelRef(for: id)
        channelRef.child(Config.name).setValue(name)
    }
    
    public func deleteChannel(for channel: Channel) {
        guard let id = channel.id else {
            return
        }
        
        let channelsRef = getChannelsRef()
        let channelRef = channelsRef.child(id)
        channelRef.removeValue { (error, ref) in
        }
    }
    
    private func getChannel(with members: [String], completion: @escaping GetChannelCallback) {
        let channelRef = getChannelsRef()
        
        let members = members.sorted(by: {$0 < $1})
        
        guard members.count > 1 else {
            return
        }
        
        let mainQuery = channelRef.queryOrdered(byChild: Config.channelType)
            .queryEqual(toValue: ChannelType.directMessage.rawValue)
        
        mainQuery.observeSingleEvent(of: .value, with: { (snapshot) in
            let membersSet = Set(members)
            for child in snapshot.children {
                guard let childSnapshot = child as? FIRDataSnapshot,
                    let channel = Channel(id: childSnapshot.key, snapshot: childSnapshot) else {
                    continue
                }
                
                let childSet = Set(channel.members)
                
                if membersSet == childSet {
                    completion(channel, nil)
                    return
                }
            }
            
            completion(nil, nil)
        })
    }
    
    public func addMember(to channel: Channel, member: User) {
        guard let id = channel.id, let uid = member.uid else {
            return
        }
        
        let channelRef = getChannelRef(for: id)
        var members = channel.members
        members.append(uid)
        channelRef.child(Config.members).setValue(members)
    }
    
    public func removeMember(from channel: Channel, uid: String) {
        guard let id = channel.id else {
            return
        }
        
        let channelRef = getChannelRef(for: id)
        var members = channel.members
        
        for (index, child) in members.enumerated() {
            if child == uid {
                members.remove(at: index)
                break
            }
        }
        
        if members.count > 1 {
            channelRef.child(Config.members).setValue(members)
        } else {
            channelRef.removeValue()
        }
        
        
    }
    
    public func saveImage(image: UIImage, completion: @escaping ImageURLCallback) {
        let imageData = image.jpeg(.low)
        let imagePath = auth!.currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata, let path = metadata.path else {
                completion(nil, self.checkError(error))
                return
            }
            
            completion("\(Config.appURL)/\(path)", self.checkError(error))
        }
    }
    
    public func getProfileImageURL(for uid: String, completion: @escaping ImageURLCallback) {
        let userRef = usersRef.child(uid).child(Config.profile)
        
        getImageURL(for: userRef, completion: { (url, error) in
            completion(url, error)
        })
    }
    
    public func getChatIconImageURL(for id: String, completion: @escaping ImageURLCallback) {
        let channelRef = getChannelRef(for: id)
        
        getImageURL(for: channelRef, completion: { (url, error) in
            completion(url, error)
        })
    }
    
    private func getImageURL(for ref: FIRDatabaseReference, completion: @escaping ImageURLCallback) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(Config.image),
                let url = snapshot.childSnapshot(forPath: Config.image).value as? String? {
                completion(url, nil)
            } else {
                completion(nil, nil)
            }
        })
        
    }
    
    public func fetchImageDataAtURL(_ imageURL: String, completion: @escaping ImageCallback) {
        guard (imageURL.hasPrefix("gs://") || imageURL.hasPrefix("http://")
            || imageURL.hasPrefix("https://")) else {
            return
        }
        
        let storageRef = FIRStorage.storage().reference(forURL: imageURL)
        
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            storageRef.metadata(completion: { (metadata, metadataErr) in
                guard let data = data else {
                    if let err = metadataErr {
                        print("Error downloading metadata: \(err)")
                    }
                    return
                }
                
                completion(UIImage.init(data: data), imageURL)
            })
        }
    }
    
    public func fetchProfileImage(for uid: String, completion: @escaping ImageCallback) {
        fetchImage(for: usersRef.child(uid).child(Config.profile), completion: { (image, url) in
            completion(image, url)
        })
    }
    
    public func fetchChannelIcon(for id: String, completion: @escaping ImageCallback) {
        fetchImage(for: getChannelsRef().child(id), completion: { (image, url) in
            completion(image, url)
        })
    }
    
    private func fetchImage(for ref: FIRDatabaseReference, completion: @escaping ImageCallback) {
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.hasChild(Config.image) else {
                completion(nil, nil)
                return
            }
            
            let data = snapshot.childSnapshot(forPath: Config.image)
            guard let imageURL = data.value as? String else {
                completion(nil, nil)
                return
            }
            
            self.fetchImageDataAtURL(imageURL, completion: { (image, url)  in
                completion(image, url)
            })
        })
    }
    
    func getUid() -> String {
        return auth?.currentUser?.uid ?? ""
    }
    
    private func checkError(_ err: Error?) -> FirebaseError? {
        guard let nsError = err as NSError? else {
            return nil
        }
        guard let errorCode = FIRAuthErrorCode(rawValue: nsError.code) else {
            return nil
        }

        switch errorCode {
        case .errorCodeNetworkError:
            return FirebaseError.networkError
        case .errorCodeUserNotFound:
            return FirebaseError.userNotFound
        case .errorCodeUserTokenExpired:
            return FirebaseError.userTokenExpired
        case .errorCodeEmailAlreadyInUse:
            return FirebaseError.emailAlreadyInUse
        case .errorCodeInvalidEmail:
            return FirebaseError.invalidEmail
        case .errorCodeWeakPassword:
            return FirebaseError.weakPassword
        case .errorCodeUserDisabled:
            return FirebaseError.userDisabled
        case .errorCodeWrongPassword:
            return FirebaseError.wrongPassword
        default:
            return FirebaseError.otherError(errorCode: errorCode.rawValue)
        }
        
    }
    
    public func getQuery(at ref: FIRDatabaseReference, for child: String, equal value: Any) -> FIRDatabaseQuery {
        return ref.child(child).queryOrderedByValue().queryEqual(toValue: value)
    }
    
    public func getChannelsRef() -> FIRDatabaseReference {
        return databaseReference(for: Config.channelsRef)
    }
    
    public func getChannelRef(for channelID: String) -> FIRDatabaseReference {
        return getChannelsRef().child(channelID)
    }
    
    public func getMessagesRef(for channel: FIRDatabaseReference) -> FIRDatabaseReference {
        return channel.child(Config.messages)
    }
    
    public func getTypingRef(for channel: FIRDatabaseReference, by uid: String) -> FIRDatabaseReference {
        return channel.child(Config.typingIndicator).child(uid)
    }
    
    public func getLatestMessageQuery(for channel: String) -> FIRDatabaseQuery {
        return getChannelsRef().child(channel).child(Config.messages).queryLimited(toLast: 1)
    }
    
    public func getUserRef(for uid: String) -> FIRDatabaseReference {
        return databaseReference(for: Config.users).child(uid)
    }
    
    public func getStorageRef() -> FIRStorageReference {
        return storageRef
    }
    
    public func getMentorsRef() -> FIRDatabaseQuery {
        return usersRef.queryOrdered(byChild: "userType/isMentor").queryEqual(toValue: true)
    }
    
    public func getIdeasRef() -> FIRDatabaseReference {
        return ideasRef
    }
    
    public func getIdeaRef(for ideaID: String) -> FIRDatabaseReference {
        return ideasRef.child(ideaID)
    }
    
    private func databaseReference(for name: String) -> FIRDatabaseReference {
        return FIRDatabase.database().reference().child(name)
    }
}

