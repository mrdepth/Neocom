//
//  NCFitCharacter.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCStorage.h"

@class NCFitCharacter;
@class NCAccount;

@interface NCFitCharacter : NSManagedObject

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSDictionary* skills;
@property (nonatomic, strong) NSArray* implants;


@end
