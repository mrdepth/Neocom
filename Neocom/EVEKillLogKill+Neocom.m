//
//  EVEKillLogKill+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEKillLogKill+Neocom.h"
#import <objc/runtime.h>

@implementation EVEKillLogKill (Neocom)

- (NCDBMapSolarSystem*) solarSystem {
	return objc_getAssociatedObject(self, @"solarSystem");
}

- (void) setSolarSystem:(NCDBMapSolarSystem *)solarSystem {
	objc_setAssociatedObject(self, @"solarSystem", solarSystem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
