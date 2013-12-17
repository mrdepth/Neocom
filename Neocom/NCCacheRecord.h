//
//  NCCacheRecord.h
//  Neocom
//
//  Created by Artem Shimanski on 12.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCCacheRecord : NSManagedObject
@property (nonatomic, retain) NSString * recordID;
@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * expireDate;
@property (nonatomic, retain) NSManagedObject *section;

+ (instancetype) cacheRecordWithRecordID:(NSString*) recordID;

@end
