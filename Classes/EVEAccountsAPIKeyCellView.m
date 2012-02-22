//
//  EVEAccountsAPIKeyCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountsAPIKeyCellView.h"


@implementation EVEAccountsAPIKeyCellView
@synthesize accessMaskLabel;
@synthesize keyIDLabel;
@synthesize keyTypeLabel;
@synthesize expiredLabel;
@synthesize errorLabel;
@synthesize topSeparator;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

/*- (void) awakeFromNib {
	self.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cellAccountBackground.png"]] autorelease];
}*/

- (void)dealloc {
	[accessMaskLabel release];
	[keyIDLabel release];
	[keyTypeLabel release];
	[expiredLabel release];
	[errorLabel release];
	[topSeparator release];

    [super dealloc];
}


@end
