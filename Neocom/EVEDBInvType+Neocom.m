//
//  EVEDBInvType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEDBInvType+Neocom.h"

@implementation EVEDBInvType (Neocom)

- (NSInteger) skillPointsAtLevel:(NSInteger) level {
	if (level == 0)
		return 0;
	EVEDBDgmTypeAttribute* rank = self.attributesDictionary[@(275)];
	if (rank) {
		float sp = pow(2.0, 2.5 * level - 2.5) * 250.0 * rank.value;
		return sp;
	}
	else
		return 0;
}

@end
