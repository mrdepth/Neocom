//
//  EVEPlanetaryPinsItem+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 25.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "EVEPlanetaryPinsItem+Neocom.h"
#import <objc/runtime.h>
#import "NCDatabase.h"

@implementation EVEPlanetaryPinsItem (Neocom)

- (NCDBInvType*) type {
	NCDBInvType* type = objc_getAssociatedObject(self, @"type");
	if (!type) {
		type = [NCDBInvType invTypeWithTypeID:self.typeID];
		if (!type)
			self.type = type = (id) [NSNull null];
	}
	return type == (id) [NSNull null] ? nil : type;
}

- (void) setType:(NCDBInvType *)type {
	return objc_setAssociatedObject(self, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NCDBInvType*) contentType {
	NCDBInvType* contentType = objc_getAssociatedObject(self, @"contentType");
	if (!contentType) {
		contentType = [NCDBInvType invTypeWithTypeID:self.contentTypeID];
		if (!contentType)
			self.contentType = contentType = (id) [NSNull null];
	}
	return contentType == (id) [NSNull null] ? nil : contentType;
}

- (void) setContentType:(NCDBInvType *)contentType {
	return objc_setAssociatedObject(self, @"contentType", contentType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
