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
@interface NCStorage(NCFitCharacter)
- (NSArray*) characters;
- (NCFitCharacter*) characterWithAccount:(NCAccount*) account;
- (NCFitCharacter*) characterWithSkillsLevel:(NSInteger) skillsLevel;
@end

@interface NCFitCharacter : NSManagedObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSDictionary* skills;


@end
