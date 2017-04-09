//
//  Config.swift
//  SWSG
//
//  Created by shixiyue on 13/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

struct Config {
    
    static let noTeam = -1
    static let defaultCountry = "Singapore"
    static let joinTeam = "Request to Join"
    static let quitTeam = "Quit Team"
    static let fullTeam = "Team is Full"
    static let appURL = "gs://swsg-74fdd.appspot.com"
    
    // Keys for encode/decode:
    static let uid = "uid"
    static let user = "user"
    static let userType = "userType"
    static let profile = "profile"
    static let email = "email"
    static let password = "password"
    static let team = "team"
    static let name = "name"
    static let username = "username"
    static let image = "image"
    static let job = "job"
    static let company = "company"
    static let country = "country"
    static let education = "education"
    static let skills = "skills"
    static let desc = "desc"
    static let isParticipant = "isParticipant"
    static let isSpeaker = "isSpeaker"
    static let isMentor = "isMentor"
    static let isOrganizer = "isOrganizer"
    static let isAdmin = "isAdmin"
    static let comment = "comment"
    static let comments = "comments"
    static let words = "words"
    static let dateTime = "date_time"
    static let details = "details"
    static let venue = "venue"
    static let id = "id"
    static let ideaName = "ideaName"
    static let ideaTeam = "ideaTeam"
    static let ideaDescription = "ideaDescription"
    static let ideaVideo = "ideaVideo"
    static let votes = "votes"
    static let mentor = "mentor"
    static let field = "field"
    static let consultationDays = "consultationDays"
    static let consultationSlots = "consultationSlots"
    static let consultationStatus = "consultationStatus"

    static let start = "start"
    static let end = "end"
    static let date = "date"

    static let speakers = "Speakers"
    static let organizers = "Organizing Team"
    static let judges = "Judges"

    
    // Parameters for UI:
    static let defaultButtonFont = UIFont(name: "Futura", size: 20)
    static let buttonCornerRadius: CGFloat = 5
    static let themeColor = UIColor(red: 232.0/255.0, green: 43.0/255.0, blue: 49.0/255.0, alpha: CGFloat(1))
    static let disableAlpha: CGFloat = 0.5
    static let enableAlpha: CGFloat = 1
    static let maximumZoomScale: CGFloat = 10
    static let minimumProfileTextFieldHeight: CGFloat = 49.5
    static let maxTeamMember: Int = 4
    static let upvoteDefault = UIImage(named: "upvote")
    static let upvoteFilled = UIImage(named: "upvote-filled")
    static let downvoteDefault = UIImage(named: "downvote")
    static let downvoteFilled = UIImage(named: "downvote-filled")
    static let placeholderImg = UIImage(named: "Placeholder")!
    static let chatIconWidth: CGFloat = 40
    static let headerBuffer: CGFloat = 45
    static let keyboardOffsetSignUp: CGFloat = 94
    
    // Parameters for Storyboard:
    static let launchScreen = "LaunchScreen"
    static let logInSignUp = "LoginSignup"
    static let initialScreen = "InitialScreen"
    static let main = "Main"
    static let homeViewController = "HomeViewController"
    static let eventSystem = "EventSystem"
    static let navigationController = "NavigationController"

    static let teamRegistration = "TeamRegistration"
    static let ideasVotingPlatform = "Ideas"

    static let profileScreen = "Profile"
    static let profileViewController = "ProfileViewController"
    static let editProfileTable = "EditProfileTable"
    static let imageCropper = "ImageCropper"
    static let imageCropperViewController = "ImageCropperViewController"
    static let uiSupporting = "UISupporting"
    
    static let channelViewController = "ChannelViewController"
    
    //Parameters for Segues:
    static let channelListToChannel = "showChannel"
    static let channelListToCreateChannel = "showCreateChannel"
    static let mentorGridToMentor = "chosenMentor"
    static let mentorToRelatedMentor = "showRelatedMentor"
    static let channelToChannelInfo = "showChatInfo"
    static let signUpTable = "signUpTable"
    static let initialToSignUp = "showSignUp"
    static let initialToLogin = "showLogin"
    static let mentorToChat = "mentorToChat"
    
    // Parameters for tableView:
    static let profileCell = "profileCell"

    
    // Parameters for information message:
    static let done = "Done"
    static let noTeamLabel = "No Team yet"
    static let defaultContent = " "
    
    static let passwordMinLength = 6
    
    // Parameters for Mentor Booking:
    static var consultationStartTime: Date {
        return Date.time(from: "11:00")
    }
    
    static var consultationEndTime: Date {
        return Date.time(from: "17:00")
    }
    
    static let duration = 60
    
    static let slotCollectionTag = 1
    static let relatedCollectionTag = 2
    
    // Parameters for Chat
    static let hourInterval = TimeInterval(3600)
    static let channelsRef = "channels"
    static let channelCell = "channelCell"
    static let memberCell = "memberCell"
    static let isPublic = "isPublic"
    static let messages = "messages"
    static let members = "members"
    static let senderId = "senderId"
    static let senderName = "senderName"
    static let timestamp = "timestamp"
    static let text = "text"
    static let photoURL = "photoURL"
    static let channelType = "channelType"
    static let typingIndicator = "typingIndicator"
    
    //Parameters for storage
    static let commentsFileName = "commentsFileName"
    static let localUser = "localUser"
    
    static let dateTimeFormatDayString = "dd-MM-yyyy"
    
    //Parameters for Firebase Client
    static let users = "users"
    static let me = "me"
    
    //Parameters for Facebook
    static let fbIdentifier = "facebook.com"
    
    // Parameters for notification:
    static let fullScreenImage = "fullScreenImage"
    
}
