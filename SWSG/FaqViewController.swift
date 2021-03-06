//
//  FaqViewController.swift
//  SWSG
//
//  Created by Shi Xiyue on 27/3/17.
//  Copyright © 2017 nus.cs3217.swsg. All rights reserved.
//

import UIKit
import Firebase

/**
 FaqViewController is a UIViewController that displays the information
 for frequently asked questions.
 
 Specifications:
 - faqs: Faqs whose information to display
 */
class FaqViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet private var faqTableView: UITableView!
    
    // MARK: Properties
    fileprivate var faqs = Faqs()
    fileprivate var faqInfo: [Faq]!
    
    private var faqRef: FIRDatabaseReference?
    private var faqAddRefHandle: FIRDatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        faqRef = System.client.getFaqRef()
        observeFaq()
        setUpFaqTableView()
    }
    
    private func observeFaq() {
        guard let faqRef = faqRef else {
            return
        }
        
        faqAddRefHandle = faqRef.observe(.childAdded, with: { (snapshot) -> Void in
            DispatchQueue.main.async {
                self.faqs.add(snapshot: snapshot)
                self.faqTableView.reloadData()
            }
        })
    }

    private func setUpFaqTableView() {
        faqTableView.dataSource = self
        faqTableView.delegate = self
        faqTableView.allowsSelection = false
    }
    
    deinit {
        if let addHandle = faqAddRefHandle {
            faqRef?.removeObserver(withHandle: addHandle)
        }
    }
    
}

// MARK: UITableViewDelegate and UITabelViewDataSource
extension FaqViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        faqInfo = faqs.retrieveFaqs()
        return faqInfo.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.item
        guard index != 0 else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Config.informationHeaderCell,
                                                           for: indexPath) as? InformationHeaderTableViewCell else {
                return InformationHeaderTableViewCell()
            }
            cell.setHeader(Config.faqHeader)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Config.faqCell,
                                                       for: indexPath) as? FaqTableViewCell else {
            return FaqTableViewCell()
        }
        let faq = faqInfo[index - 1]
        cell.setUp(question: faq.question, answer: faq.answer, link: faq.link)
        return cell
    }
    
}
