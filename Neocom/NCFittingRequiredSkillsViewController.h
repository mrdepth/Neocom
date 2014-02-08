//
//  NCFittingRequiredSkillsViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 08.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCTrainingQueue.h"

@interface NCFittingRequiredSkillsViewController : UITableViewController
@property (strong, nonatomic) NCTrainingQueue* trainingQueue;

- (IBAction)onTrain:(id)sender;
@end
