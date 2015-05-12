//
//  NCDBWhType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 17.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDBWhType+Neocom.h"

@implementation NCDBWhType (Neocom)

- (NSString*) targetSystemClassDisplayName {
	int32_t target = self.targetSystemClass;
	if (target == 0)
		return [NSString stringWithFormat:NSLocalizedString(@"Exit WH", nil)];
	if (target >= 1 && target <= 6)
		return [NSString stringWithFormat:NSLocalizedString(@"W-Space Class %d", nil), target];
	else if (target == 7)
		return NSLocalizedString(@"High-sec", nil);
	else if (target == 8)
		return NSLocalizedString(@"Low-sec", nil);
	else if (target == 9)
		return NSLocalizedString(@"0.0 system", nil);
	else if (target == 12)
		return NSLocalizedString(@"Thera", nil);
	else if (target == 13)
		return NSLocalizedString(@"W-Frig", nil);
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Unknown Class %d", nil), target];
}

@end
