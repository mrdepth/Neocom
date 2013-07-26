//
//  EVEAPIKeyCell.m
//  EVEUniverse
//
//  Created by mr_depth on 21.07.13.
//
//

#import "EVEAPIKeyCell.h"

@implementation EVEAPIKeyCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)onDelete:(id)sender {
	[self.delegate apiKeyCell:self deleteButtonTapped:sender];
}

@end
