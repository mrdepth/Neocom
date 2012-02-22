//
//  SkillLevelsViewControllerDelegate.h
//  EVEUniverse
//
//  Created by mr_depth on 28.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SkillLevelsViewController;
@protocol SkillLevelsViewControllerDelegate <NSObject>
- (void) skillLevelsViewController:(SkillLevelsViewController*) controller didSelectLevel:(NSInteger) level;
@end
