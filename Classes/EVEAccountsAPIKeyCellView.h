//
//  EVEAccountsAPIKeyCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EVEAccountsAPIKeyCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *accessMaskLabel;
@property (nonatomic, weak) IBOutlet UILabel *keyIDLabel;
@property (nonatomic, weak) IBOutlet UILabel *keyTypeLabel;
@property (nonatomic, weak) IBOutlet UILabel *expiredLabel;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@property (nonatomic, weak) IBOutlet UIImageView *topSeparator;

@end
