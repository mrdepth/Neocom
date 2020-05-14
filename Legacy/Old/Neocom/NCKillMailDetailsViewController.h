//
//  NCKillMailDetailsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 24.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCKillMail.h"

@interface NCKillMailDetailsViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *shipLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *damageTakenLabel;

@property (nonatomic, strong) NCKillMail* killMail;

- (IBAction)onChangeMode:(id)sender;

@end
