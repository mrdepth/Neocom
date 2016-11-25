//
//  NCDatabaseTypeInfoViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 25.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeInfoViewController.h"
#import "NCDatabase.h"
#import "NCDatabaseTypeInfoHeaderViewController.h"

@interface NCDatabaseTypeInfoViewController ()
@property (nonatomic, strong) NCDatabaseTypeInfoHeaderViewController* headerViewController;

@end

@implementation NCDatabaseTypeInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = self.type.typeName ?: NSLocalizedString(@"Unknown", nil);
	
	NCDatabaseTypeInfoHeaderViewController* header = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypeInfoHeaderViewControllerLarge"];
	self.headerViewController = header;
	header.type = self.type;
	CGRect frame = CGRectZero;
	frame.size = [header.view systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
	header.view.frame = frame;
	self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:frame];
	[self.tableView addSubview:header.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	dispatch_async(dispatch_get_main_queue(), ^{
		CGRect frame = CGRectZero;
		UIView* header = self.headerViewController.view;
		header.frame = CGRectMake(0, 0, size.width, size.height);
		//self.tableView.tableHeaderView = nil;
		frame.size = [header systemLayoutSizeFittingSize:CGSizeMake(size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
		header.frame = frame;
		self.tableView.tableHeaderView.frame = frame;
		self.tableView.tableHeaderView = self.tableView.tableHeaderView;
	});
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
