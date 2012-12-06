//
//  KillboardCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillboardCellView : UITableViewCell
@property (retain, nonatomic) IBOutlet UIImageView *shipImageView;
@property (retain, nonatomic) IBOutlet UILabel *shipLabel;
@property (retain, nonatomic) IBOutlet UILabel *systemNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *piratesLabel;
@property (retain, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *corporationNameLabel;

@end
