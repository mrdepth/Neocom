//
//  KillMailAttackerCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import <UIKit/UIKit.h>

@interface KillMailAttackerCellView : UITableViewCell
@property (retain, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (retain, nonatomic) IBOutlet UIImageView *shipImageView;
@property (retain, nonatomic) IBOutlet UIImageView *weaponImageView;
@property (retain, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *damageDoneLabel;

@end
