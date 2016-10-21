//
//  NCCharacter.h
//  Develop
//
//  Created by Artem Shimanski on 21.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAccount+CoreDataClass.h"

@interface NCCharacter : NSObject

+ (void) createCharacterForAccount:(NCAccount*) account completinHandler:(void (^)(NCCharacter* character, NSError* error)) block;

@end
