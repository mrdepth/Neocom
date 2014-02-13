//
//  EVEAssetListItem+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEAssetListItem+Neocom.h"
#import <objc/runtime.h>

@implementation EVEAssetListItem (Neocom)

- (EVEDBInvType*) type {
	EVEDBInvType* type = objc_getAssociatedObject(self, @"type");
	return type;
}

- (void) setType:(EVEDBInvType *)type {
	objc_setAssociatedObject(self, @"type", type, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EVELocationsItem*) location {
	EVELocationsItem* location = objc_getAssociatedObject(self, @"location");
	return location;
}

- (void) setLocation:(EVELocationsItem *)location {
	objc_setAssociatedObject(self, @"location", location, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) title {
	NSString* title = objc_getAssociatedObject(self, @"title");
	return title;
}

- (void) setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @"title", title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
