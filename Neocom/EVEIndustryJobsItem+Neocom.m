//
//  EVEIndustryJobsItem+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEIndustryJobsItem+Neocom.h"
#import <objc/runtime.h>
#import "NSString+Neocom.h"
#import "NSDate+DaysAgo.h"

@implementation EVEIndustryJobsItem (Neocom)

- (NCLocationsManagerItem*) blueprintLocation {
	return objc_getAssociatedObject(self, @"blueprintLocation");
}

- (NCLocationsManagerItem*) outputLocation {
	return objc_getAssociatedObject(self, @"outputLocation");
}

/*- (NSString*) installerName {
	return objc_getAssociatedObject(self, @"installerName");
}*/

/*- (NCDBRamActivity*) activity {
	return objc_getAssociatedObject(self, @"activity");
}

- (NCDBInvType*) blueprintType {
	return objc_getAssociatedObject(self, @"blueprintType");
}

- (NCDBInvType*) productType {
	return objc_getAssociatedObject(self, @"productType");
}*/

- (void) setBlueprintLocation:(NCLocationsManagerItem *)blueprintLocation {
	return objc_setAssociatedObject(self, @"blueprintLocation", blueprintLocation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setOutputLocation:(NCLocationsManagerItem *)outputLocation {
	return objc_setAssociatedObject(self, @"outputLocation", outputLocation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*- (void) setInstallerName:(NSString *)installerName {
	return objc_setAssociatedObject(self, @"installerName", installerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}*/

/*- (void) setActivity:(NCDBRamActivity *)activity {
	return objc_setAssociatedObject(self, @"activity", activity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setBlueprintType:(NCDBInvType *)blueprintType {
	return objc_setAssociatedObject(self, @"blueprintType", blueprintType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setProductType:(NCDBInvType *)productType {
	return objc_setAssociatedObject(self, @"productType", productType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}*/

- (NSString*) localizedStateWithCurrentDate:(NSDate*) date {
	switch (self.status) {
		case EVEIndustryJobStatusActive: {
			NSTimeInterval remainsTime = [self.endDate timeIntervalSinceDate:date];
			if (remainsTime < 0)
				remainsTime = 0;
			NSTimeInterval productionTime = [self.endDate timeIntervalSinceDate:self.startDate];
			NSTimeInterval progressTime = [date timeIntervalSinceDate:self.startDate];
			
			float progress = (progressTime / productionTime);
			if (progress >= 1.0)
				return NSLocalizedString(@"Completion (100%)", nil);
			else {
				NSString* remains = [NSString stringWithFormat:@"%@ (%d%%)", [NSString stringWithTimeLeft:remainsTime], (int) (progress * 100)];
				return [NSString stringWithFormat:NSLocalizedString(@"In Progress: %@", nil), remains];
			}
		}
		case EVEIndustryJobStatusPaused:
			return NSLocalizedString(@"Paused", nil);
		case EVEIndustryJobStatusReady:
			return NSLocalizedString(@"Ready", nil);
		case EVEIndustryJobStatusDelivered:
			return NSLocalizedString(@"Delivered", nil);
		case EVEIndustryJobStatusCancelled:
			return NSLocalizedString(@"Cancelled", nil);
		case EVEIndustryJobStatusReverted:
			return NSLocalizedString(@"Reverted", nil);
		default:
			return NSLocalizedString(@"Unknown State", nil);
			break;
	}
}

@end
