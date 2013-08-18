//
//  KillNetFilterTextCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillNetFilterTextCellView.h"

@implementation KillNetFilterTextCellView

- (void) awakeFromNib {
	self.textField.captionLabel.textColor = [UIColor whiteColor];
	self.textField.captionLabel.font = [UIFont boldSystemFontOfSize:12];
}

- (IBAction)onDefaultValue:(id)sender {
	[self.delegate killNetFilterTextCellViewDidPressDefaultButton:self];
}

@end
