//
//  CertificateInfoHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/24/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct CertificateInfoHeader: View {
    var certificate: SDECertCertificate
    var masteryLevel: Int?
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Icon(Image(uiImage: (try? self.managedObjectContext.fetch(SDEEveIcon.named(.mastery(masteryLevel))).first?.image?.image) ?? UIImage()))
                Text(certificate.certificateName ?? "").font(.title)
//                title()
            }//.padding([.horizontal, .top], 15)
            Text(certificate.certificateDescription?.text?.string ?? "").foregroundColor(Color(.descriptionLabel))
        }
    }
}

struct CertificateInfoHeader_Previews: PreviewProvider {
    static var previews: some View {
        let certificate = try! Storage.testStorage.persistentContainer.viewContext
        .from(SDECertCertificate.self)
        .first()!
        return CertificateInfoHeader(certificate: certificate, masteryLevel: nil).padding()
            .modifier(ServicesViewModifier.testModifier())
    }
}
