//
//  CertificateTreeView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CertificateView.h"
#import "CertificateRelationshipView.h"
#import "CertificateTreeViewDelegate.h"

@class EVEDBCrtCertificate;
@interface CertificateTreeView : UIView<CertificateRelationshipViewDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) EVEDBCrtCertificate* certificate;
@property (strong, nonatomic, readonly) NSMutableArray* prerequisites;
@property (strong, nonatomic, readonly) NSMutableArray* derivations;
@property (strong, nonatomic, readonly) CertificateView* certificateView;
@property (weak, nonatomic) IBOutlet id<CertificateTreeViewDelegate> delegate;

- (IBAction)onAddToTrainingPlan;

@end
