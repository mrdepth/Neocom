//
//  NCAccountCorporationCell.h
//  Neocom
//
//  Created by Артем Шиманский on 10.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCAccountCorporationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *apiKeyButton;
@property (weak, nonatomic) IBOutlet UILabel *ceoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *membersLabel;
@end
