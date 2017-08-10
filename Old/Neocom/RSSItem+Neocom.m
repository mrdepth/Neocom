//
//  RSSItem+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 05.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "RSSItem+Neocom.h"
#import <objc/runtime.h>

@implementation RSSItem (Neocom)

- (NSString*) shortDescription {
	return objc_getAssociatedObject(self, @"shortDescription");
}

- (NSString*) plainTitle {
	return objc_getAssociatedObject(self, @"plainTitle");
}

- (NSString*) updatedDateString {
	return objc_getAssociatedObject(self, @"updatedDateString");
}

- (void) setShortDescription:(NSString *)shortDescription {
	objc_setAssociatedObject(self, @"shortDescription", shortDescription, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setPlainTitle:(NSString *)plainTitle {
	objc_setAssociatedObject(self, @"plainTitle", plainTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setUpdatedDateString:(NSString *)updatedDateString {
	objc_setAssociatedObject(self, @"updatedDateString", updatedDateString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
