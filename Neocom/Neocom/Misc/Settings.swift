//
//  Settings.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct Settings: View {
    @State private var isClearCacheActionSheetPresented = false
    @ObservedObject private var notificationsEnabled = UserDefault(wrappedValue: true, key: .notificationsEnabled)
    @ObservedObject private var skillQueueNotificationOptions = UserDefault(wrappedValue: NotificationsManager.SkillQueueNotificationOptions.default.rawValue, key: .notificationSettigs)
    
    private func skillQueueNotificationCell(option: NotificationsManager.SkillQueueNotificationOptions, title: LocalizedStringKey) -> some View {
        Toggle(title, isOn: Binding(get: {
            NotificationsManager.SkillQueueNotificationOptions(rawValue: self.skillQueueNotificationOptions.wrappedValue).contains(option)
        }, set: { newValue in
            var options = NotificationsManager.SkillQueueNotificationOptions(rawValue: self.skillQueueNotificationOptions.wrappedValue)
            if newValue {
                options.insert(option)
            }
            else {
                options.remove(option)
            }
            self.skillQueueNotificationOptions.wrappedValue = options.rawValue
        }))
    }
    
    @ObservedObject private var storage = Storage.sharedStorage
    
    var body: some View {
        List {
            Section(footer: Text("Data will be restored from iCloud.")) {
                MigrateLegacyDataButton()
            }
            
            LanguagePack.packs[storage.sde.tag].map { pack in
                Section(header: Text("DATABASE LANGUAGE")) {
                    NavigationLink(destination: LanguagePacks()) {
                        VStack(alignment: .leading) {
                            Text(pack.name).foregroundColor(.primary)
                            pack.localizedName.modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
            
            Section {
                Toggle("Notifications Enabled", isOn: $notificationsEnabled.wrappedValue)
            }
            
            if notificationsEnabled.wrappedValue {
                Section(header: Text("SKILL QUEUE NOTIFICATIONS")) {
                    skillQueueNotificationCell(option: .inactive, title: "Inactive Skill Queue")
                    skillQueueNotificationCell(option: .oneHour, title: "1 Hour Left")
                    skillQueueNotificationCell(option: .fourHours, title: "4 Hours Left")
                    skillQueueNotificationCell(option: .oneDay, title: "24 Hours Left")
                    skillQueueNotificationCell(option: .skillTrainingComplete, title: "Skill Training Complete")
                }
            }
            
            Section(header: Text("CACHE"), footer: Text("Some application features may be temporarily unavailable")) {
                Button("Clear Cache") {
                    self.isClearCacheActionSheetPresented = true
                }
                .frame(maxWidth: .infinity)
                .accentColor(.red)
                .actionSheet(isPresented: $isClearCacheActionSheetPresented) {
                    ActionSheet(title: Text("Are you sure?"), buttons: [
                        .destructive(Text("Clear Cache"), action: {
                            URLCache.shared.removeAllCachedResponses()
                        }),
                        .cancel()
                    ])
                }
            }
            
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Settings")
    }
}

struct MigrateLegacyDataButton: View {
    @State private var token = FileManager.default.ubiquityIdentityToken
    
    var body: some View {
        Group {
            if token == nil {
                VStack(alignment: .leading) {
                    Text("Migrate legacy data")
                    Text("Please, log in to iCloud Account").modifier(SecondaryLabelModifier())
                }
            }
            else {
                NavigationLink("Migrate legacy data", destination: Migration())
            }
        }.onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSUbiquityIdentityDidChange)) { (_) in
            self.token = FileManager.default.ubiquityIdentityToken
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
