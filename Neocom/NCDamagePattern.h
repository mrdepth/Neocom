//
//  NCDamagePattern.h
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCDamagePattern : NSManagedObject

@property (nonatomic) float em;
@property (nonatomic) float thermal;
@property (nonatomic) float kinetic;
@property (nonatomic) float explosive;
@property (nonatomic, retain) NSString * name;

@end
