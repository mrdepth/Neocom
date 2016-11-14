//
//  NCTintImageView.m
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTintImageView.h"

@implementation NCTintImageView

- (void) awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES;
	//Storyboards fix template image
	UIColor* tintColor = self.tintColor;
	self.tintColor = nil;
	self.tintColor = tintColor;
}


#if TARGET_INTERFACE_BUILDER
- (void) prepareForInterfaceBuilder {
	self.layer.masksToBounds = YES;
	//if (self.image.renderingMode == UIImageRenderingModeAlwaysTemplate)
	self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}
#endif

@end
