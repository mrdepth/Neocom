//
//  NCFitCharacter.h
//  Neocom
//
//  Created by Artem Shimanski on 17.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCAccount;
@interface NCFitCharacter : NSManagedObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSDictionary* skills;

+ (NSArray*) characters;
+ (instancetype) characterWithAccount:(NCAccount*) account;
+ (instancetype) characterWithSkillsLevel:(NSInteger) skillsLevel;

@end
