//
//  NibTableViewCell.m
//
//
//  Created by Shimanski on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NibTableViewCell.h"


@implementation UITableViewCell(NibTableViewCell)

+ (id) cellWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle reuseIdentifier:(NSString *)reuseIdentifier {
	if (!nibBundle)
		nibBundle = [NSBundle mainBundle];
	NSArray *objects = [nibBundle loadNibNamed:nibName owner:nil options:nil];
	for (NSObject *object in objects) {
		if ([object isKindOfClass:[self class]]) {
			UITableViewCell *cell = (UITableViewCell *) object;
			if ([[cell reuseIdentifier] isEqualToString:reuseIdentifier])
				return cell;
		}
	}
	return nil;
}
@end
