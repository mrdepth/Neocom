//
//  NCAccountsCell.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCAccountsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UILabel *corporationLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *spLabel;
@property (weak, nonatomic) IBOutlet UILabel *wealthLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillLabel;
@property (weak, nonatomic) IBOutlet UILabel *trainingTimeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *trainingProgressView;

@end
