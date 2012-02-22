//
//  CertificateRelationshipViewDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CertificateRelationshipView;
@protocol CertificateRelationshipViewDelegate <NSObject>

- (void) certificateRelationshipViewDidTap:(CertificateRelationshipView*) certificateRelationshipView;

@end
