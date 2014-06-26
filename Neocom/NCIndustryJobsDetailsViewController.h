//
//  NCIndustryJobsDetailsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 20.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCIndustryJobsDetailsViewController : NCTableViewController
@property (nonatomic, strong) EVEIndustryJobsItem* job;
@property (nonatomic, strong) NSDate* currentDate;

@end
