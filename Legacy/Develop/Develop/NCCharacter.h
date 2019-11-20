//
//  NCCharacter.h
//  Develop
//
//  Created by Artem Shimanski on 21.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCSkill.h"
#import "NCCharacterAttributes.h"
#import "NCTrainingQueue.h"

@class NCAccount;
@interface NCCharacter : NSObject
@property (nonatomic, strong, readonly) NCCharacterAttributes* characterAttributes;
@property (nonatomic, strong, readonly) NSArray<NCSkill*>* skills;
@property (nonatomic, strong, readonly) NCTrainingQueue* skillQueue;

+ (void) createCharacterForAccount:(NCAccount*) account completinHandler:(void (^)(NCCharacter* character, NSError* error)) block;

@end
