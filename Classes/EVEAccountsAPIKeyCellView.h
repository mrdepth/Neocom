//
//  EVEAccountsAPIKeyCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EVEAccountsAPIKeyCellView : UITableViewCell {
	UILabel *accessMaskLabel;
	UILabel *keyIDLabel;
	UILabel *keyTypeLabel;
	UILabel *expiredLabel;
	UILabel *errorLabel;
	UIImageView *topSeparator;
}
@property (nonatomic, retain) IBOutlet UILabel *accessMaskLabel;
@property (nonatomic, retain) IBOutlet UILabel *keyIDLabel;
@property (nonatomic, retain) IBOutlet UILabel *keyTypeLabel;
@property (nonatomic, retain) IBOutlet UILabel *expiredLabel;
@property (nonatomic, retain) IBOutlet UILabel *errorLabel;
@property (nonatomic, retain) IBOutlet UIImageView *topSeparator;

@end
