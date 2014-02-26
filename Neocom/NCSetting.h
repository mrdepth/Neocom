//
//  NCSetting.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCSetting : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) id value;

+ (instancetype) settingWithKey:(NSString*) key;

@end
