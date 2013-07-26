//
//  EUTextField.m
//  EVEUniverse
//
//  Created by mr_depth on 22.07.13.
//
//

#import "EUTextField.h"

@implementation EUTextField

- (void) awakeFromNib {
	self.background = [[UIImage imageNamed:@"textFieldBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 17, 0, 17)];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect) textRectForBounds:(CGRect)bounds {
	return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, 15, 0, 25));
}

- (CGRect) editingRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}


@end
