//
//  CertificateTreeScrollView.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CertificateTreeScrollView.h"

@implementation CertificateTreeScrollView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// center the image as it becomes smaller than the size of the screen
	UIView* contentView = [self.subviews objectAtIndex:0];
	if (contentView) {
		CGSize boundsSize = self.bounds.size;
		CGRect frameToCenter = contentView.frame;
		
		// center horizontally
		if (frameToCenter.size.width < boundsSize.width)
			frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
		else
			frameToCenter.origin.x = 0;
		
		// center vertically
		if (frameToCenter.size.height < boundsSize.height)
			frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
		else
			frameToCenter.origin.y = 0;
		
		contentView.frame = frameToCenter;
		contentView.contentScaleFactor = 1.0;
	}
}

@end
