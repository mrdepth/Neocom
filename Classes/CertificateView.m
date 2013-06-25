//
//  CertificateView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateView.h"

@implementation CertificateView

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
	UIImage* mask = [UIImage imageNamed:@"certificateMaskBordered.png"];
	UIImage* background = [UIImage imageNamed:@"certificateBackgroundBordered.png"];
	mask = [mask stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	background = [background stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
	[mask drawInRect:rect];
	mask = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[background drawInRect:rect];
	CGContextClipToMask(context, rect, [mask CGImage]);
	//CGContextSetRGBFillColor(context, 38.0/255.0, 37.0/255.0, 15.0/255.0, 1);
	CGContextSetFillColorWithColor(context, [self.color CGColor]);
	CGContextFillRect(context, rect);
}


- (CGSize) sizeThatFits:(CGSize)size {
	CGRect r = CGRectMake(0, 0, size.width, size.height);
	CGRect r2 = self.descriptionLabel.frame;
	r2.size.width = size.width - r2.origin.x * 2;
	r2.size.height = size.height - r2.origin.y + 10;

	r2 = [self.descriptionLabel textRectForBounds:r2 limitedToNumberOfLines:0];
	r.size.height = r2.size.height + r2.origin.y + 10;
	return r.size;
}


@end
