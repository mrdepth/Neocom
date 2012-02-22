//
//  SkillPlannerImportViewControllerDelegate.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SkillPlannerImportViewController;
@class SkillPlan;
@protocol SkillPlannerImportViewControllerDelegate <NSObject>
- (void) skillPlannerImportViewController:(SkillPlannerImportViewController*) controller didSelectSkillPlan:(SkillPlan*) skillPlan;
@end
