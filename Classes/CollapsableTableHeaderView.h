//
//  CollapsableTableHeaderView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 05.11.12.
//
//

#import <UIKit/UIKit.h>

@interface CollapsableTableHeaderView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *collapsImageView;
@property (nonatomic, assign) BOOL collapsed;

@end
