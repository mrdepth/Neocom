//
//  EVEAssetListItem+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEAssetListItem+Neocom.h"
#import <objc/runtime.h>
#import "NSNumberFormatter+Neocom.h"

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
	if (title)
		return title;
	
	if (!title)
		title = self.type.typeName;
	if (!title)
		title = NSLocalizedString(@"Unknown", nil);

	if (self.quantity > 1)
		title = [NSString stringWithFormat:@"%@ (x%@)", title, [NSNumberFormatter neocomLocalizedStringFromInteger:self.quantity]];
	else if (self.contents.count == 1)
		title = [NSString stringWithFormat:NSLocalizedString(@"%@ (1 item)", nil), title];
	else if (self.contents.count > 1)
		title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ items)", nil), title, [NSNumberFormatter neocomLocalizedStringFromInteger:self.contents.count]];
	else {
		if (!title)
			title = @"";
	}
	self.title = title;
	return title;
}

- (void) setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @"title", title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*) owner {
	return objc_getAssociatedObject(self, @"owner");
}

- (void) setOwner:(NSString *)owner {
	objc_setAssociatedObject(self, @"owner", owner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
