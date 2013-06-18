//
//  MessageCellView.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCellView : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel* subjectLabel;
@property (nonatomic, retain) IBOutlet UILabel* fromLabel;
@property (nonatomic, retain) IBOutlet UILabel* dateLabel;

@end
