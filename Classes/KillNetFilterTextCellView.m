//
//  KillNetFilterTextCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillNetFilterTextCellView.h"

@implementation KillNetFilterTextCellView

- (IBAction)onDefaultValue:(id)sender {
	[self.delegate killNetFilterTextCellViewDidPressDefaultButton:self];
}

@end
