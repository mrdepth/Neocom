//
//  NCFittingShipAffectingSkillsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 10.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCFitCharacter.h"

@interface NCFittingShipAffectingSkillsViewController : NCTableViewController
@property (assign, nonatomic) BOOL modified;
@property (strong, nonatomic) NCFitCharacter* character;
@property (strong, nonatomic) NSArray* affectingSkillsTypeIDs;
@end
