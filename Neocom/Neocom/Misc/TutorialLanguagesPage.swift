//
//  TutorialLanguagesPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 5/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TutorialLanguagesPage: View {
    var completion: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            LanguagePacks()
            NavigationLink(destination: TutorialAccountPage(completion: completion)) {
                Text("Continue")//.modifier(TutorialButtonModifier())
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 50)
            .padding(.top)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
        
    }
}

struct TutorialLanguagesPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TutorialLanguagesPage {}
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
