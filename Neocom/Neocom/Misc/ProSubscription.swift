//
//  ProSubscription.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
import SwiftUI
import ASReceipt
import StoreKit
import Combine

struct ProSubscription: View, Equatable {
    static func == (lhs: ProSubscription, rhs: ProSubscription) -> Bool {
        return lhs.receipt === rhs.receipt
    }
    
    
    
    
    @State private var receipt: Receipt?
    
    private var receiptChangesPublisher: FileChangesPublisher? {
        Bundle.main.appStoreReceiptURL.map {
            FileChangesPublisher(path: $0.path)
        }
    }
    
    @State private var receiptPublisher: AnyPublisher<Receipt, Error>? = Receipt.receiptPublisher()
    
    @State private var products: Result<[String: SKProduct], SKError>?
    @State private var productsPublisher = SKProductsRequest.productsPublisher(productIdentifiers: Set(Config.current.inApps.allProducts)).receive(on: RunLoop.main).eraseToAnyPublisher()
    @State private var restoreCompletedTransactionsPublisher: AnyPublisher<Result<[SKPaymentTransaction], Error>, Never>?

    @State private var selectedProduct: SKProduct?
    @State private var error: IdentifiableWrapper<Error>?
    
    @State private var isRestoreCompleted = false
    @State private var selectedLifetimeProduct: IdentifiableWrapper<SKProduct>?
    @State private var isDonationAlertPresented = false
    
    private func purchase(_ product: SKProduct) {
        SKPaymentQueue.default().add(SKPayment(product: product))
        withAnimation {
            selectedProduct = product
        }
    }
    
    private func restore() {
        withAnimation {
            restoreCompletedTransactionsPublisher = RestoreCompletedTransactionsPublisher().receive(on: RunLoop.main).asResult().share().eraseToAnyPublisher()
        }
    }
    
