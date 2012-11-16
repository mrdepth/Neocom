//
//  CollapsableTableHeaderView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 05.11.12.
//
//

#import <UIKit/UIKit.h>

@interface CollapsableTableHeaderView : UIView
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UIImageView *collapsImageView;
@property (nonatomic, assign) BOOL collapsed;

@end
