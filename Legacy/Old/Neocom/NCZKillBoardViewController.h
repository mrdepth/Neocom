//
//  NCZKillBoardViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 26.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCZKillBoardViewController : NCTableViewController
- (IBAction)onChangeDate:(UIDatePicker*)sender;
- (IBAction)onChangeFilter:(UISegmentedControl*)sender;
- (IBAction)onChangeWHKills:(UISwitch*)sender;
- (IBAction)onChangeSoloKills:(UISwitch*)sender;
@end
