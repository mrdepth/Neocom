//
//  NAPISearchTitleCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import "NAPISearchTitleCellView.h"

@implementation NAPISearchTitleCellView



- (IBAction)onClear:(id)sender {
	[self.delegate searchTitleCellViewDidClear:self];
}

@end
