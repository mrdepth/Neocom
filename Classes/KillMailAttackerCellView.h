//
//  KillMailAttackerCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillMailAttackerCellView : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shipImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weaponImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *damageDoneLabel;

@end
