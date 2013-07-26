//
//  GroupedCell.h
//  EVEUniverse
//
//  Created by mr_depth on 20.07.13.
//
//

#import <UIKit/UIKit.h>

typedef enum {
	GroupedCellGroupStyleMiddle = 0,
	GroupedCellGroupStyleTop = 0x1,
	GroupedCellGroupStyleBottom = 0x2,
	GroupedCellGroupStyleSingle = GroupedCellGroupStyleTop | GroupedCellGroupStyleBottom
} GroupedCellGroupStyle;

@interface GroupedCell : UITableViewCell
@property (nonatomic, assign) GroupedCellGroupStyle groupStyle;

@end
