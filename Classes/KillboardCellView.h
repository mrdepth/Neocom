//
//  KillboardCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillboardCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *shipImageView;
@property (weak, nonatomic) IBOutlet UILabel *shipLabel;
@property (weak, nonatomic) IBOutlet UILabel *systemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *piratesLabel;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;

@end
