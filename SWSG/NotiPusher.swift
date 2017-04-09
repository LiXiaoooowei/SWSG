//
//  NotiPusher.swift
//  SWSG
//
//  Created by dinhvt on 9/4/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation

class NotiPusher {
    
    public func pushToAll(noti: PushNotification) {
        let data = ["app_id": Secret.oneSignalAppId,
                    "included_segments": ["All"],
                    "contents": noti.toDictionary()] as [String : Any]
        let http = HttpClient()
        http.post(urlString: "https://onesignal.com/api/v1/notifications", jsonData: data, authHeaderValue: Secret.oneSignalAuthHeaderValue, completion: nil)
        
    }
    
    public func push(noti: PushNotification, toUserWithEmail: String) {
        let data = ["app_id": Secret.oneSignalAppId,
                    "included_segments": ["All"],
                    "filters": [
                        ["field": "email", "value": toUserWithEmail]
                    ],
                    "contents": noti.toDictionary()] as [String : Any]
        let http = HttpClient()
        http.post(urlString: "https://onesignal.com/api/v1/notifications", jsonData: data, authHeaderValue: Secret.oneSignalAuthHeaderValue, completion: nil)
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
