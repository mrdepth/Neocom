//
//  KillMailAttackerCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import "GroupedCell.h"

@interface KillMailAttackerCellView : GroupedCell
@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shipImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weaponImageView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corporationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *damageDoneLabel;

@end
