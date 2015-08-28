//
//  NSManagedObjectContext+NCCache.h
//  Neocom
//
//  Created by Артем Шиманский on 28.08.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NCCacheRecord;
@interface NSManagedObjectContext (NCCache)

- (NCCacheRecord*) cacheRecordWithRecordID:(NSString*) recordID;

@end
