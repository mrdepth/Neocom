//
//  CharacterEqualSkills.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Character.h"

@interface CharacterEqualSkills : NSObject<Character>
+ (id) characterWithSkillsLevel:(NSInteger) level;
- (id) initWithSkillsLevel:(NSInteger) level;
@end
