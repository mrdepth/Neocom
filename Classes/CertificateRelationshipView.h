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

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIImageView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) UIColor* color;
@property (strong, nonatomic) EVEDBCrtCertificate* certificate;
@property (strong, nonatomic) EVEDBInvTypeRequiredSkill* type;
@property (weak, nonatomic) id<CertificateRelationshipViewDelegate> delegate;

@end
