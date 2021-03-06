//
//  Utility.swift
//  SWSG
//
//  Created by shixiyue on 13/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Firebase
import EventKit
import Google
import GoogleSignIn
import SwiftSpinner

/**
    Utility is a helper struct consisting of static functions that perform
    Utility tasks that can be abstracted from the normal code flow
 */
struct Utility {
    
    //Rounds any Image View passed in
    static func roundUIImageView(for image: UIImageView) -> UIImageView {
        image.layer.cornerRadius = image.frame.size.width / 2
        image.clipsToBounds = true
        
        return image
    }
    
    //Returns a list of countries
    static let countries = NSLocale.isoCountryCodes.map { (code: String) -> String in
        let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
        let currentLocaleID = NSLocale.current.identifier
        return NSLocale(localeIdentifier: currentLocaleID).displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
    }
    
    static let defaultCountryIndex = countries.index(of: Config.defaultCountry) ?? 0
    
    //Checks if an email is Valid
    static func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    //Checks if a password is Valid
    static func isValidPassword(testStr: String) -> Bool {
        return testStr.characters.count >= Config.passwordMinLength
    }
    
    /// Jumps to another storyboard
    static func showStoryboard(storyboard: String, destinationViewController: String, currentViewController: UIViewController) {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: destinationViewController) as UIViewController

