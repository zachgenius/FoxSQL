//
// 设置
//
// Created by Zach Wang on 2019-03-01.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import UIKit
import SnapKit
import UIColor_Hex_Swift

class SettingsController : BaseViewController {

    private var tableView:UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor("#efeff4")

        let closeButton = self.generateNavBarIconItem(imageName: "close", target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = closeButton

        self.title = "Settings"

        let logo = UIImageView.init(image: UIImage.init(named: "icon-1024"))
        let logoWH:CGFloat = 60
        logo.layer.cornerRadius = logoWH / 2
        logo.layer.masksToBounds = true
        self.view.addSubview(logo)

        let label = UILabel.init()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.numberOfLines = 2

        let infoDic = Bundle.main.infoDictionary
// 获取App的版本号
        let appVersion = infoDic?["CFBundleShortVersionString"]
// 获取App的build版本
        let appBuildVersion = infoDic?["CFBundleVersion"]
// 获取App的名称
        let appName = infoDic?["CFBundleDisplayName"]

        label.text = "\(appName!)\n\(appVersion!) ( \(appBuildVersion!) )"

        self.view.addSubview(label)

        tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
        
        tableView?.delegate = self
        tableView?.dataSource = self
        self.view.addSubview(tableView!)

        logo.snp.makeConstraints { maker in
            maker.width.equalTo(logoWH)
            maker.height.equalTo(logoWH)
            maker.left.equalToSuperview().offset(10)
            maker.topMargin.equalToSuperview().offset(20)
        }

        label.snp.makeConstraints { maker in
            maker.centerY.equalTo(logo)
            maker.left.equalTo(logo.snp.right).offset(15)
        }

        tableView?.snp.makeConstraints { maker in
            maker.top.equalTo(logo.snp.bottom)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()

        }

    }

    @objc func closeAction(){
        self.dismiss(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseNotify(_:)), name: NSNotification.Name(rawValue: "PurchaseNotify"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func purchaseNotify(_ notification:Notification){
        self.tableView?.reloadData()
    }
}

extension SettingsController:UITableViewDelegate, UITableViewDataSource{
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.section == 0 {
            if indexPath.row == 0 { // subscription
                if !SubscriptionManager.get().isSubscriptionValid {
                    let controller = SubscriptionController.init()
                    controller.callback = {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
            else if indexPath.row == 1 {
                let urlString:String = "itms-apps://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"
                
                let url = URL(string: urlString)
                if url != nil{
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }
        }
        else if indexPath.section == 1 {
            let urlString:String
            // policy
            if indexPath.row == 0 {
                urlString = "https://www.wildfox.dev/foxsqlpolicy.html"
            }
                // website
            else if indexPath.row == 1 {
                urlString = "https://www.wildfox.dev"
            }
                // feedback on website
            else if indexPath.row == 2{
                let localeCode = NSLocale.current.languageCode
                if localeCode == "zh"{
                    urlString = "http://v876vssu39abgva9.mikecrm.com/R4XEfHS"
                }
                else {
                    urlString = "https://docs.google.com/forms/d/e/1FAIpQLSdYKcCiwtmtxarMvN41143lcTqrdpFkuL1O1sAb674bpfOVYg/viewform?usp=pp_url"
                }
            }
                // feedback email
            else if indexPath.row == 3 {
                urlString = "mailto:foxsql@wildfox.pro?subject=\"FoxSQL Feedback\""
            }
                // app store
            else if indexPath.row == 4 {
                urlString = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1450483272"
            }
            else {
                urlString = "https://wildfox.dev"
            }
            
            let url = URL(string: urlString)
            if url != nil{
                UIApplication.shared.open(url!)
            }
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "cell")
        }
        cell!.accessoryType = .disclosureIndicator
        cell!.detailTextLabel?.text = ""
        if indexPath.section == 0 {
            // subscribe
            if indexPath.row == 0 {
                cell!.textLabel?.text = "FoxSQL Premium"
                
                if SubscriptionManager.get().isSubscriptionValid {
                    if SubscriptionManager.get().isLifelong {
                        cell!.detailTextLabel?.text = "Lifelong"
                    }
                    else{
                        let formatter = DateFormatter.init()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        formatter.locale = Locale.current
                        let time = formatter.string(from: Date.init(timeIntervalSince1970: TimeInterval(SubscriptionManager.get().expireDateTimestamp)))
                        cell!.detailTextLabel?.text = "~ \(time)"
                    }
                    cell!.accessoryType = .none
                    
                }else {
                    if SubscriptionManager.get().expireDateTimestamp > 0 {
                        let formatter = DateFormatter.init()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .none
                        formatter.locale = Locale.current
                        let time = formatter.string(from: Date.init(timeIntervalSince1970: TimeInterval(SubscriptionManager.get().expireDateTimestamp)))
                        cell!.detailTextLabel?.text = "Expired \(time)"
                    }
                    else {
                        cell!.detailTextLabel?.text = "Subscribe Now"
                    }
                    
                }
                
            } else if indexPath.row == 1 {
                cell!.textLabel?.text = "Manage Subscriptions"
            }
            
        }
        else if indexPath.section == 1{
            cell!.detailTextLabel?.text = ""
            // policy
            if indexPath.row == 0 {
                cell!.textLabel?.text = "Terms and Privacy Policies"
            }
                // website
            else if indexPath.row == 1 {
                cell!.textLabel?.text = "Official Website"
            }
            else if indexPath.row == 2 {
                cell!.textLabel?.text = "Feedback on website"
            }
                // feedback
            else if indexPath.row == 3 {
                cell!.textLabel?.text = "Feedback through email"
            }
                // app store
            else if indexPath.row == 4 {
                cell!.textLabel?.text = "Feedback on AppStore"
            }

        }
        return cell!
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // subscription
            return 2
        }
        // privacy, website,feedback, feedback by email
        return 5
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Subscription"
        }
        
        return "Contact & Feedback"
    }

}
