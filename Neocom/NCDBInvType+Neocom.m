//
//  NCDBInvType+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 11.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+Neocom.h"
#import "NCDBInvMetaGroup.h"
#import "NCDatabase.h"
#import <objc/runtime.h>

@implementation NCDBInvType (Neocom)

+ (instancetype) invTypeWithTypeID:(int32_t) typeID {
	NCDatabase* database = [NCDatabase sharedDatabase];
	NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
	request.predicate = [NSPredicate predicateWithFormat:@"typeID == %d", typeID];
	request.fetchLimit = 1;
	__block NSArray* result;
	if ([NSThread isMainThread])
		result = [database.managedObjectContext executeFetchRequest:request error:nil];
	else
		[database.backgroundManagedObjectContext performBlockAndWait:^{
			result = [database.backgroundManagedObjectContext executeFetchRequest:request error:nil];
		}];
	return result.count > 0 ? result[0] : nil;
}

- (NSString*) metaGroupName {
	return self.metaGroup.metaGroupName;
}

- (NSDictionary*) attributesDictionary {
	NSDictionary* attributesDictionary = objc_getAssociatedObject(self, @"attributesDictionary");
	if (!attributesDictionary) {
		NSMutableDictionary* dic = [NSMutableDictionary new];
		for (NCDBDgmTypeAttribute* attribute in self.attributes)
			dic[@(attribute.attributeType.attributeID)] = attribute;
		attributesDictionary = dic;
		objc_setAssociatedObject(self, @"attributesDictionary", attributesDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return attributesDictionary;
}

- (NSDictionary*) effectsDictionary {
	NSDictionary* effectsDictionary = objc_getAssociatedObject(self, @"effectsDictionary");
	if (!effectsDictionary) {
		NSMutableDictionary* dic = [NSMutableDictionary new];
		for (NCDBDgmEffect* effect in self.effects)
			dic[@(effect.effectID)] = effect;
		effectsDictionary = dic;
		objc_setAssociatedObject(self, @"effectsDictionary", effectsDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return effectsDictionary;
}




@end
