//
//  Mentor.swift
//  SWSG
//
//  Created by Jeremy Jee on 14/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import Foundation

class Mentor {
    var days = [ConsultationDate]()
    var field: Field
    
    init(profile: Profile, field: Field) {
        self.field = field
    }
    
    func addSlots(on date: Date) {
        var day = ConsultationDate(on: date)
        
        var slotTime = Date.dateTime(forDate: date, forTime: Config.consultationStartTime)
        let endTime = Date.dateTime(forDate: date, forTime: Config.consultationEndTime)
        
        while slotTime <= endTime {
            let slot = ConsultationSlot(start: slotTime, duration: Config.duration,
                                        status: .vacant)
            
            day.slots.append(slot)
            
            slotTime = slotTime.add(minutes: Config.duration)
        }
        
        days.append(day)
    }
    
    func toDictionary() -> [String: Any] {
        return [Config.consultationDays: days, Config.field: field.rawValue]
    }
}
