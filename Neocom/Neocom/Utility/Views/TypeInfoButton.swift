//
//  TypeInfoButton.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct TypeInfoButton: View {
    var type: SDEInvType
    @State private var isTypeInfoPresented = false
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    var body: some View {
        InfoButton {
            self.isTypeInfoPresented = true
        }.sheet(isPresented: $isTypeInfoPresented) {
            NavigationView {
                TypeInfo(type: self.type).navigationBarItems(leading: BarButtonItems.close {self.isTypeInfoPresented = false})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct TypeInfoButton_Previews: PreviewProvider {
    static var previews: some View {
        TypeInfoButton(type: SDEInvType.dominix)
            .modifier(ServicesViewModifier.testModifier())
    }
}
