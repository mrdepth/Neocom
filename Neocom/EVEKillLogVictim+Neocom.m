//
//  EVEKillLogVictim+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEKillLogVictim+Neocom.h"
#import <objc/runtime.h>

@implementation EVEKillLogVictim (Neocom)

- (NCDBInvType*) shipType {
	return objc_getAssociatedObject(self, @"shipType");
}

- (void) setShipType:(NCDBInvType *)shipType {
	objc_setAssociatedObject(self, @"shipType", shipType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