        currentViewController.present(controller, animated: false, completion: nil)
    }
    
    // Show a Storyboard using the Navigation Controller
    static func showStoryboardByNavigation(storyboard: String, destinationViewController: String, currentViewController: UIViewController) {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: destinationViewController) as UIViewController

        currentViewController.present(controller, animated: true, completion: nil)

        controller.navigationItem.hidesBackButton = currentViewController.navigationItem.hidesBackButton
    controller.navigationController?.setNavigationBarHidden(controller.navigationItem.hidesBackButton, animated: false)
        //currentViewController.navigationController?.pushViewController(controller, animated: true)
    }
    
    static func onBackButtonClick(tableViewController: UITableViewController) {
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        tableViewController.view.window!.layer.add(transition, forKey: nil)
        tableViewController.dismiss(animated: false, completion: nil)
    }
    
    static func onBackButtonClick(UIViewController: UIViewController) {
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        UIViewController.view.window!.layer.add(transition, forKey: nil)
        UIViewController.dismiss(animated: false, completion: nil)
    }
    
    static func logOutUser(currentViewController: UIViewController) {
        let title = "Log Out"
        let message = "Do you want to log out?"
        
        let logoutController = UIAlertController(title: title, message: message,
                                                  preferredStyle: UIAlertControllerStyle.alert)
        
        //Add an Action to Confirm quitting with the Destructive Style
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _ in
        }
        logoutController.addAction(cancelAction)
        
        //Add an Action to Confirm quitting with the Destructive Style
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            signOutAllAccounts()
            showStoryboard(storyboard: Config.logInSignUp, destinationViewController: Config.initialScreen, currentViewController: currentViewController)
        }
        logoutController.addAction(logoutAction)
        
        //Present the Popup
        currentViewController.present(logoutController, animated: true, completion: nil)
    }
    
    static func signOutAllAccounts() {
        System.activeUser = nil
        System.client.signOut()
        signOutSocialMedia()
    }
    
    static func signOutSocialMedia() {
        if let _ = AccessToken.current {
            LoginManager().logOut()
        }
        
        GIDSignIn.sharedInstance().signOut()
    }
    
    static func logInUser(user: User, currentViewController: UIViewController) {
        System.activeUser = user
        showStoryboard(storyboard: Config.mainStoryboard, destinationViewController: Config.navigationController, currentViewController: currentViewController)
    }
    
    static func getFailAlertController(message: String) -> UIAlertController {
        let alertController = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        return alertController
    }
    
    static func getNoInternetAlertController() -> UIAlertController {
        return getFailAlertController(message: "Sorry, there's no internet connection!")
    }
    
    static func getSuccessAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        return alertController
    }

    static func getDestinationStoryboard(from navController: UIViewController) -> UIViewController? {
        guard let navController = navController as? UINavigationController else {
            return nil
        }
        
        return navController.viewControllers[0]
    }
    
    static var fbDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
    
        formatter.dateFormat = "d-MM-yyyy"
    
        return formatter
    }
    
    static var fbDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        formatter.dateFormat = "d-MM-yyyy-HH:mm"
        
        return formatter
    }
    
    static var fbTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        formatter.dateFormat = "HH:mm"
        
        return formatter
    }
    
    static var niceDateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        formatter.dateFormat = "d MMM - h:mma"
        
        return formatter
    }
    
    //Display a Popup with only the option to dismiss
    static func displayDismissivePopup(title: String, message: String,
                                       viewController: UIViewController,
                                       completion: @escaping () -> Void) {
        let dismissController = UIAlertController(title: title, message: message,
                                                  preferredStyle: UIAlertControllerStyle.alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { _ in
            completion()
        }
        dismissController.addAction(dismissAction)
        
        //Present the Popup
        viewController.present(dismissController, animated: true, completion: nil)
    }
    
    //Display a Popup with a textfield
    static func createPopUpWithTextField(title: String, message: String, btnText: String, placeholderText: String, existingText: String, viewController: UIViewController, completion: @escaping (String) -> Void) {
        createPopUpWithTextField(title: title, message: message, btnText: btnText,
                                 placeholderText: placeholderText, existingText: existingText,
                                 isSecure: false, viewController: viewController,
                                 completion: completion)
    }
    
     //Display a Popup with a textfield and the option for the textfield to be secure
    static func createPopUpWithTextField(title: String, message: String, btnText: String, placeholderText: String, existingText: String, isSecure: Bool, viewController: UIViewController, completion: @escaping (String) -> Void) {
        //Creating a Alert Popup for Saving
        let createController = UIAlertController(title: title, message: message,
                                                 preferredStyle: UIAlertControllerStyle.alert)
        
        //Creates a Save Button for the Popup
        let action = UIAlertAction(title: btnText, style: .default) { _ -> Void in
            
            if let textField = createController.textFields?[0] {
                guard var text = textField.text else {
                    return
                }
                
                text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                completion(text)
            }
        }
        createController.addAction(action)
        
        //Creates a Cancel Button for the Popup
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        createController.addAction(cancelAction)
        
        //Creates a Textfield to enter the Level Name in the Popup
        createController.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = placeholderText
            textField.isSecureTextEntry = isSecure
            
            if existingText.characters.count > 0 {
                textField.text = existingText
            }
            
            //Disable the Save Button by default
            action.isEnabled = false
            
            textField.textAlignment = .center
            
            guard let _ = viewController as? UITextFieldDelegate else {
                return
            }
            
            textField.delegate = viewController as? UITextFieldDelegate
            textField.returnKeyType = .done
            
            //Sets the Save Button to disabled if the textfield is empty
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UITextFieldTextDidChange,
                object: textField, queue: OperationQueue.main) { _ in
                    guard var text = textField.text else {
                        return
                    }
                    text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if text != "" {
                        action.isEnabled = true
                    } else {
                        action.isEnabled = false
                    }
            }
        })
        
        //Displays the Save Popup
        viewController.present(createController, animated: true, completion: nil)
    }
    
    //Add an event to the iOS Calendar
    static func addEventToCalendar(title: String, description: String?, startDate: Date, endDate: Date, completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event, completion: { (granted, error) in
            if (granted) && (error == nil) {
                let event = EKEvent(eventStore: eventStore)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate 
                event.notes = description
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let e as NSError {
                    completion?(false, e)
                    return
                }
                completion?(true, nil)
            } else {
                completion?(false, error as NSError?)
            }
        })
    }
    
    static func strtok(string: String, delimiter: String) -> [Int] {
        let values = string.components(separatedBy: delimiter).flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return values
    }
    
    //Sort a list of channels by their latest messages
    static func channelsSortedByLatestMessage(channels: [Channel]) -> [Channel] {
        let sortedChannels = channels.sorted(by: {
            guard let msgFirst = $0.latestMessage, let msgSecond = $1.latestMessage else {
                if let _ = $0.latestMessage {
                    return true
                } else if let _ = $1.latestMessage {
                    return false
                } else {
                    return $0.id! < $1.id!
                }
            }
            
            return msgFirst.timestamp > msgSecond.timestamp
        })
        
        return sortedChannels
    }
    
    //Obtain the Profile Img, either from cache or firebase
    static func getProfileImg(uid: String, completion: @escaping (UIImage?) -> Void) {
        if System.profileImageCache.keys.contains(uid) {
            System.client.getProfileImageURL(for: uid, completion: { (url, error) in
                if System.profileImageCache[uid]?.url == url {
                    completion(System.profileImageCache[uid]?.image)
                } else {
                    forceGetProfileImg(uid: uid, completion: { (image) in
                        completion(image)
                    })
                }
            })
        } else {
            forceGetProfileImg(uid: uid, completion: { (image) in
                completion(image)
            })
        }
    }
    
    static func forceGetProfileImg(uid: String, completion: @escaping (UIImage?) -> Void) {
        System.client.fetchProfileImage(for: uid, completion: { (image, url) in
            guard let image = image, let url = url else {
                return
            }
            
            System.profileImageCache[uid] = (image: image, url: url)
            completion(image)
        })
    }
    
    //Obtain the Chat Icon, either from cache or firebase
    static func getChatIcon(id: String, completion: @escaping (UIImage?) -> Void) {
        if System.chatIconCache.keys.contains(id) {
            System.client.getChatIconImageURL(for: id, completion: { (url, error) in
                if System.chatIconCache[id]?.url == url {
                    completion(System.chatIconCache[id]?.image)
                } else {
                    forceGetChatIcon(id: id, completion: { (image) in
                        completion(image)
                    })
                }
            })
        } else {
            forceGetChatIcon(id: id, completion: { (image) in
                completion(image)
            })
        }
    }
    
    static func forceGetChatIcon(id: String, completion: @escaping (UIImage?) -> Void) {
        System.client.fetchChannelIcon(for: id, completion: { (image,url) in
            guard let image = image, let url = url else {
                return
            }
            
            System.chatIconCache[id] = (image: image, url: url)
            completion(image)
            
        })
    }
    
    //Obtain the Event Icon, either from cache or firebase
    static func getEventIcon(id: String, completion: @escaping (UIImage?) -> Void) {
        if System.eventIconCache.keys.contains(id) {
            System.client.getEventImageURL(with: id, completion: { (url, error) in
                if System.eventIconCache[id]?.url == url {
                    completion(System.eventIconCache[id]?.image)
                } else {
                    forceGetEventIcon(id: id, completion: { (image) in
                        completion(image)
                    })
                }
                
            })
        } else {
            forceGetEventIcon(id: id, completion: { (image) in
                completion(image)
            })
        }
    }
    
    static func forceGetEventIcon(id: String, completion: @escaping (UIImage?) -> Void) {
        System.client.fetchEventImage(for: id, completion: { (image,url) in
            guard let image = image, let url = url else {
                return
            }
            
            System.eventIconCache[id] = (image: image, url: url)
            completion(image)
            
        })
    }
    
    //Obtain an image from a URL
    static func getImage(name: String, completion: @escaping (UIImage?) -> Void) {
        if let image = System.imageCache[name] {
            completion(image)
        }
        System.client.fetchImageDataAtURL(name, completion: { (image, _) in
            if let image = image {
                System.imageCache[name] = image
            }
            completion(image)
        })
    }
    
    static func logUserIn(error: FirebaseError?, current viewController: UIViewController) {
        if let firebaseError = error {
            viewController.present(Utility.getFailAlertController(message: firebaseError.errorMessage), animated: true, completion: nil)
        } else {
            System.client.getCurrentUser(completion: { (user, userError) in
                guard let user = user else {
                    var msg = "An error has occured"
                    if let error = userError {
                        msg = error.errorMessage
                    }
                    
                    viewController.present(Utility.getFailAlertController(message: msg), animated: true, completion: { () in
                        SwiftSpinner.hide()
                    })
                    
                    return
                }
                
                Utility.logInUser(user: user, currentViewController: viewController)
            })
        }
    }
    
    //Attempt registration with an email
    static func attemptRegistration(email: String, auth: AuthType, newCredential: FIRAuthCredential?, viewController: UIViewController, completion: @escaping (Bool, [String]?) -> Void) {
        attemptRegistration(email: email, password: nil, auth: auth, newCredential: newCredential,
                            viewController: viewController, completion: completion)
    }
    
    //Attempt registration with an email and password
    static func attemptRegistration(email: String, password: String?, auth: AuthType, newCredential: FIRAuthCredential?, viewController: UIViewController, completion: @escaping (Bool, [String]?) -> Void) {
        
        System.client.checkIfEmailAlreadyExists(email: email, completion: { (arr, error) in
            if let arr = arr, arr.contains(auth.rawValue) {
                attemptLogin(auth: auth, newCredential: newCredential, email: email, password: password, viewController: viewController, completion: { (success)  in
                    completion(success, arr)
                })
            } else {
                completion(false, arr)
            }
        })
    }
    
    //Attempt to login with an existing credential
    static func attemptLogin(auth: AuthType, newCredential: FIRAuthCredential?, viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        attemptLogin(auth: auth, newCredential: newCredential, email: nil, password: nil,
                     viewController: viewController, completion: completion)
    }
    
    //Attempt Login with an existing credential, add new credential if login successful
    static func attemptLogin(auth: AuthType, newCredential: FIRAuthCredential?, email: String?, password: String?, viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        
        var authCredential: FIRAuthCredential?
        switch auth {
        case .facebook:
            authCredential = System.client.getFBCredential()
        case .google:
            authCredential = System.client.getGoogleCredential()
        case .email:
            authCredential = System.client.getEmailCredential(email: email, password: password)
        }
        
        if let credential = authCredential {
            loginWithCredential(credential: credential, newCredential: newCredential,
                                viewController: viewController, completion: completion)
        } else {
            completion(false)
        }
    }
    
    //Log In with a Credential
    private static func loginWithCredential(credential: FIRAuthCredential,
                                            newCredential: FIRAuthCredential?,
                                            viewController: UIViewController,
                                            completion: @escaping (Bool) -> Void) {
        System.client.signIn(credential: credential, completion: { (error) in
            if let newCredential = newCredential {
                System.client.addAdditionalAuth(credential: newCredential, completion: { _ in
                })
            }
            
            Utility.logUserIn(error: error, current: viewController)
            completion(true)
        })
    }
    
    //Get the Value of the Team Label
    static func getTeamLbl(user: User, completion: @escaping (String) -> Void) {
        if user.type.isParticipant {
            if user.team != Config.noTeam {
                Teams().retrieveTeamWith(id: user.team, completion: { (team) in
                    guard let team = team else {
                        completion(Config.noTeamLabel)
                        return
                    }
                    completion(team.name)
                })
            } else {
                completion(Config.noTeamLabel)
            }
        } else if user.type.isMentor {
            completion(Config.mentorLabel)
        } else if user.type.isSpeaker {
            completion(Config.speakerLabel)
        } else if user.type.isOrganizer {
            completion(Config.organizerLabel)
        } else if user.type.isAdmin {
            completion(Config.adminLabel)
        }
    }
    
    //Check if a channel is valid for a user
    static func validChannel(_ channel: Channel) -> Bool {
        guard let uid = System.client.getUid() else {
            return false
        }
        
        if channel.type != .publicChannel {
            if !channel.members.contains(uid) {
                return false
            }
        }
        
        return true
    }
    
    //Get the other user in a Direct Message Channel
    static func getOtherUser(in channel: Channel, completion: @escaping (User?) -> Void) {
        for memberID in channel.members {
            if memberID != System.client.getUid() {
                System.client.getUserWith(uid: memberID, completion: { (user, error) in
                    completion(user)
                })
                return
            }
        }
        
        completion(nil)
    }
    
    //Get the latest message for a channel
    static func getLatestMessage(channel: Channel, snapshot: FIRDataSnapshot,
                                  completion: @escaping () -> Void) {
        let query = System.client.getLatestMessageQuery(for: snapshot.key)
        query.observe(.value, with: { (snapshot) in
            for child in snapshot.children {
                guard let mentorSnapshot = child as? FIRDataSnapshot,
                    let message = Message(snapshot: mentorSnapshot) else {
                        completion()
                        return
                }
                channel.latestMessage = message
            }
            completion()
            
        })
    }
    
    //Display the image picker
    static func showImagePicker(imagePicker: ImagePickerPopoverViewController, viewController: UIViewController, completion: @escaping (UIImage?)->Void) {
        imagePicker.modalPresentationStyle = .overCurrentContext
        imagePicker.completionHandler = completion
        
        viewController.present(imagePicker, animated: true, completion: nil)
        imagePicker.showImageOptions()
    }
    
    //Remove view controllers from the navigation controller stack
    static func popViewController(no: Int, viewController: UIViewController) {
        if let viewControllers = viewController.navigationController?.viewControllers {
            let vcIndex = viewControllers.count - (no + 1)
            viewController.navigationController?.popToViewController(viewControllers[vcIndex], animated: true)
        }
        
    }
    
    //Obtain a Keyboard Toolbar with previous, next and Done
    static func getToolbar(previous: Selector, next: Selector, done: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: done)
        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        
        let nextButton  = UIBarButtonItem(title: ">", style: .plain, target: self, action: next)
        nextButton.width = 50.0
        let previousButton  = UIBarButtonItem(title: "<", style: .plain, target: self, action: previous)
        
        toolbar.setItems([fixedSpaceButton, previousButton, nextButton, fixedSpaceButton, flexibleSpaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        
        return toolbar
    }
    
    //Obtain a Keyboard Toolbar with Done
    static func getDoneToolbar(done: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: done)
        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([flexibleSpaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        
        return toolbar
    }
    
    //Default implementation for previous Text Field
    static func previousTextField(runFirst: () -> Void, activeTF: UITextField?, tfCollection: [UITextField], activeTV: UITextView?, tvCollection: [UITextView]) {
        runFirst()
        
        if let activeTextField = activeTF {
            var previousTag = activeTextField.tag - 1
            
            while previousTag >= 0 {
                if tfCollection[previousTag].isEnabled {
                    tfCollection[previousTag].becomeFirstResponder()
                    return
                } else {
                    previousTag -= 1
                }
            }
        } else if let activeTextView = activeTV {
            var previousTag = activeTextView.tag - 1
            
            while previousTag >= 0 {
                if tvCollection[previousTag].isEditable {
                    tvCollection[previousTag].becomeFirstResponder()
                    return
                } else {
                    previousTag -= 1
                }
            }
            tfCollection.last?.becomeFirstResponder()
        }
    }
    
    //Default implementation for next Text Field
    static func nextTextField(runFirst: () -> Void, runLast: () -> Void, activeTF: UITextField?, tfCollection: [UITextField], activeTV: UITextView?, tvCollection: [UITextView]) {
        runFirst()
        
        if let activeTextField = activeTF {
            var nextTag = activeTextField.tag + 1
            
            while nextTag < tfCollection.count {
                if tfCollection[nextTag].isEnabled {
                    tfCollection[nextTag].becomeFirstResponder()
                    return
                } else {
                    nextTag += 1
                }
            }
            
            tvCollection.first?.becomeFirstResponder()
        } else if let activeTextView = activeTV {
            var nextTag = activeTextView.tag + 1
            
            while nextTag < tvCollection.count {
                if tvCollection[nextTag].isEditable {
                    tvCollection[nextTag].becomeFirstResponder()
                    return
                } else {
                    nextTag += 1
                }
            }
            runLast()
        }
    }
    
    //Default implementation for done pressed
    static func donePressed(runFirst: () -> Void, viewController: UIViewController) {
        runFirst()
        viewController.view.endEditing(true)
    }
    
    //Get the Name of a user
    static func getUserFullName(uid: String, label: UILabel, prefix: String = Config.emptyString) {
        System.client.getUserWith(uid: uid, completion: { (user, error) in
            guard let user = user else {
                label.text = prefix
                return
            }
            label.text = prefix + user.profile.name
        })
    }
    
    //Sets Up a Search Bar
    static func setUpSearchBar(_ searchBar: UISearchBar, viewController: UISearchBarDelegate, selector: Selector) {
        searchBar.delegate = viewController
        searchBar.inputAccessoryView = Utility.getDoneToolbar(done: selector)
    }
    
    //Style a Search Bar
    static func styleSearchBar(_ searchBar: UISearchBar) {
        searchBar.barTintColor = Config.themeColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = Config.themeColor.cgColor
    }
    
    //Check if Search should be Set to Active
    static func setSearchActive(_ searchActive: inout Bool, searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        
        if searchText.characters.count == 0 {
            searchActive = false
        } else {
            searchActive = true
        }
    }
    
    //Call when search button is pressed
    static func searchBtnPressed(viewController: UIViewController) {
        viewController.view.endEditing(true)
    }
    
    //Update votes in ideas
    static func updateVotes(idea: Idea, votesLabel: UILabel, upvoteButton: UIButton, downvoteButton: UIButton) {
        votesLabel.text = "\(idea.votes)"
        let state = idea.getVotingState()
        let upvoteImage = state.upvote ? Config.upvoteFilled : Config.upvoteDefault
        upvoteButton.setImage(upvoteImage, for: .normal)
        let downvoteImage = state.downvote ? Config.downvoteFilled : Config.downvoteDefault
        downvoteButton.setImage(downvoteImage, for: .normal)
    }
    
    static func getVideoId(for videoLink: String) -> String {
        let substring = videoLink.components(separatedBy: Config.youtubePrefix)
        let videoId = substring.count > Config.youtubeIdComponent ? substring[Config.youtubeIdComponent] : Config.emptyString
        return videoId
    }
    
    static func getVideoLink(for videoId: String) -> String {
        let videoLink = videoId.trimTrailingWhiteSpace().isEmpty ? Config.emptyString : Config.youtubePrefix + videoId
        return videoLink
    }
    
    static func showSwiftSpinnerErrorMsg() {
        let title = Config.unexpectedError
        let message = Config.tryAgain
        SwiftSpinner.show(title, animated: false).addTapHandler({
            SwiftSpinner.hide({
            })
        }, subtitle: message)
    }

}
