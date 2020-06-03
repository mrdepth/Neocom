//
//  StoreKit+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import Foundation
import StoreKit
import Combine
import ASReceipt

extension SKProductsRequest {
    static func productsPublisher(productIdentifiers: Set<String>) -> ProductsRequestPublisher {
        ProductsRequestPublisher(productIdentifiers: productIdentifiers)
    }
}

extension SKProduct {
    var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter
    }
}

struct ProductsRequestPublisher: Publisher {
    typealias Output = [SKProduct]
    typealias Failure = SKError

    var productIdentifiers: Set<String>
    
    private class ProductsRequestSubscription<S: Subscriber>: NSObject, SKProductsRequestDelegate, Subscription where S.Failure == Failure, S.Input == Output {
        var productIdentifiers: Set<String>
        var request: SKProductsRequest?
        var subscriber: S

        init(subscriber: S, productIdentifiers: Set<String>) {
            self.subscriber = subscriber
            self.productIdentifiers = productIdentifiers
            super.init()
        }
        
        
        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            _ = subscriber.receive(response.products)
        }
        
        func request(_ request: SKRequest, didFailWithError error: Error) {
            subscriber.receive(completion: .failure(error as? SKError ?? SKError(SKError.unknown)))
        }
        
        func requestDidFinish(_ request: SKRequest) {
            subscriber.receive(completion: .finished)
        }
        
        func request(_ demand: Subscribers.Demand) {
            if request == nil {
                let request = SKProductsRequest(productIdentifiers: productIdentifiers)
                request.delegate = self
                request.start()
            }
        }
        
        func cancel() {
            request?.cancel()
        }
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: ProductsRequestSubscription(subscriber: subscriber, productIdentifiers: productIdentifiers))
    }
}

extension SKProductSubscriptionPeriod {
    var localizedDescription: String {
        switch unit {
        case .day:
            return String.localizedStringWithFormat(NSLocalizedString("%d days", comment: ""), numberOfUnits)
        case .month:
            return String.localizedStringWithFormat(NSLocalizedString("%d months", comment: ""), numberOfUnits)
        case .week:
            return String.localizedStringWithFormat(NSLocalizedString("%d weeks", comment: ""), numberOfUnits)
        case .year:
            return String.localizedStringWithFormat(NSLocalizedString("%d years", comment: ""), numberOfUnits)
        @unknown default:
            return "unknown"
        }
    }
}

struct RestoreCompletedTransactionsPublisher: Publisher {
    typealias Output = [SKPaymentTransaction]
    typealias Failure = Error

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(subscription: RestoreCompletedTransactionsSubscription(subscriber: subscriber))
    }
    
    private class RestoreCompletedTransactionsSubscription<S: Subscriber>: NSObject, SKPaymentTransactionObserver, Subscription where S.Failure == Failure, S.Input == Output {
        private var restored: [SKPaymentTransaction]?
        
        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            restored?.append(contentsOf: transactions.filter{$0.transactionState == .restored})
        }
        
        func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            _ = subscriber.receive(restored ?? [])
            subscriber.receive(completion: .finished)
        }
        
        func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            subscriber.receive(completion: .failure(error))
        }
        
        func request(_ demand: Subscribers.Demand) {
            if restored == nil {
                restored = []
                let queue = SKPaymentQueue.default()
                queue.add(self)
                queue.restoreCompletedTransactions()
            }
        }
        
        func cancel() {
            guard restored != nil else {return}
            restored = nil
            SKPaymentQueue.default().remove(self)
        }
        
        deinit {
            cancel()
        }
        
        var subscriber: S

        init(subscriber: S) {
            self.subscriber = subscriber
            super.init()
        }
    }
}


extension Receipt {
    static func receiptPublisher(refreshIfNeeded: Bool = false) -> AnyPublisher<Receipt, Error> {
        Deferred {
            Future { promise in
//                DispatchQueue.global().async {
                    do {
                        guard let url = Bundle.main.appStoreReceiptURL else {throw RuntimeError.unknown}
                        let receipt = try Receipt(data: Data(contentsOf: url))
                        promise(.success(receipt))
                    }
                    catch {
                        promise(.failure(error))
                    }
//                }
            }
        }.eraseToAnyPublisher()
/*//        Deferred { () -> AnyPublisher<Receipt, Error> in
            guard let url = Bundle.main.appStoreReceiptURL else {return Fail(error: RuntimeError.unknown).eraseToAnyPublisher()}
            let publisher = FileChangesPublisher(path: url.path)
                .mapError{$0 as Error}
            
            if FileManager.default.fileExists(atPath: url.path) {
                return publisher.merge(with: Just(()).setFailureType(to: Error.self))
                    .tryMap {try Receipt(data: Data(contentsOf: url))}.eraseToAnyPublisher()
            }
            else {
                return publisher.tryMap {try Receipt(data: Data(contentsOf: url))}.eraseToAnyPublisher()
            }
//        }.eraseToAnyPublisher()*/
    }
}
#endif