    private func manageSubscriptions() {
        let url = URL(string: "https://apps.apple.com/account/subscriptions")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private var subscriptionRenewalInfo: some View {
        VStack {
        Text("Payment will be charged to iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. Auto-renew option can be turned off in iTunes Account Settings.")
            HStack(alignment: .top) {
                Spacer()
                privacyPolicyButton
                Spacer()
                termsOfUseButton
                Spacer()
            }
        }
    }
    
    private var privacyPolicyButton: some View {
        Button(action: {UIApplication.shared.open(Config.current.privacy, options: [:], completionHandler: nil)}) {
            Text("Privacy Policy")
        }
    }
    
    private var termsOfUseButton: some View {
        Button(action: {UIApplication.shared.open(Config.current.terms, options: [:], completionHandler: nil)}) {
            Text("Terms of Use")
        }
    }
    
    private func didFinish(transaction: SKPaymentTransaction) {
        guard selectedProduct?.productIdentifier == transaction.payment.productIdentifier else {return}
        if transaction.transactionState == .failed, (transaction.error as? SKError)?.code != SKError.paymentCancelled {
            error = transaction.error.map{IdentifiableWrapper($0)}
        }
        withAnimation {
            selectedProduct = nil
        }
    }
    
    private func didReceiveProducts(_ result: Result<[SKProduct], SKError>) {
        products = result.map{products in Dictionary(products.map{($0.productIdentifier, $0)}, uniquingKeysWith: {a, _ in a})}
        productsPublisher = Empty().eraseToAnyPublisher()
    }
    
    private func didRestorePurchases(_ result: Result<[SKPaymentTransaction], Error>) {
        switch result {
        case .success:
            break
        case let .failure(error):
            if (error as? SKError)?.code != SKError.paymentCancelled {
                self.error = IdentifiableWrapper(error)
            }
        }
        withAnimation {
            restoreCompletedTransactionsPublisher = nil
        }
        isRestoreCompleted = true
    }
    
    private func lifetimeProductAlert(_ product: SKProduct) -> Alert {
        Alert(title: Text("Lifetime Subscription"),
              message: Text("Remember to cancel any auto-renewable subscriptions."),
              primaryButton: .default(Text("Continue"), action: {self.purchase(product)}),
              secondaryButton: .cancel())
    }
    
    private var donationAlert: ActionSheet {
        let buttons = self.products?.value.map { products in
            Config.current.inApps.donate.compactMap {
                products[$0]
            }.map { product in
                ActionSheet.Button.default(Text("Donate \(product.priceFormatter.string(from: product.price) ?? "")")) {
                    self.purchase(product)
                }
            }
        } ?? []
        return ActionSheet(title: Text("Donation"), message: nil, buttons: buttons + [.cancel()])
    }
    

    var body: some View {
        let error = self.products?.error
        let productIDs = Config.current.inApps.autoRenewableSubscriptions + Config.current.inApps.lifetimeSubscriptions
        let products = self.products?.value.map { products in
            productIDs.compactMap {
                products[$0]
            }
        }
        
        let currentSubscription = receipt.flatMap { receipt in
            receipt.inAppPurchases?
                .filter{$0.inAppType == .autoRenewableSubscription && !$0.isCancelled}
                .max {$0.expiresDate! < $1.expiresDate!}
        }
        
        let lifetimePurchase = receipt?.inAppPurchases?.filter{$0.productID != nil}.first{Config.current.inApps.lifetimeSubscriptions.contains($0.productID!)}
        
        return List {
            if lifetimePurchase != nil {
                Section {
                    SubscriptionInfo(purchase: lifetimePurchase!, product: products?.first{$0.productIdentifier == lifetimePurchase?.productID})
                }
            }
            else if currentSubscription == nil {
                Section {
                    VStack(alignment: .leading) {
                        Text("Tired of seeing those pesky ads? Why not upgrade to an Ad Free Subscription!")
                        Text("- Remove ads from every screen\n- Remove ads across all devices with the same Apple ID")
                    }
                }
            }
            else {
                Section {
                    SubscriptionInfo(purchase: currentSubscription!, product: products?.first{$0.productIdentifier == currentSubscription?.productID})
                }
            }
            
            if lifetimePurchase == nil {
                Section(header: Text("SUBSCRIPTION PLANS")) {
                    if products == nil {
                        ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity)
                    }
                    else if products != nil {
                        ForEach(products!, id: \.productIdentifier) { product in
                            Button(action: {
                                if Config.current.inApps.lifetimeSubscriptions.contains(product.productIdentifier) {
                                    self.selectedLifetimeProduct = IdentifiableWrapper(product)
                                }
                                else {
                                    self.purchase(product)
                                }
                            }) {
                                ProductCell(product: product, isSelected: product.productIdentifier == currentSubscription?.productID && currentSubscription?.isExpired == false)
                            }
                        }
                    }
                    else if error != nil{
                        Text(error!)
                    }
                }
                .alert(item: $selectedLifetimeProduct) { product in
                    self.lifetimeProductAlert(product.wrappedValue)
                }

            }
            else {
//                Section(footer:
                Text("You can now use Neocom without any restrictions on all devices for unlimited time. But you can make a donation to support the development.")
                if products == nil {
                    ActivityIndicatorView(style: .medium).frame(maxWidth: .infinity)
                }
                else {
                    Button(action: {self.isDonationAlertPresented = true}) {
                        Text("Make Donation").frame(maxWidth: .infinity)
                    }
                    .actionSheet(isPresented: $isDonationAlertPresented) {
                        self.donationAlert
                    }
                }
//                }
            }

            Section(footer: subscriptionRenewalInfo) {
                Button(action: restore) {
                    Text("Restore Purchases").frame(maxWidth: .infinity)
                }
                .alert(isPresented: $isRestoreCompleted) {
                    Alert(title: Text("Restore Completed"), message: Text("Your previous purchases are being restored. Thank you!"), dismissButton: .cancel(Text("Close")))
                }

                Button(action: manageSubscriptions) {
                    Text("Manage Subscriptions").frame(maxWidth: .infinity)
                }
            }

//            Section(footer: subscriptionRenewalInfo) {
//                Button(action: {UIApplication.shared.open(Config.current.privacy, options: [:], completionHandler: nil)}) {
//                    Text("Privacy Policy").frame(maxWidth: .infinity)
//                }
//                Button(action: {UIApplication.shared.open(Config.current.terms, options: [:], completionHandler: nil)}) {
//                    Text("Terms of Use").frame(maxWidth: .infinity)
//                }
//            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Subscriptions"))
        .onReceive(productsPublisher.asResult(), perform: didReceiveProducts)
        .onReceive(receiptChangesPublisher?.asResult().receive(on: RunLoop.main).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()) { _ in
            self.receiptPublisher = Receipt.receiptPublisher()
//            self.receipt = Bundle.main.appStoreReceiptURL.flatMap { url in
//                try? Receipt(data: Data(contentsOf: url))
//            }
        }
        .onReceive(receiptPublisher?.asResult().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()) { result in
            self.receipt = result.value
            self.receiptPublisher = nil
        }
//    .onReceive(FileChangesPublisher(path: <#T##String#>), perform: <#T##(Publisher.Output) -> Void#>)
//        .onReceive(receiptPublisher) { result in
//            self.receipt = result
//        }
        .onReceive(NotificationCenter.default.publisher(for: .didFinishPaymentTransaction).receive(on: RunLoop.main)) { note in
            guard let transaction = note.object as? SKPaymentTransaction else {return}
            self.didFinish(transaction: transaction)
        }
        .onReceive(restoreCompletedTransactionsPublisher ?? Empty().eraseToAnyPublisher(), perform: didRestorePurchases)
        .alert(item: $error) {
            Alert(title: Text("Error"), message: Text($0.wrappedValue.localizedDescription), dismissButton: .cancel(Text("Close")))
        }
        .overlay(selectedProduct != nil || restoreCompletedTransactionsPublisher != nil ? ActivityIndicator().edgesIgnoringSafeArea(.all) : nil)
    }
}

struct ProSubscription_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        ProSubscription()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif
