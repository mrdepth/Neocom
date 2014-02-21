//
//  EVEStarbaseListItem+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEStarbaseListItem+Neocom.h"
#import <objc/runtime.h>

@implementation EVEStarbaseListItem (Neocom)

- (EVEStarbaseDetail*) details {
	return objc_getAssociatedObject(self, @"details");
}

- (void) setDetails:(EVEStarbaseDetail *)details {
	objc_setAssociatedObject(self, @"details", details, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (float) resourceConsumptionBonus {
	return [objc_getAssociatedObject(self, @"resourceConsumptionBonus") floatValue];
}

- (void) setResourceConsumptionBonus:(float)resourceConsumptionBonus {
	objc_setAssociatedObject(self, @"resourceConsumptionBonus", @(resourceConsumptionBonus), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVEDBMapSolarSystem*) solarSystem {	
	return objc_getAssociatedObject(self, @"solarSystem");
}

- (void) setSolarSystem:(EVEDBMapSolarSystem *)solarSystem {
	objc_setAssociatedObject(self, @"solarSystem", solarSystem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVEDBMapDenormalize*) moon {
	return objc_getAssociatedObject(self, @"moon");
}

- (void) setMoon:(EVEDBMapDenormalize *)moon {
	objc_setAssociatedObject(self, @"moon", moon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVEDBInvType*) type {
	return objc_getAssociatedObject(self, @"type");
}

- (void) setType:(EVEDBInvType *)type {
	objc_setAssociatedObject(self, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) title {
	return objc_getAssociatedObject(self, @"title");
}

- (void) setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @"title", title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
