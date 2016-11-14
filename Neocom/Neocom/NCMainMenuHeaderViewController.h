//
//  NCMainMenuHeaderViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCMainMenuHeaderViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *characterImageView;
@property (weak, nonatomic) IBOutlet UILabel *corporationLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *corporationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *allianceImageView;

@end
