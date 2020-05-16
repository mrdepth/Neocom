//
//  LanguagePacks.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct LanguagePack {
    var name: String
    var localizedName: Text
    
    static let packs = [
        "SDE_en": LanguagePack(name: "English", localizedName: Text("English")),
        "SDE_de": LanguagePack(name: "German", localizedName: Text("German")),
        "SDE_es": LanguagePack(name: "Spanish", localizedName: Text("Spanish")),
        "SDE_fr": LanguagePack(name: "French", localizedName: Text("French")),
        "SDE_it": LanguagePack(name: "Italian", localizedName: Text("Italian")),
        "SDE_ja": LanguagePack(name: "Japanese", localizedName: Text("Japanese")),
        "SDE_ru": LanguagePack(name: "Russian", localizedName: Text("Russian")),
        "SDE_zh": LanguagePack(name: "Chinese", localizedName: Text("Chinese")),
        "SDE_ko": LanguagePack(name: "Korean", localizedName: Text("Korean")),
    ]
}

struct LanguagePacks: View {
//    private static let ids = ["SDE_en", "SDE_de", "SDE_es", "SDE_fr", "SDE_it", "SDE_ja", "SDE_ru", "SDE_zh", "SDE_ko"]
    var onSelect: ((BundleResource) -> Void)? = nil

    private let languagePacks = Storage.sharedStorage.supportedLanguages()
    
    var body: some View {
        List {
            ForEach(languagePacks , id: \.tag) { pack in
                LanguagePackCell(resource: pack, onSelect: self.onSelect)
            }
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Language Pack")
    }
}

struct LanguagePacks_Previews: PreviewProvider {
    static var previews: some View {
        LanguagePacks()
    }
}

