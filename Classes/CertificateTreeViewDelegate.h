//
//  CertificateTreeViewDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CertificateTreeView;
@class EVEDBCrtCertificate;
@class EVEDBInvType;
@protocol CertificateTreeViewDelegate <NSObject>

- (void) certificateTreeViewDidFinishLoad:(CertificateTreeView*) certificateTreeView;
- (void) certificateTreeView:(CertificateTreeView*) certificateTreeView didSelectCertificate:(EVEDBCrtCertificate*) certificate;
- (void) certificateTreeView:(CertificateTreeView*) certificateTreeView didSelectType:(EVEDBInvType*) type;

@end
