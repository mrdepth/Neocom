//
//  NCDBVersion.h
//  Neocom
//
//  Created by Артем Шиманский on 22.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCDBVersion : NSManagedObject

@property (nonatomic) int32_t build;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSString * expansion;

@end
