//
//  TodayViewController.m
//  today
//
//  Created by Артем Шиманский on 28.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "NCTodayCell.h"
#import "NCTodayRow.h"
#import "NSString+Neocom.h"

@interface TodayViewController () <NCWidgetProviding>
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) UIEdgeInsets defaultMarginInsets;
- (void) update;
@end

@implementation TodayViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self update];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encoutered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

	[self update];
    completionHandler(NCUpdateResultNewData);
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
	self.defaultMarginInsets = defaultMarginInsets;
	defaultMarginInsets.left = 0;
	defaultMarginInsets.bottom = 0;
	[self.tableView reloadData];
	return defaultMarginInsets;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count > 0 ? self.rows.count : 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.rows.count > 0) {
		NCTodayCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		NCTodayRow* row = self.rows[indexPath.row];
		cell.nameLabel.text = row.name;
		cell.iconImageView.image = row.image;
		
		NSString *text;
		UIColor *color = nil;
		if (row.skillQueueEndDate) {
			NSTimeInterval timeLeft = [row.skillQueueEndDate timeIntervalSinceNow];
			if (timeLeft > 3600 * 24)
				color = [UIColor greenColor];
			else
				color = [UIColor yellowColor];
			text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), [NSString stringWithTimeLeft:timeLeft]];
		}
		else {
			text = NSLocalizedString(@"Training queue is inactive", nil);
			color = [UIColor redColor];
		}
		cell.skillQueueLabel.text = text;
		cell.skillQueueLabel.textColor = color;
		cell.leftMarginConstraint.constant = self.defaultMarginInsets.left;
		cell.separatorInset = UIEdgeInsetsMake(0, self.defaultMarginInsets.left, 0, cell.separatorInset.right);
		return cell;
	}
	else {
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PlaceholderCell" forIndexPath:indexPath];
		cell.separatorInset = UIEdgeInsetsMake(0, self.defaultMarginInsets.left, 0, cell.separatorInset.right);
		return cell;
	}
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 37;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (self.rows.count > 0) {
		NCTodayRow* row = self.rows[indexPath.row];
		[self.extensionContext openURL:[NSURL URLWithString:[NSString stringWithFormat:@"ncaccount:%@", row.uuid]] completionHandler:nil];
	}
	else
		[self.extensionContext openURL:[NSURL URLWithString:@"ncaccount:"] completionHandler:nil];
}

#pragma mark - Private

- (void) update {
	NSURL* url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.shimanski.eveuniverse.today"];
	url = [url URLByAppendingPathComponent:@"today.plist"];
	NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	[coordinator coordinateReadingItemAtURL:url
									options:NSFileCoordinatorReadingWithoutChanges
									  error:nil
								 byAccessor:^(NSURL *newURL) {
									 self.rows = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:newURL]];
								 }];
	self.preferredContentSize = CGSizeMake(self.view.frame.size.width, 37 * [self tableView:self.tableView numberOfRowsInSection:1]);
	[self.tableView reloadData];
}

@end
