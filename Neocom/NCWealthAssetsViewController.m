//
//  NCWealthAssetsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 23.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCWealthAssetsViewController.h"
#import "NCWealthCell.h"
#import "NSNumberFormatter+Neocom.h"

@interface NCWealthAssetsViewController()
@property (nonatomic, strong) NSArray* rows;
- (NSNumberFormatter*) numberFormatterWithTitle:(NSString*) title value:(double) value;
@end

@implementation NCWealthAssetsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.refreshControl = nil;
	
	NSMutableArray* categories = [[NSMutableArray alloc] initWithObjects:@0,@0,@0,@0,@0, nil];
	[self.categories enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		int32_t identifier = 0;
		switch ([key integerValue]) {
			case 6://Ships
				identifier = 0;
				break;
			case 7://Modules
			case 32://Subsystems
				identifier = 1;
				break;
			case 18://Drones
			case 8://Charges
				identifier = 2;
				break;
			case 25://Asteroid
			case 34://Ancient Relics
			case 4://Material
			case 42://Planetary Resources
			case 24://Reactions
				identifier = 3;
				break;
			default:
				identifier = 4;
				break;
		}
		categories[identifier] = @([categories[identifier] doubleValue] + [obj doubleValue]);
	}];
	
	NSMutableArray* rows = [NSMutableArray new];
	if ([categories[0] doubleValue] > 0)
		[rows addObject:@{@"title":NSLocalizedString(@"Ships", nil), @"value": categories[0], @"color":[UIColor greenColor]}];
	if ([categories[1] doubleValue] > 0)
		[rows addObject:@{@"title":NSLocalizedString(@"Modules", nil), @"value": categories[1], @"color":[UIColor cyanColor]}];
	if ([categories[2] doubleValue] > 0)
		[rows addObject:@{@"title":NSLocalizedString(@"Drones/Charges", nil), @"value": categories[2], @"color":[UIColor redColor]}];
	if ([categories[3] doubleValue] > 0)
		[rows addObject:@{@"title":NSLocalizedString(@"Materials", nil), @"value": categories[3], @"color":[UIColor yellowColor]}];
	if ([categories[4] doubleValue] > 0)
		[rows addObject:@{@"title":NSLocalizedString(@"Other", nil), @"value": categories[4], @"color":[UIColor orangeColor]}];
	self.rows = rows;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.rows.count + 2;
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row == 0 ? @"NCWealthCell" : @"Cell";
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row == 0) {
		NCWealthCell* cell = (NCWealthCell*) tableViewCell;
		[cell.pieChartView clear];
		for (NSDictionary* row in self.rows) {
			double value = [row[@"value"] doubleValue];
			[cell.pieChartView addSegment:[NCPieChartSegment segmentWithValue:value color:row[@"color"] numberFormatter:[self numberFormatterWithTitle:row[@"title"] value:value]] animated:YES];
		}
	}
	else if (indexPath.row == self.rows.count + 1) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		double value = 0;
		for (NSDictionary* row in self.rows)
			value += [row[@"value"] doubleValue];

		cell.titleLabel.text = NSLocalizedString(@"Total", nil);
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@(value)]];
	}
	else {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		NSDictionary* row = self.rows[indexPath.row - 1];
		cell.titleLabel.text = row[@"title"];
		cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ ISK", [NSNumberFormatter neocomLocalizedStringFromNumber:@([row[@"value"] doubleValue])]];

	}
}

#pragma mark - Private

- (NSNumberFormatter*) numberFormatterWithTitle:(NSString*) title value:(double) value {
	NSNumberFormatter* formatter = [NSNumberFormatter new];
	NSString* abbreviation;
	if (value >= 1E12) {
		abbreviation = NSLocalizedString(@"T", nil);
		formatter.multiplier = @((double) 1E-12);
	}
	else if (value >= 1E9) {
		abbreviation = NSLocalizedString(@"B", nil);
		formatter.multiplier = @((double) 1E-9);
	}
	else if (value >= 1E6) {
		abbreviation = NSLocalizedString(@"M", nil);
		formatter.multiplier = @((double) 1E-6);
	}
	else if (value >= 1E3) {
		abbreviation = NSLocalizedString(@"k", nil);
		formatter.multiplier = @((double) 1E-3);
	}
	else
		abbreviation = @"";
	formatter.positiveFormat = [NSString stringWithFormat:NSLocalizedString(@"%@\n#,##0.00%@ ISK", nil), title, abbreviation];
	return formatter;
}


@end
