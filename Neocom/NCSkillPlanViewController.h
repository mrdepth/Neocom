//
//  NCSkillPlanViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 04.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCSkillPlanViewController : NCTableViewController
@property (nonatomic, strong) NSData* xmlData;
@property (nonatomic, strong) NSString* skillPlanName;

- (IBAction)onAction:(id)sender;

@end
