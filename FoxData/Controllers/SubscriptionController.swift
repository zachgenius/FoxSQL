//
//  SubscriptionController.swift
//  FoxData
//
//  Created by Zach Wang on 4/25/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import StoreKit

class SubscriptionController: BaseViewController {

    var tableView:UITableView!
    
    var subs:[SKProduct] = []
    
    var selected:SKProduct?
    
    var callback:(()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Subscription"
        let closeButton = self.generateNavBarIconItem(imageName: "back", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton
        tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }
        
        self.showLoading()
        SubscriptionManager.get().loadSubscriptionCodes(){[unowned self] codes in
            if codes == nil{
                self.hideLoading()
                self.showFailurePop("Subscription", "Failed to download Subscription Products, please check your network and try again later")
                return
            }
            
            let set = Set<String>.init(codes!)
            let productRequest = SKProductsRequest.init(productIdentifiers: set)
            productRequest.delegate = self
            productRequest.start()
        }
        
    }
    
    @objc func closeAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseNotify(_:)), name: NSNotification.Name(rawValue: "PurchaseNotify"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func purchaseNotify(_ notification:Notification){
        let userInfo = notification.userInfo
        if userInfo != nil {
            let receipt = userInfo!["content"]
            if receipt is ReceiptValidationModel {
                
                if SubscriptionManager.get().isSubscriptionValid {
                    showSuccessPop("Purchase", "Success")
                    if self.navigationController!.viewControllers.count == 1{
                        self.dismiss(animated: true) {[unowned self] in
                            self.callback?()
                        }
                    }
                    else{
                        self.navigationController?.popViewController(animated: true)
                        self.callback?()
                    }
                }
                else {
                    if SubscriptionManager.get().expireDateTimestamp > 0 {
                        showFailurePop("Purchase", "Sorry, your latest subscription has already expired")
                    }
                    else {
                        showFailurePop("Purchase", "Sorry, you need to subscribe a plan first")
                    }
                }
                
            }
            else {
                showFailurePop("Purchase", receipt as? String ?? "Failed")
            }
        }
        
        hideLoading()
    }

}

extension SubscriptionController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subs.count
        }
        else if section == 3 {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "cell")
        }
        
        if indexPath.section == 0{
            let item = subs[indexPath.row]
            cell?.textLabel?.text = item.localizedTitle
            
            let numberFormatter = NumberFormatter.init()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = item.priceLocale
            let price = numberFormatter.string(from: item.price)
            cell?.detailTextLabel?.text = price
            
            if item == self.selected {
                cell?.accessoryType = .checkmark
            }
            else {
                cell?.accessoryType = .none
            }
            
        }
        else if indexPath.section == 1{
            
            var purCell = tableView.dequeueReusableCell(withIdentifier: "purchase")
            if purCell == nil {
                purCell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "purchase")
            }
            if self.selected == nil {
                purCell?.textLabel?.text = "Please select a plan"
                purCell?.detailTextLabel?.text = ""
            }
            else {
                
                purCell?.textLabel?.text = "Subscribe Now"
                purCell?.detailTextLabel?.text = ""
                if #available(iOS 11.2, *) {
                    if selected!.introductoryPrice != nil && selected!.introductoryPrice!.paymentMode == .freeTrial {
                        purCell?.textLabel?.text = "START FREE TRIAL"
                        let discount = selected!.introductoryPrice!
                        let numberFormatter = NumberFormatter.init()
                        numberFormatter.formatterBehavior = .behavior10_4
                        numberFormatter.numberStyle = .currency
                        numberFormatter.locale = selected!.priceLocale
                        let price = numberFormatter.string(from: selected!.price)
                        var period = ""
                        if selected!.productIdentifier == "foxsqlannual"{
                            period = "/ year"
                        }
                        else if selected!.productIdentifier == "foxsqlmonthly"{
                            period = "/ month"
                        }
                        
                        var freeUnit = ""
                        if discount.subscriptionPeriod.unit == .day {
                            if discount.subscriptionPeriod.numberOfUnits == 1 {
                                freeUnit = "day"
                            }
                            else {
                                freeUnit = "days"
                            }
                        }else if discount.subscriptionPeriod.unit == .week{
                            if discount.subscriptionPeriod.numberOfUnits == 1 {
                                freeUnit = "week"
                            }
                            else {
                                freeUnit = "weeks"
                            }
                        }
                        
                        purCell?.detailTextLabel?.text = "\(discount.subscriptionPeriod.numberOfUnits) \(freeUnit) free trial and then \(price!) \(period)/\(freeUnit)"
                    }
                }
                
                
            }
            
            return purCell!
        }
        else if indexPath.section == 2{
            cell?.textLabel?.text = "Restore Purchase"
            cell?.detailTextLabel?.text = ""
        }
        else if indexPath.section == 3{
            cell?.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell?.textLabel?.text = "Term of use"
                cell?.detailTextLabel?.text = ""
            } else if indexPath.row == 1 {
                cell?.textLabel?.text = "Manage Subscriptions"
                cell?.detailTextLabel?.text = ""
            }
        }
        
        return cell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 { // item
            selected = self.subs[indexPath.row]
            tableView.reloadData()
        }
        else if indexPath.section == 1 { // purchase
            if selected != nil{
                SubscriptionManager.get().purchase(selected!)
                showLoading()
            }
        }
        else if indexPath.section == 2 { // restore
            SubscriptionManager.get().restorePurchase()
            showLoading()
        }
        else if indexPath.section == 3{
            var urlString:String = ""
            if indexPath.row == 0 { // term of use
                urlString = "https://www.wildfox.dev/foxsqlpolicy.html"
            } else if indexPath.row == 1 { // manage subscription
                urlString = "itms-apps://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"
            }
            
            let url = URL(string: urlString)
            if url != nil{
                UIApplication.shared.open(url!)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 3 {
            let label = UITextView()
            label.isEditable = false
            label.textContainerInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
            label.textAlignment = .justified
            label.isScrollEnabled = false
            label.isSelectable = false
            let sp = NSMutableString.init(string: "Auto-renewal Subscription Announcement:\n")
            sp.append("1. Payment: \nFoxSQL provides Monthly and Annual auto-renewal subscriptions. Payment will be charged at the beginning of the subscription duration.\n")
            sp.append("2. Re-new: \niTunes will charge you subscription fee before the deadline of a term automatically and then expiry dates will be updated.\n")
            sp.append("3. Cancellation: \nIf you would like to cancel the subscription, please open Settings -> iTunes Store and App Store -> Apple ID -> Subscriptions, cancel the subscription mannually and then payment will not be charged after current duration expired.")
            
            label.textColor = UIColor.gray
            label.text = sp as String
            label.font = UIFont.systemFont(ofSize: 14)
            return label
        }
        
        return nil
    }
    
}

extension SubscriptionController : SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.hideLoading()
        self.subs = response.products
        if self.subs.count > 0 {
            self.selected = self.subs[0]
        }
        self.tableView.reloadData()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.hideLoading()
        showFailurePop("Purchase", "Cannot make connection to AppStore: \(error.localizedDescription)")
    }
}
