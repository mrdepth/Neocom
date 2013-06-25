//
//  CertificateRelationshipView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CertificateRelationshipViewDelegate.h"

@class EVEDBCrtCertificate;
@class EVEDBInvTypeRequiredSkill;
@interface CertificateRelationshipView : UIView

@property (retain, nonatomic) IBOutlet UIImageView *iconView;
@property (retain, nonatomic) IBOutlet UIImageView *statusView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) UIColor* color;
@property (retain, nonatomic) EVEDBCrtCertificate* certificate;
@property (retain, nonatomic) EVEDBInvTypeRequiredSkill* type;
@property (assign, nonatomic) id<CertificateRelationshipViewDelegate> delegate;

@end
