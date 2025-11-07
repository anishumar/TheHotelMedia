//
//  StoreKitAndIAPManager.swift
//  TheHotelMedia
//
//  Created by MAC on 12/02/25.
//

import Foundation
import StoreKit


class StoreKitAndIAPManager: ObservableObject {
    
    let dataManager = SubscriptionPlanManager()
    @Published var subscriptions: [Product] = []
    @Published var jwsToken: String? = nil
    
    init() {
//        listenForTransactionUpdates()
    }
    
    
    func fetchSubscriptions(productIds: [String]) async throws {
        do {
            let fetchedProducts = try await Product.products(for: productIds)
            await MainActor.run {
                self.subscriptions = fetchedProducts
            }
        } catch {
            throw error
        }
    }
    
    
    func purchaseSubscription(subscription: Product) async -> (String?, String) {
        await finishTransactions()
        do {
            let result = try await subscription.purchase()
            
            switch result {
            case .success(let verificationResult):
                return (await getJwsToken(retries: 100), "success")
                
            case .userCancelled:
                return (nil, "cancelled")
            case .pending:
                break
            default:
                break
            }
            return (await getJwsToken(retries: 100), "other")
        } catch {
            print(error)
            return (await getJwsToken(retries: 50), "error")
//            return nil
        }
    }
    
    
//    func getJwsToken(retries: Int = 0) async -> String? {
//        for await verificationResult in StoreKit.Transaction.currentEntitlements {
//            if case .verified(let transaction) = verificationResult {
//                print(verificationResult.jwsRepresentation)
//                await transaction.finish()
//                return verificationResult.jwsRepresentation
//            }
//        }
//        
//        if retries > 0 {
//            for i in 0..<retries {
//                try? await Task.sleep(nanoseconds: 10_000_000_000)
//                print("Retry no. \(i), ☘️☘️☘️☘️☘️☘️☘️☘️☘️☘️☘️☘️☘️")
//                for await verificationResult in StoreKit.Transaction.currentEntitlements {
//                    if case .verified(let transaction) = verificationResult {
//                        print(verificationResult.jwsRepresentation)
//                        await transaction.finish()
//                        return verificationResult.jwsRepresentation
//                    }
//                }
//            }
//        }
//        
//        return nil
//    }
    func getJwsToken(retries: Int = 0) async -> String? {
        // First check
        if Task.isCancelled { return nil }

        for await verificationResult in StoreKit.Transaction.currentEntitlements {
            if Task.isCancelled { return nil }

            if case .verified(let transaction) = verificationResult {
                print(verificationResult.jwsRepresentation)
                await transaction.finish()
                return verificationResult.jwsRepresentation
            }
        }
        
        if retries > 0 {
            for i in 0..<retries {
                if Task.isCancelled { return nil }

                try? await Task.sleep(nanoseconds: 10_000_000_000)

                print("Retry no. \(i), ☘️☘️☘️")

                for await verificationResult in StoreKit.Transaction.currentEntitlements {
                    if Task.isCancelled { return nil }

                    if case .verified(let transaction) = verificationResult {
                        print(verificationResult.jwsRepresentation)
                        await transaction.finish()
                        return verificationResult.jwsRepresentation
                    }
                }
            }
        }
        
        return nil
    }

    
    
    func sendTransactionToServer(jwsTransaction: String) {
        
    }
    
    
    func listenForTransactionUpdates() {
        Task {
            for await verificationResult in StoreKit.Transaction.updates {
                if case .verified( _) = verificationResult {
                    await MainActor.run {
                        print(verificationResult.jwsRepresentation)
                        jwsToken = verificationResult.jwsRepresentation
                    }
                }
            }
        }
    }
    
    
    func checkActiveSubscription(groupID: String) async -> Bool {
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: groupID)

            for status in statuses {
                if case .verified(_) = status.transaction,
                   case .verified(_) = status.renewalInfo,
                   status.state == .subscribed || status.state == .inGracePeriod {
                    print("✅ Subscription is ACTIVE")
                    return true
                }
            }
        } catch {
            print("❌ Error fetching subscription status: \(error)")
        }
        return false
    }
    
    
    func fetchActiveSubscriptions() async -> Bool {
        var activeSubscriptions: Set<StoreKit.Transaction> = []

        for await entitlement in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                // Ignore revoked transactions
                if let revocationDate = transaction.revocationDate {
                    continue
                }

                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {  // Subscription is still valid
                        activeSubscriptions.insert(transaction)
                    }
                } else {
                    // Non-consumable purchase (one-time unlock)
                    activeSubscriptions.insert(transaction)
                }
            }
        }
        
        print("Active Subscriptions: \(activeSubscriptions)")
        return !activeSubscriptions.isEmpty
    }


    
    
    func finishTransactions() async {
        for await result in StoreKit.Transaction.unfinished {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
    }
}
