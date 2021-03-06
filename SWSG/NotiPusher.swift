//
//  NotiPusher.swift
//  SWSG
//
//  Created by dinhvt on 9/4/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

/**
    NotiPusher is the interface between the app and OneSignal that can send request to OneSignal server to send notifications to other users.
 */

import Foundation
import OneSignal

class NotiPusher {
    
    /**
        Send the notification to all user.
            - requires: the type of noti must have the type that is available to all user (.i.e announcement)
    */
    public func pushToAll(noti: PushNotification) {
        var data = noti.toSendableDict()
        data["app_id"] = Secret.oneSignalAppId
        data["included_segments"] = ["All"]
        let http = HttpClient()
        http.post(urlString: "https://onesignal.com/api/v1/notifications", jsonData: data, authHeaderValue: Secret.oneSignalAuthHeaderValue, completion: nil)
        
    }
    
    /**
        Send the notification to a specific user by user id
            - requires: user with this user id exists and subscribed for push notification otherwise the method has no effect
    */    
    public func push(noti: PushNotification, toUserWithUid uid: String) {
        var data = noti.toSendableDict()
        data["app_id"] = Secret.oneSignalAppId
        //data["included_segments"] = ["All"]
        data["filters"] = [["field": "tag", "key": "uid", "relation": "=", "value": uid]]
        let http = HttpClient()
        http.post(urlString: "https://onesignal.com/api/v1/notifications", jsonData: data, authHeaderValue: Secret.oneSignalAuthHeaderValue, completion: nil)
    }
    
    /**
        Send the notification to a specific user by email
            - requires: user with this email exists and subscribed for push notification otherwise the method has no effect
    */
    public func push(noti: PushNotification, toUserWithEmail: String) {
        var data = noti.toSendableDict()
        data["app_id"] = Secret.oneSignalAppId
        //data["included_segments"] = ["All"]
        data["filters"] = [["field": "email", "relation": "=", "value": toUserWithEmail]]
        let http = HttpClient()
        http.post(urlString: "https://onesignal.com/api/v1/notifications", jsonData: data, authHeaderValue: Secret.oneSignalAuthHeaderValue, completion: nil)
    }
    
//    public func crawlNoti() {
//        let http = HttpClient()
//        http.get(urlString: "https://onesignal.com/api/v1/notifications?app_id=\(Secret.oneSignalAppId)&limit=limit&offset=offset", authHeaderValue: Secret.oneSignalAuthHeaderValue)
//    }
    
    /**
        Send a push notification of type PushNotificationType.message and with necessary additionalData (chat channel id) used to handle the notification.
    */
    public func sendMessageNoti(fromUsername: String, fromUserId: String, toChannel: Channel) {
        guard let id = toChannel.id else {
            return
        }
        let noti = PushNotification(type: .message, additionData: [Config.channelId: id], message: fromUsername + " sends you a message")
        for member in toChannel.members {
            if member != fromUserId {
                push(noti: noti, toUserWithUid: member)
            }
        }
    }
    
}

enum UserGroup {
    case all
    case individual
    case admin
    case mentor
    case organizer
    case speak
    case participant
}

