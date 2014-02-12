//
//  NCFittingBattleClinicSearchResultsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCFittingBattleClinicSearchResultsViewController : NCTableViewController
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) NSArray* tags;

@end
