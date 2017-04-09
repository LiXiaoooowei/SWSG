//
//  Notification.swift
//  SWSG
//
//  Created by dinhvt on 10/4/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation

class PushNotification {
    
    public let type: PushNotificationType
    public let data: Any?
    public let message: String
    
    init(type: PushNotificationType, data: Any?, message: String) {
        self.type = type
        self.data = data
        self.message = message
    }
    
    public func toDictionary() -> [String: Any] {
        var result = [String: Any]()
        result["aps"] = ["body": message]
        result["type"] = type.rawValue
        result["data"] = data
        return result
    }
    
}

enum PushNotificationType: Int {
    case announcement = 0
    case message = 1
}
