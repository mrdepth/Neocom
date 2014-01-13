//
//  NCAccountCharacterCell.h
//  Neocom
//
//  Created by Артем Шиманский on 09.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCAccountCharacterCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipLabel;
@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillsLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentSkillLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillQueueLabel;
@property (weak, nonatomic) IBOutlet UILabel *subscriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *apiKeyButton;

@end
