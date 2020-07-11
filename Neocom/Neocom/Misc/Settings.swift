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
    @ObservedObject private var colorScheme = UserDefault(wrappedValue: -1, key: .colorScheme)
    
    private func skillQueueNotificationCell(option: NotificationsManager.SkillQueueNotificationOptions, title: String) -> some View {
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
            
            Section(header: Text("APPEARANCE")) {
                Toggle(isOn: Binding(get: {
                    self.colorScheme.wrappedValue <= 0
                }, set: { (newValue) in
                    self.colorScheme.wrappedValue = newValue ? -1 : 2
                })) {
                    Text("Automatic")
                }
                if colorScheme.wrappedValue > 0 {
                    Picker(selection: $colorScheme.wrappedValue, label: Text("Appearance")) {
                        Text("Light Theme").tag(1)
                        Text("Dark Theme").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                }
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
                Toggle(NSLocalizedString("Notifications Enabled", comment: ""), isOn: $notificationsEnabled.wrappedValue)
            }
            
            if notificationsEnabled.wrappedValue {
                Section(header: Text("SKILL QUEUE NOTIFICATIONS")) {
                    
                    skillQueueNotificationCell(option: .inactive, title: NSLocalizedString("Inactive Skill Queue", comment: "Skill queue notifications"))
                    skillQueueNotificationCell(option: .oneHour, title: NSLocalizedString("1 Hour Left", comment: "Skill queue notifications"))
                    skillQueueNotificationCell(option: .fourHours, title: NSLocalizedString("4 Hours Left", comment: "Skill queue notifications"))
                    skillQueueNotificationCell(option: .oneDay, title: NSLocalizedString("24 Hours Left", comment: "Skill queue notifications"))
                    skillQueueNotificationCell(option: .skillTrainingComplete, title: NSLocalizedString("Skill Training Complete", comment: "Skill queue notifications"))
                }
            }
            
            Section(header: Text("CACHE"), footer: Text("Some application features may be temporarily unavailable")) {
                Button(NSLocalizedString("Clear Cache", comment: "")) {
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
            
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Settings"))
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
                NavigationLink(NSLocalizedString("Migrate legacy data", comment: ""), destination: Migration())
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
