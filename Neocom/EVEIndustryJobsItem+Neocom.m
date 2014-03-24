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

- (NCLocationsManagerItem*) installedItemLocation {
	return objc_getAssociatedObject(self, @"installedItemLocation");
}

- (NCLocationsManagerItem*) outputLocation {
	return objc_getAssociatedObject(self, @"outputLocation");
}

- (NSString*) installerName {
	return objc_getAssociatedObject(self, @"installerName");
}

- (EVEDBRamActivity*) activity {
	return objc_getAssociatedObject(self, @"activity");
}

- (EVEDBInvType*) installedItemType {
	return objc_getAssociatedObject(self, @"installedItemType");
}

- (EVEDBInvType*) outputType {
	return objc_getAssociatedObject(self, @"outputType");
}

- (void) setInstalledItemLocation:(NCLocationsManagerItem *)installedItemLocation {
	return objc_setAssociatedObject(self, @"installedItemLocation", installedItemLocation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setOutputLocation:(NCLocationsManagerItem *)outputLocation {
	return objc_setAssociatedObject(self, @"outputLocation", outputLocation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setInstallerName:(NSString *)installerName {
	return objc_setAssociatedObject(self, @"installerName", installerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setActivity:(EVEDBRamActivity *)activity {
	return objc_setAssociatedObject(self, @"activity", activity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setInstalledItemType:(EVEDBInvType *)installedItemType {
	return objc_setAssociatedObject(self, @"installedItemType", installedItemType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setOutputType:(EVEDBInvType *)outputType {
	return objc_setAssociatedObject(self, @"outputType", outputType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) localizedStateWithCurrentDate:(NSDate*) date {
	if (!self.completed) {
		NSTimeInterval remainsTime = [self.endProductionTime timeIntervalSinceDate:date];
		if (remainsTime < 0)
			remainsTime = 0;
		NSTimeInterval productionTime = [self.endProductionTime timeIntervalSinceDate:self.beginProductionTime];
		NSTimeInterval progressTime = [date timeIntervalSinceDate:self.beginProductionTime];
		
		float progress = (progressTime / productionTime);
		if (progress >= 1.0)
			return NSLocalizedString(@"Completion (100%)", nil);
		else {
			NSString* remains = [NSString stringWithFormat:@"%@ (%d%%)", [NSString stringWithTimeLeft:remainsTime], (int) (progress * 100)];
			return [NSString stringWithFormat:NSLocalizedString(@"In Progress: %@", nil), remains];
		}
	}
	else {
		if (self.completedStatus == 0) {
			return [NSString stringWithFormat:NSLocalizedString(@"Failed: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else if (self.completedStatus == 1) {
			return [NSString stringWithFormat:NSLocalizedString(@"Delivered: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else if (self.completedStatus == 2) {
			return [NSString stringWithFormat:NSLocalizedString(@"Aborted: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else if (self.completedStatus == 3) {
			return [NSString stringWithFormat:NSLocalizedString(@"GM aborted: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else if (self.completedStatus == 4) {
			return [NSString stringWithFormat:NSLocalizedString(@"Inflight unanchored: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else if (self.completedStatus == 5) {
			return [NSString stringWithFormat:NSLocalizedString(@"Destroyed: %@", nil), [self.endProductionTime daysAgoStringWithTime:YES]];
		}
		else {
			return NSLocalizedString(@"Unknown Status", nil);
		}
	}
}

@end
