//
//  ConsultationSlotCell.swift
//  SWSG
//
//  Created by Jeremy Jee on 14/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class ConsultationSlotCell: UICollectionViewCell {
    @IBOutlet weak var outerFrame: UIView!
    @IBOutlet weak var timeLbl: UILabel!
    
    func setTime(to date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        timeLbl.text = formatter.string(from: date)
    }
    
    func setStatus(is status: ConsultationSlotStatus) {
        switch status {
        case .booked:
            outerFrame.backgroundColor = UIColor.red
            timeLbl.textColor = UIColor.red
        case .vacant:
            outerFrame.backgroundColor = UIColor.green
            timeLbl.textColor = UIColor.green
        case .unavailable:
            outerFrame.backgroundColor = UIColor.gray
            timeLbl.textColor = UIColor.gray
        }
    }
}
