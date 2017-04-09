//
//  SignUpViewController.swift
//  SWSG
//
//  Created by shixiyue on 13/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var loginStack: UIStackView!
    @IBOutlet private var signUpButton: RoundCornerButton!
    
    public var socialUser: SocialUser?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Config.signUpTable, let signUpTableViewController = segue.destination as? SignUpTableViewController else {
            return
        }
        signUpTableViewController.socialUser = socialUser
        signUpTableViewController.signUpButton = signUpButton
        signUpTableViewController.loginStack = loginStack
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
