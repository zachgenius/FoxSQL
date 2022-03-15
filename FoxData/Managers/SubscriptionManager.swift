//
//  SubscriptionManager.swift
//  FoxData
//
//  Created by Zach Wang on 4/25/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit
import Alamofire
import StoreKit

class SubscriptionManager : NSObject{
    private static let _sharedManager = SubscriptionManager()
    
    private override init(){
        
    }
    
    class func get()->SubscriptionManager {
        return _sharedManager
    }
    
    private var receipt:ReceiptValidationModel?
    
    var isSubscriptionValid = false
    var expireDateTimestamp:Int64 = 0
    var cancellationTimestamp:Int64 = 0
    var isLifelong = false
    
    /// 读取当前用户的订阅信息
    func loadMySubscription(){
        SKPaymentQueue.default().add(self)
        
        expireDateTimestamp = Int64(UserDefaults.standard.integer(forKey: "expireDate"))
        isLifelong = UserDefaults.standard.bool(forKey: "lifelong")
        
        let currentTime = Date.init().timeIntervalSince1970
        let last = TimeInterval.init(expireDateTimestamp)
        isSubscriptionValid = isLifelong || currentTime < last
        
        //应该不需要每次都检查.
//        uploadReceipt { (isSuccess, receipt) in
//            if receipt != nil {
//                let userInfo:[String: Any] = [
//                    "success" : isSuccess,
//                    "content" : receipt!
//                ]
//
//                let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
//                NotificationCenter.default.post(notification)
//            }
//            else {
//                let userInfo:[String: Any] = [
//                    "success" : isSuccess,
//                    "content" : "Error"
//                ]
//                let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
//                NotificationCenter.default.post(notification)
//            }
//        }
    }
    
    func loadSubscriptionCodes(_ callback: @escaping (_ list:[String]?)->Void) {
        let parameters: Parameters = [
            "bundle" : "pro.wildfox.studio",
            "platform" : "ios"
        ]
        Alamofire.request("https://foxapi.wildfox.dev/fetchSubscriptions", method: .post, parameters: parameters).responseJSON {(response) in
            
            if response.result.isFailure {
                callback(nil)
                return
            }
            
            if let dict = response.result.value as? [String : AnyObject]
            {
                if let content = dict["content"] as? [String] {
                    callback(content)
                    return
                }
            }
            
            callback(nil)
        }
    }
    
    func purchase(_ item:SKProduct){
        let payment = SKPayment.init(product: item)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchase(){
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func uploadReceipt(_ callback:@escaping ((_ success: Bool, _ receipt:ReceiptValidationModel? ) -> Void)){
        if let receiptData = loadReceipt() {
            let parameters: Parameters = [
                "receipt": receiptData.base64EncodedString()
            ]
            Alamofire.request("https://foxapi.wildfox.dev/appReceipt",
                              method: .post,
                              parameters: parameters
                ).responseJSON {[unowned self](response) in
                
                if response.result.isFailure { // 网络错误, 暂时利用上次的结果
                    callback(false, self.receipt)
                    return
                }
                
                if let dict = response.result.value as? [String : AnyObject]
                {
                    let status = dict["status"] as! Int
                    if status == 0 {
                        if let content = dict["content"] as? String {
                            
                            let json = try! JSONSerialization.jsonObject(with: content.data(using: .utf8)!, options: []) as! Dictionary<String, Any>
                            let receipt = ReceiptValidationModel.init(from: json)
                            self.checkReceipt(receipt)
                            callback(true, receipt)
                            return
                        }
                    }
                    
                }
                
                callback(false, nil)
                self.receipt = nil
            }
        } else {
            callback(false, nil)
            self.receipt = nil
        }
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
    
    ///整理receipt
    private func checkReceipt(_ receipt:ReceiptValidationModel) {
        self.receipt = receipt
        let receiptCount = receipt.latestReceiptInfo.count
        if receiptCount > 0 {
            let last = receipt.latestReceiptInfo[receiptCount - 1]
            self.expireDateTimestamp = last.expiresDateMs / 1000
            let current = Date.init().timeIntervalSince1970
            let lastTime = TimeInterval(self.expireDateTimestamp)
            self.isSubscriptionValid = current < lastTime
            
            //TODO + lifelong
            
        }else {
            self.isSubscriptionValid = false
            self.expireDateTimestamp = 0
        }
        
        UserDefaults.standard.set(self.expireDateTimestamp, forKey: "expireDate")
        UserDefaults.standard.set(self.isLifelong, forKey: "lifelong")
    }
}

extension SubscriptionManager : SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for item in transactions {
            switch item.transactionState {
            case .purchasing:
                handlePurchasingState(for: item, in: queue)
                break
            case .purchased:
                handlePurchasedState(for: item, in: queue)
                break
            case .failed:
                handleFailedState(for: item, in: queue)
                break
            case .restored:
                handleRestoredState(for: item, in: queue)
                break
            case .deferred:
                handleDeferredState(for: item, in: queue)
                break
            }
        }
    }
    
    /// 恢复失败
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        let userInfo:[String: Any] = [
            "success" : false,
            "content" : error.localizedDescription
        ]
        
        let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
    
    /// 恢复完成
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Restore Completed")
        checkUploadReceipt(nil)
    }
    
    func handlePurchasingState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("User is attempting to purchase product id: \(transaction.payment.productIdentifier)")
    }
    
    func handlePurchasedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        checkUploadReceipt(transaction)
        
    }
    
    func handleRestoredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        
    }
    
    func handleFailedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        
        //防止因为网络出现bug, 这里再调用一下
        let userInfo:[String: Any] = [
            "success" : false,
            "content" : transaction.error?.localizedDescription ?? "It seems something went wrong. Please try again later"
        ]
        
        let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
    
    func handleDeferredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        checkUploadReceipt(transaction)
    }
    
    private func checkUploadReceipt(_ transaction:SKPaymentTransaction?){
        
        uploadReceipt { (isSuccess, receipt) in
            if receipt != nil {
                let userInfo:[String: Any] = [
                    "success" : isSuccess,
                    "content" : receipt!
                ]
                
                let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
                NotificationCenter.default.post(notification)
            }
            else {
                let userInfo:[String: Any] = [
                    "success" : isSuccess,
                    "content" : transaction?.error?.localizedDescription ?? "Oops, something went wrong. Please tap \"Restore Purchase\" later"
                ]
                let notification = Notification.init(name: Notification.Name(rawValue: "PurchaseNotify"), object: nil, userInfo: userInfo)
                NotificationCenter.default.post(notification)
            }
        }
    }
}
