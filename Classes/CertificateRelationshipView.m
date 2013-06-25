//
//  CertificateRelationshipView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateRelationshipView.h"

@interface CertificateRelationshipView()

- (void) didTap;

@end

@implementation CertificateRelationshipView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	UIImage* mask = [UIImage imageNamed:@"certificateMask.png"];
	UIImage* background = [UIImage imageNamed:@"certificateBackground.png"];
	mask = [mask stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	background = [background stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
	[mask drawInRect:rect];
	mask = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[background drawInRect:rect];
	CGContextClipToMask(context, rect, [mask CGImage]);
	CGContextSetFillColorWithColor(context, [self.color CGColor]);
	CGContextFillRect(context, rect);
	[self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap)]];
}


#pragma mark - Private

- (void) didTap {
	[self.delegate certificateRelationshipViewDidTap:self];
}

@end
