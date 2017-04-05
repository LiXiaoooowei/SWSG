//
//  MentorViewController.swift
//  SWSG
//
//  Created by Jeremy Jee on 14/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase

class MentorViewController: UIViewController {
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var positionLbl: UILabel!
    @IBOutlet weak var companyLbl: UILabel!
    @IBOutlet weak var descriptionTB: UITextView!
    
    @IBOutlet weak var consultationSlotCollection: UICollectionView!
    @IBOutlet weak var relatedMentorCollection: UICollectionView!
    
    private let mentorBookingErrorMsg = "Sorry, only participants of SWSG can book a slot!"
    
    public var mentorAcct: User?
    fileprivate var mentor: Mentor?
    fileprivate var relatedMentors = [User]()
    fileprivate var cvLayout = MultiDirectionCollectionViewLayout()
    
    //MARK: Firebase References
    private var mentorRef: FIRDatabaseReference!
    private var mentorRefHandle: FIRDatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImg = Utility.roundUIImageView(for: profileImg)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        consultationSlotCollection.delegate = self
        consultationSlotCollection.dataSource = self
        consultationSlotCollection.collectionViewLayout = cvLayout
        
        relatedMentorCollection.delegate = self
        relatedMentorCollection.dataSource = self
        
        setUpDescription()
        
        guard let mentorAcct = mentorAcct, let uid = mentorAcct.uid else {
            return
        }
        
        mentorRef = System.client.getUserRef(for: uid)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeSlots()
        getRelatedMentors()
    }
    
    // MARK: Firebase related methods
    private func observeSlots() {
        // Use the observe method to listen for new
        // channels being written to the Firebase DB
        mentorRefHandle = mentorRef.observe(.value, with: { (snapshot) -> Void in
            guard let userSnapshot = snapshot.value as? [String: Any],
                let mentorSnapshot = userSnapshot[Config.mentor] as? [String: Any],
                let mentor = Mentor(snapshot: mentorSnapshot) else {
                    return
            }
            self.mentor = mentor
            self.cvLayout.dataSourceDidUpdate = true
            self.consultationSlotCollection.reloadData()
        })
    }
    
    private func getRelatedMentors() {
        System.client.getMentors(completion: { (mentors, error) in
            for mentorAcct in mentors {
                if self.mentorAcct?.mentor?.field == mentorAcct.mentor?.field &&
                    self.mentorAcct?.uid != mentorAcct.uid {
                    self.relatedMentors.append(mentorAcct)
                }
            }
            self.relatedMentorCollection.reloadData()
        })
    }
    
    func setUpDescription() {
        guard let mentorAcct = mentorAcct else {
            return
        }
        let profile = mentorAcct.profile
        
        profileImg.image = profile.image
        nameLbl.text = profile.name
        positionLbl.text = profile.job
        companyLbl.text = profile.company
        descriptionTB.text = profile.desc
    }
    
    func bookSlot(on dayIndex: Int, at index: Int) {
        guard let mentor = mentor else {
            return
        }
        
        let day = mentor.days[dayIndex]
        let dateString = Utility.fbDateFormatter.string(from: day.date)
        let slot = day.slots[index]
        let slotTimeString = Utility.fbDateTimeFormatter.string(from: slot.startDateTime)
        
        let slotRef = mentorRef.child("mentor/consultationDays/\(dateString)/\(slotTimeString)")
        slotRef.child(Config.consultationStatus).setValue(ConsultationSlotStatus.booked.rawValue)
        slotRef.child(Config.team).setValue(System.activeUser?.team)
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Config.mentorToRelatedMentor {
            let mentorVC = segue.destination as! MentorViewController
            if let indexPaths = relatedMentorCollection.indexPathsForSelectedItems {
                let index = indexPaths[0].item
                mentorVC.mentorAcct = relatedMentors[index]
            }
        }
    }
}

extension MentorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let mentor = mentor else {
                return 1
        }
        
        if collectionView.tag == Config.slotCollectionTag {
            return mentor.days.count
        } else {
            return 1
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let mentor = mentor else {
            return 0
        }
        
        if collectionView.tag == Config.slotCollectionTag {
            return mentor.days[section].slots.count + 1
        } else if collectionView.tag == Config.relatedCollectionTag {
            return relatedMentors.count
        } else {
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView.tag == Config.slotCollectionTag && indexPath.item == 0 {
            return getConsultationDayCell(for: collectionView, at: indexPath)
        } else if collectionView.tag == Config.slotCollectionTag {
            return getConsultationSlotCell(for: collectionView, at: indexPath)
        } else if collectionView.tag == Config.relatedCollectionTag {
            return getRelatedMentorCell(for: collectionView, at: indexPath)
        } else {
            return UICollectionViewCell()
        }
    }
    
    private func getConsultationDayCell(for collectionView: UICollectionView,
                                      at indexPath: IndexPath) -> UICollectionViewCell {
        guard let mentor = mentor, let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:"consultationDayCell",
            for: indexPath) as? ConsultationDayCell
            else {
                return ConsultationDayCell()
        }
        
        let date = mentor.days[indexPath.section].date
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EE"
        
        cell.dayLbl.text = formatter.string(from: date)
        
        formatter.dateFormat = "d/MM"
        cell.dateLbl.text = formatter.string(from: date)
        
        return cell
    }
    
    private func getConsultationSlotCell(for collectionView: UICollectionView,
                                         at indexPath: IndexPath) -> UICollectionViewCell {
        guard let mentor = mentor, let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:"consultationSlotCell",
            for: indexPath) as? ConsultationSlotCell
            else {
                return ConsultationSlotCell()
        }
        let consultationSlots = mentor.days[indexPath.section].slots
        let slot = consultationSlots[indexPath.item - 1]
        
        cell.setTime(to: slot.startDateTime)
        cell.setStatus(is: slot.status)
        
        return cell
    }
    
    private func getRelatedMentorCell(for collectionView: UICollectionView,
                                      at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier:"relatedMentorCell",
            for: indexPath) as? MentorCell
            else {
                return MentorCell()
        }
        
        let profile = relatedMentors[indexPath.item].profile
        
        cell.iconIV.image = profile.image
        cell.nameLbl.text = profile.name
        cell.positionLbl.text = profile.job
        cell.companyLbl.text = profile.company
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath){
        if collectionView.tag == Config.slotCollectionTag && indexPath.item > 0 {
            selectedSlot(for: collectionView, at: indexPath)
        } 
    }
    
    private func selectedSlot(for collectionView: UICollectionView,
                              at indexPath: IndexPath) {
        guard let mentorAcct = mentorAcct, let mentor = mentorAcct.mentor else {
            return
        }
        
        let dayIndex = collectionView.tag
        let index = indexPath.item - 1
        let slot = mentor.days[dayIndex].slots[index]
        
        guard slot.status == .vacant else {
            return
        }
        
        let message = "Would you like to book \(slot.startDateTime.string(format: "dd/M - Ha"))?"
        let bookingController = UIAlertController(title: "Book Slot", message: message,
                                                  preferredStyle: UIAlertControllerStyle.alert)
        
        //Add an Action to Confirm the Deletion with the Destructive Style
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ -> Void in
            self.bookSlot(on: dayIndex, at: index)
            
            //collectionView.reloadItems(at: [indexPath])
        }
        bookingController.addAction(confirmAction)
        
        //Add a Cancel Action to the Popup
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        bookingController.addAction(cancelAction)
        
        //Present the Popup
        self.present(bookingController, animated: true, completion: nil)
    }
}
