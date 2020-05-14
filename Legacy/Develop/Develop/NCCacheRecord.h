//
//  NCCacheRecord.h
//  Develop
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCCacheRecordData;

NS_ASSUME_NONNULL_BEGIN

@interface NCCacheRecord<__covariant ObjectType> : NSManagedObject
@property (readonly, getter=isExpired) BOOL expired;
+ (NSFetchRequest<NCCacheRecord *> *)fetchRequestForKey:(NSString*) key account:(NSString*) account;
- (ObjectType) object;

@end

NS_ASSUME_NONNULL_END

