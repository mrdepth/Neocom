//
//  AdsContainerView.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

#if canImport(Appodeal)
#if !targetEnvironment(macCatalyst)
import SwiftUI
import Combine
import ASReceipt

struct AdsContainerView<Content: View>: View {
    @ObservedObject private var advertisingProvider = AdvertisingProvider.shared
    @State private var isAdFree = true
    @ObservedObject private var isLifetimeUpgrade = UserDefault(wrappedValue: false, key: .isLifetimeUpgrade)
    
    @State private var receiptPublisher: AnyPublisher<Receipt, Error>? = Receipt.receiptPublisher()
    private var receiptChangesPublisher: FileChangesPublisher? {
        Bundle.main.appStoreReceiptURL.map {
            FileChangesPublisher(path: $0.path)
        }
    }

    
    private var content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
            if advertisingProvider.isAdInitialised && advertisingProvider.isBannerReady && !isAdFree && !isLifetimeUpgrade.wrappedValue {
                AdvertisingProvider.Banner().frame(height: advertisingProvider.bannerHeight).background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didFinishStartup)) { _ in
            self.advertisingProvider.initialize()
        }
        .onReceive(receiptChangesPublisher?.asResult().receive(on: RunLoop.main).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()) { _ in
            self.receiptPublisher = Receipt.receiptPublisher()
        }
        .onReceive(receiptPublisher?.asResult().eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()) { result in
            let transactions = result.value?.inAppPurchases
            let isAdFree = transactions?.contains{($0.inAppType == .autoRenewableSubscription && !$0.isExpired && !$0.isCancelled) || Config.current.inApps.lifetimeSubscriptions.contains($0.productID ?? "")}
            self.isAdFree = isAdFree ?? false
            self.receiptPublisher = nil
        }
    }
}

struct AdsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AdsContainerView {
            NavigationView {
                List {
                    Text(verbatim: "Hello, World")
                }.listStyle(GroupedListStyle())
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
#endif
#endif
