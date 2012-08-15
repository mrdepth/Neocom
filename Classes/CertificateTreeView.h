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
@interface CertificateTreeView : UIView<CertificateRelationshipViewDelegate, UIAlertViewDelegate> {
	EVEDBCrtCertificate* certificate;
	NSMutableArray* prerequisites;
	NSMutableArray* derivations;
	CertificateView* certificateView;
	id<CertificateTreeViewDelegate> delegate;
}
@property (retain, nonatomic) EVEDBCrtCertificate* certificate;
@property (retain, nonatomic, readonly) NSMutableArray* prerequisites;
@property (retain, nonatomic, readonly) NSMutableArray* derivations;
@property (retain, nonatomic, readonly) CertificateView* certificateView;
@property (assign, nonatomic) IBOutlet id<CertificateTreeViewDelegate> delegate;

- (IBAction)onAddToTrainingPlan;

@end
