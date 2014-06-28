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
	defaultMarginInsets.bottom = 0;
	return defaultMarginInsets;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	
	return cell;
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
	self.preferredContentSize = CGSizeMake(self.view.frame.size.width, self.tableView.rowHeight * [self tableView:self.tableView numberOfRowsInSection:1]);
	[self.tableView reloadData];
}

@end
