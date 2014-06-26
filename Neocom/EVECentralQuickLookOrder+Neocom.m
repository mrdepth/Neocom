//
//  EVECentralQuickLookOrder+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 19.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVECentralQuickLookOrder+Neocom.h"
#import "NCDatabase.h"
#import <objc/runtime.h>

@implementation EVECentralQuickLookOrder (Neocom)

- (NCDBMapRegion*) region {
	if (self.regionID == 0)
		return nil;
	NCDBMapRegion* region = objc_getAssociatedObject(self, @"region");
	if (!region) {
		region = [NCDBMapRegion mapRegionWithRegionID:self.regionID];
		if (!region)
			region = (NCDBMapRegion*) [NSNull null];
		self.region = region;
	}
	if ((NSNull*) region == [NSNull null])
		return nil;
	else
		return region;
}

- (void) setRegion:(NCDBMapRegion *)region {
	objc_setAssociatedObject(self, @"region", region, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NCDBStaStation*) station {
	if (self.stationID == 0)
		return nil;
	NCDBStaStation* station = objc_getAssociatedObject(self, @"station");
	if (!station) {
		station = [NCDBStaStation staStationWithStationID:self.stationID];
		if (!station)
			station = (NCDBStaStation*) [NSNull null];
		self.station = station;
	}
	if ((NSNull*) station == [NSNull null])
		return nil;
	else
		return station;
}

- (void) setStation:(NCDBStaStation *)station {
	objc_setAssociatedObject(self, @"station", station, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
