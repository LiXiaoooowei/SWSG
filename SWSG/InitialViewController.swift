//
//  ViewController.swift
//  SWSG
//
//  Created by Jeremy Jee on 9/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin
import GoogleSignIn
import SwiftSpinner

/**
    InitialViewController is a UIViewController that displays the Initial Screen
    if a user is not logged in. It provides the user with an option to either
    Register or Log In.
 */

class InitialViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var fbView: UIView!
    @IBOutlet weak var googleView: UIView!
    
    // MARK: Properties
    fileprivate let fbLoginButton = LoginButton(readPermissions: [.publicProfile, .email])
    fileprivate let googleLoginButton = GIDSignInButton()
    fileprivate let client = System.client
    fileprivate var currentAuth: AuthType?
    
    // MARK: Initialization Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        fbLoginButton.isHidden = false
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        Utility.signOutAllAccounts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    fileprivate func setUpButtons() {
        fbLoginButton.center = fbView.center
        fbLoginButton.delegate = self
        
        googleLoginButton.center = googleView.center
        
        self.stackView.addSubview(fbLoginButton)
        self.stackView.addSubview(googleLoginButton)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == Config.signUpToLogin, let arr = sender as? [String] {
            guard let loginVC = segue.destination as? LoginViewController,
                let auth = currentAuth else {
                return
            }
            
            switch auth {
            case .facebook:
                loginVC.newCredential = client.getFBCredential()
            case .google:
                loginVC.newCredential = client.getGoogleCredential()
            default:
                break
            }
            
            loginVC.clientArr = arr
        } else if segue.identifier == Config.initialToSignUp, let user = sender as? SocialUser {
            guard let signUpVC = segue.destination as? SignUpViewController else {
                return
            }
            
            signUpVC.socialUser = user
        }
    }
    
    fileprivate func attemptLogin(email: String, user: SocialUser, auth: AuthType) {
        Utility.attemptRegistration(email: email, auth: auth, newCredential: nil,
                                    viewController: self, completion: { (exists, arr) in
            if !exists, let arr = arr {
                let title = Config.emailExists
                let message = Config.logInWithOriginal
                SwiftSpinner.show(title, animated: false).addTapHandler({
                    SwiftSpinner.hide({
                        self.currentAuth = auth
                        self.performSegue(withIdentifier: Config.initialToLogin, sender: arr)
                    })
                }, subtitle: message)
            } else if arr == nil {
                //Account does not exist, proceed with registration
                self.performSegue(withIdentifier: Config.initialToSignUp, sender: user)
            }
        })
    }
    
}

// MARK: GIDSignInDelegate, GIDSignInUIDelegate
extension InitialViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            Utility.showSwiftSpinnerErrorMsg()
            return
        }
        SwiftSpinner.show(Config.communicateGoogle)
        let user = SocialUser(gUser: user)
        attemptLogin(email: user.email, user: user, auth: .google)
    }
}

// MARK: LoginButtonDelegate
extension InitialViewController: LoginButtonDelegate {
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
        SwiftSpinner.show(Config.communicateFacebook)
        client.getFBProfile(completion: { (user, _) in
            guard let user = user else {
                Utility.showSwiftSpinnerErrorMsg()
                return
            }
            
            self.attemptLogin(email: user.email, user: user, auth: .facebook)
        })
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton){
        
    }
}

