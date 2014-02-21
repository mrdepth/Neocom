//
//  NCStarbasesDetailsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 21.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCStarbasesDetailsViewController : NCTableViewController
@property (nonatomic, strong) EVEStarbaseListItem* starbase;
@property (nonatomic, strong) NSDate* currentDate;
@end
