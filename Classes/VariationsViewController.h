//
//  VariationsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 11.02.13.
//
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface VariationsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) EVEDBInvType* type;

- (void) didSelectType:(EVEDBInvType*) type;

@end
