//
//  NCCacheRecordData.h
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCCacheRecord;

@interface NCCacheRecordData : NSManagedObject

@property (nonatomic, retain) id data;
@property (nonatomic, retain) NCCacheRecord *record;

@end
