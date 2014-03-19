//
//  NCFittingAreaEffectPickerViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAreaEffectPickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCFittingAreaEffectPickerViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCFittingAreaEffectPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
	NSMutableArray* sections = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NSMutableArray* blackHole = [NSMutableArray array];
											 NSMutableArray* cataclysmic = [NSMutableArray array];
											 NSMutableArray* magnetar = [NSMutableArray array];
											 NSMutableArray* pulsar = [NSMutableArray array];
											 NSMutableArray* redGiant = [NSMutableArray array];
											 NSMutableArray* wolfRayet = [NSMutableArray array];
											 NSMutableArray* incursion = [NSMutableArray array];
											 NSMutableArray* other = [NSMutableArray array];
											 
											 EVEDBDatabase *database = [EVEDBDatabase sharedDatabase];
											 if (database) {
												 [database execSQLRequest:@"SELECT * from invTypes WHERE groupID=920 ORDER BY typeName"
															  resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
																  if (![task isCancelled]) {
																	  EVEDBInvType* type = [[EVEDBInvType alloc] initWithStatement:stmt];
																	  if ([type.typeName rangeOfString:@"Black Hole Effect Beacon Class"].location != NSNotFound)
																		  [blackHole addObject:type];
																	  else if ([type.typeName rangeOfString:@"Cataclysmic Variable Effect Beacon Class"].location != NSNotFound)
																		  [cataclysmic addObject:type];
																	  else if ([type.typeName rangeOfString:@"Incursion"].location != NSNotFound)
																		  [incursion addObject:type];
																	  else if ([type.typeName rangeOfString:@"Magnetar Effect Beacon Class"].location != NSNotFound)
																		  [magnetar addObject:type];
																	  else if ([type.typeName rangeOfString:@"Pulsar Effect Beacon Class"].location != NSNotFound)
																		  [pulsar addObject:type];
																	  else if ([type.typeName rangeOfString:@"Red Giant Beacon Class"].location != NSNotFound)
																		  [redGiant addObject:type];
																	  else if ([type.typeName rangeOfString:@"Wolf Rayet Effect Beacon Class"].location != NSNotFound)
																		  [wolfRayet addObject:type];
																	  else
																		  [other addObject:type];
																  }
																  else
																	  *needsMore = NO;
															  }];
											 }
											 
											 [sections addObject:blackHole];
											 [sections addObject:cataclysmic];
											 [sections addObject:magnetar];
											 [sections addObject:pulsar];
											 [sections addObject:redGiant];
											 [sections addObject:wolfRayet];
											 [sections addObject:incursion];
											 [sections addObject:other];
										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.sections = sections;
									 [self.tableView reloadData];
								 }
							 }];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedAreaEffect = [sender object];
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* destinationViewController = [segue destinationViewController];
		destinationViewController.type = [sender object];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return self.sections.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return NSLocalizedString(@"Black Hole", nil);
		case 1:
			return NSLocalizedString(@"Cataclysmic Variable", nil);
		case 2:
			return NSLocalizedString(@"Magnetar", nil);
		case 3:
			return NSLocalizedString(@"Pulsar", nil);
		case 4:
			return NSLocalizedString(@"Red Giant", nil);
		case 5:
			return NSLocalizedString(@"Wolf Rayet", nil);
		case 6:
			return NSLocalizedString(@"Incursion", nil);
		default:
			return NSLocalizedString(@"Other", nil);
	}
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"Cell";
	NCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	EVEDBInvType* row = self.sections[indexPath.section][indexPath.row];
	cell.titleLabel.text = row.typeName;
	cell.accessoryView = self.selectedAreaEffect && self.selectedAreaEffect.typeID == row.typeID ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	cell.object = row;
	return cell;
}

#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

@end
