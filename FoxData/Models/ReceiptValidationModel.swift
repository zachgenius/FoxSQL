//
//  ReceiptModel.swift
//  FoxData
//
//  Created by Zach Wang on 4/26/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

import UIKit

class ReceiptValidationModel: NSObject {
    
    var status = 0
    var environment = "Sandbox"
    var receipt: ReceiptModel?
    var latestReceiptInfo:[InAppModel] = []
    var latestReceipt = ""
    var pendingRenewalInfo:[ReceiptPendingRenewalInfo] = []

    override init() {
        
    }
    
    init(from:Dictionary<String,Any>) {
        status = from["status"] as! Int
        environment = from["environment"] as! String
        latestReceipt = from["latest_receipt"] as! String
        if from["receipt"] is [String : Any] {
            receipt = ReceiptModel.init(from: from["receipt"] as! [String : Any])
        }
        
        if from["latest_receipt_info"] is [[String: Any]] {
            let array = from["latest_receipt_info"] as! [[String: Any]]
            for item in array {
                latestReceiptInfo.append(InAppModel.init(from: item))
            }
        }
        
        if from["pending_renewal_info"] is [[String: Any]] {
            let array = from["pending_renewal_info"] as! [[String: Any]]
            for item in array {
                pendingRenewalInfo.append(ReceiptPendingRenewalInfo.init(from: item))
            }
        }
    }
    
}

class ReceiptModel : NSObject {
    var receiptType = ""
    var adamId = 0
    var appItemId = ""
    var bundleId = ""
    var applicationVersion = ""
    var downloadId = 0
    var versionExternalIdentifier = ""
    var originalApplicationVersion = ""
    var inApp:[InAppModel] = []
    var receiptCreationDate = ""
    var receiptCreationDateMs:Int64 = 0
    var receiptCreationDatePts = ""
    var requestDate = ""
    var requestDateMs:Int64 = 0
    var requestDatePts = ""
    var originalPurchaseDate = ""
    var originalPurchaseDateMs:Int64 = 0
    var originalPurchaseDatePts = ""
    override init() {
        
    }
    
    init(from:Dictionary<String,Any>) {
        receiptType = from["receipt_type"] as! String
        adamId = from["adam_id"] as! Int
        appItemId = from["app_item_id"] as! String
        bundleId = from["bundle_id"] as! String
        applicationVersion = from["application_version"] as! String
        downloadId = from["download_id"] as! Int
        versionExternalIdentifier = from["version_external_identifier"] as! String
        originalApplicationVersion = from["original_application_version"] as! String
        if from["in_app"] is [[String: Any]] {
            let array = from["in_app"] as! [[String: Any]]
            for item in array {
                inApp.append(InAppModel.init(from: item))
            }
        }
        
        
        receiptCreationDate = from["receipt_creation_date"] as! String
        receiptCreationDateMs = Int64(from["receipt_creation_date_ms"] as! String) ?? 0
        receiptCreationDatePts = from["receipt_creation_date_pst"] as! String
        requestDate = from["request_date"] as! String
        requestDateMs = Int64(from["request_date_ms"] as! String) ?? 0
        requestDatePts = from["request_date_pst"] as! String
        originalPurchaseDate = from["original_purchase_date"] as! String
        originalPurchaseDateMs = Int64(from["original_purchase_date_ms"] as! String) ?? 0
        originalPurchaseDatePts = from["original_purchase_date_pst"] as! String
    }
}

class InAppModel : NSObject{
    
    var quantity = 0
    var productId = ""
    var transactionId = ""
    var originalTransactionId = ""
    var webOrderLineItemId = ""
    var isTrialPerial = false
    var isIntroOfferPeriod = false
    var expiresDate = ""
    var expiresDateMs:Int64 = 0
    var expiresDatePts = ""
    var purchaseDate = ""
    var purchaseDateMs:Int64 = 0
    var purchaseDatePts = ""
    var originalPurchaseDate = ""
    var originalPurchaseDateMs:Int64 = 0
    var originalPurchaseDatePts = ""
    var cancellationDate = ""
    var cancellationDateMs:Int64 = 0
    var cancellationDatePts = ""
    var cancellationReason = ""
    override init() {
        
    }
    
    init(from:Dictionary<String,Any>) {
        quantity = Int.init(from["quantity"] as! String) ?? 0
        productId = from["product_id"] as? String ?? ""
        transactionId = from["transaction_id"] as! String
        originalTransactionId = from["original_transaction_id"] as! String
        webOrderLineItemId = from["web_order_line_item_id"] as! String
        isTrialPerial = from["is_trial_period"] as! String == "true"
        isIntroOfferPeriod = from["is_in_intro_offer_period"] as! String == "true"
        expiresDate = from["expires_date"] as! String
        expiresDateMs = Int64(from["expires_date_ms"] as! String) ?? 0
        expiresDatePts = from["expires_date_pst"] as! String
        purchaseDate = from["purchase_date"] as! String
        purchaseDateMs = Int64(from["purchase_date_ms"] as! String) ?? 0
        purchaseDatePts = from["purchase_date_pst"] as! String
        originalPurchaseDate = from["original_purchase_date"] as! String
        originalPurchaseDateMs = Int64(from["original_purchase_date_ms"] as! String) ?? 0
        originalPurchaseDatePts = from["original_purchase_date_pst"] as! String
        cancellationDate = from["cancellation_date"] as? String ?? ""
        cancellationDateMs = Int64(from["cancellation_date_ms"] as? String ?? "0") ?? 0
        cancellationDatePts = from["cancellation_date_pst"] as? String ?? ""
        cancellationReason = from["cancellation_reason"] as? String ?? ""
    }
}

class ReceiptPendingRenewalInfo : NSObject {
    
    var expirationIntent = ""
    var autoRenewProductId = ""
    var isInBillingRetryPeriod = ""
    var autoRenewStatus = ""
    var priceConsentStatus = ""
    var productId = ""
    var originalTransactionId = ""
    
    override init() {
        
    }
    
    init(from:Dictionary<String,Any>) {
        expirationIntent = from["expiration_intent"] as! String
        autoRenewProductId = from["auto_renew_product_id"] as! String
        isInBillingRetryPeriod = from["is_in_billing_retry_period"] as! String
        autoRenewStatus = from["auto_renew_status"] as! String
        priceConsentStatus = from["price_consent_status"] as! String
        productId = from["product_id"] as! String
        originalTransactionId = from["original_transaction_id"] as! String
    }
}
