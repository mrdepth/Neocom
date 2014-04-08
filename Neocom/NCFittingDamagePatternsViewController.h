//
//  NCFittingDamagePatternsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCDamagePattern.h"

@interface NCFittingDamagePatternsViewController : NCTableViewController
@property (nonatomic, strong) NCDamagePattern* selectedDamagePattern;
@end
