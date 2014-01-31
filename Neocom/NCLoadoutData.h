//
//  NCLoadoutData.h
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class NCLoadout;
@interface NCLoadoutData : NSManagedObject

@property (nonatomic, retain) id data;
@property (nonatomic, retain) NCLoadout *loadout;

@end
