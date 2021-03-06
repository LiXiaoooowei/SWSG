//
//  EditProfileViewController.swift
//  SWSG
//
//  Created by shixiyue on 17/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet private var doneButton: RoundCornerButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Config.editProfileTable,
            let editProfileViewController = segue.destination as? EditProfileTableViewController else {
            return
        }
        editProfileViewController.doneButton = doneButton
    }

}
