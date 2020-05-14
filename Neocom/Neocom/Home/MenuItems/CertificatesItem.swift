//
//  CertificatesItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct CertificatesItem: View {
    var body: some View {
        NavigationLink(destination: CertificateGroups()) {
            Icon(Image("certificates"))
            Text("Certificates")
        }
    }
}

struct CertificatesItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                CertificatesItem()
            }.listStyle(GroupedListStyle())
        }
    }
}
