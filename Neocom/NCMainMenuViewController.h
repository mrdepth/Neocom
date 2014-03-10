//
//  NCMainMenuViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCMainMenuViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UILabel *serverStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverTimeLabel;

@end
