//
//  KillboardKillNetFilterViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillboardKillNetFilterViewController.h"
#import "UITableViewCell+Nib.h"
#import "EVEAccount.h"
#import "EVEKillNetAPI.h"
#import "EUOperationQueue.h"
#import "UIAlertView+Error.h"
#import "KillboardKillNetViewController.h"
#import "KillNetFilterShipClassesViewController.h"
#import "KillNetFilterRegionsViewController.h"
#import "KillNetFilterSolarSystemsViewController.h"
#import "appearance.h"
#import "NCItemsViewController.h"
#import "UIViewController+Neocom.h"


@interface KillboardKillNetFilterViewController ()
@property (nonatomic, strong) NSMutableArray* filters;
@property (nonatomic, strong) NSIndexPath* modifiedIndexPath;

- (IBAction)onSearch:(id)sender;
- (void) reload;
- (NSDictionary*) logFilter;

@end

@implementation KillboardKillNetFilterViewController

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
	self.title = NSLocalizedString(@"EVE-Kill.net", nil);
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	self.filters = [NSMutableArray array];
	[self.tableView setEditing:YES];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(onSearch:)];
	// Do any additional setup after loading the view.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.filters.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GroupedCell* cell;
	if (indexPath.row == self.filters.count) {
		static NSString *cellIdentifier = @"Cell";
		
		cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil)
			cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.textLabel.text = NSLocalizedString(@"Add Search Criteria", nil);
	}
	else
		cell = self.filters[indexPath.row][@"cell"];
	GroupedCellGroupStyle groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = groupStyle;
	return cell;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.filters.count) {
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
	}
	else {
		NSDictionary* filter = [self.filters objectAtIndex:indexPath.row];
		KillNetFilterType filterType = [[filter valueForKey:@"filterType"] integerValue];
		
		switch (filterType) {
			case KillNetFilterTypeVictimShip:
			case KillNetFilterTypeAttackerShip:
			case KillNetFilterTypeCombinedShip: {
				NCItemsViewController* controller = [[NCItemsViewController alloc] init];
				
				controller.title = [filter valueForKey:@"title"];
				controller.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"];
				
				
				controller.completionHandler = ^(EVEDBInvType* type) {
					if (type) {
						NSMutableDictionary* filter = [self.filters objectAtIndex:indexPath.row];
						[filter setValue:type.typeName forKey:@"value"];
						GroupedCell* cell = filter[@"cell"];
						cell.detailTextLabel.text = type.typeName;
						[self reload];
					}
					[self dismiss];
				};
				
				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
					[self presentViewControllerInPopover:controller
												fromRect:[tableView rectForRowAtIndexPath:indexPath]
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
				else {
					[self presentViewController:controller animated:YES completion:nil];
				}
				break;
			}
			case KillNetFilterTypeSolarSystem: {
				KillNetFilterSolarSystemsViewController* controller = [[KillNetFilterSolarSystemsViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
				controller.delegate = self;
				controller.title = [filter valueForKey:@"title"];
				
				UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
				navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;

				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					[self presentViewControllerInPopover:navigationController
												fromRect:[tableView rectForRowAtIndexPath:indexPath]
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

				}
				else {
					[self presentViewController:navigationController animated:YES completion:nil];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
				}
				
				self.modifiedIndexPath = indexPath;
				break;
			}
			case KillNetFilterTypeRegion: {
				KillNetFilterRegionsViewController* controller = [[KillNetFilterRegionsViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
				controller.groupsRequest = nil;
				controller.delegate = self;
				controller.title = [filter valueForKey:@"title"];
				
				UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
				navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;

				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					[self presentViewControllerInPopover:navigationController
												fromRect:[tableView rectForRowAtIndexPath:indexPath]
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
					
				}
				else {
					[self presentViewController:navigationController animated:YES completion:nil];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
				}
				
				self.modifiedIndexPath = indexPath;
				break;
			}
			case KillNetFilterTypeVictimShipClass:
			case KillNetFilterTypeAttackerShipClass: {
				KillNetFilterShipClassesViewController* controller = [[KillNetFilterShipClassesViewController alloc] initWithNibName:@"KillNetFilterDBViewController" bundle:nil];
				controller.delegate = self;
				controller.title = [filter valueForKey:@"title"];
				
				UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
				navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;

				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					[self presentViewControllerInPopover:navigationController
												fromRect:[tableView rectForRowAtIndexPath:indexPath]
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
					
				}
				else {
					[self presentViewController:navigationController animated:YES completion:nil];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
				}
				
				self.modifiedIndexPath = indexPath;
				break;
			}
			case KillNetFilterTypeStartDate:
			case KillNetFilterTypeEndDate: {
				KillNetFilterDateViewController* controller = [[KillNetFilterDateViewController alloc] initWithNibName:@"KillNetFilterDateViewController" bundle:nil];
				controller.title = [filter valueForKey:@"title"];
				controller.maximumDate = [NSDate date];
				controller.date = [filter valueForKey:@"value"];
				controller.delegate = self;
				
				UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
				navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;

				if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
					[self presentViewControllerInPopover:navigationController
												fromRect:[tableView rectForRowAtIndexPath:indexPath]
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
					
				}
				else {
					[self presentViewController:navigationController animated:YES completion:nil];
					controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
				}
				
				self.modifiedIndexPath = indexPath;
				break;
			}
			default:
				break;
		}
	}
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		KillNetFiltersViewController* controller = [[KillNetFiltersViewController alloc] initWithNibName:@"KillNetFiltersViewController" bundle:nil];
		controller.usedFilters = self.filters;
		controller.delegate = self;
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		navigationController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[self presentViewControllerInPopover:navigationController
										fromRect:[tableView rectForRowAtIndexPath:indexPath]
										  inView:tableView
						permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			
		}
		else {
			[self presentViewController:navigationController animated:YES completion:nil];
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
		}
	}
	else {
		KillNetFilterTextCellView* cell = [[self.filters objectAtIndex:indexPath.row] valueForKey:@"cell"];
		if ([cell isKindOfClass:[KillNetFilterTextCellView class]])
			[cell.textField resignFirstResponder];
		[self.filters removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self reload];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == self.filters.count)
		return UITableViewCellEditingStyleInsert;
	else
		return UITableViewCellEditingStyleDelete;
}

#pragma mark - KillNetFiltersViewControllerDelegate

- (void) killNetFiltersViewController:(KillNetFiltersViewController*) controller didSelectFilter:(NSDictionary*) aFilter {
	[self dismiss];
	
	NSMutableDictionary* filter = [NSMutableDictionary dictionaryWithDictionary:aFilter];
	[self.filters addObject:filter];
	KillNetFilterType filterType = [[filter valueForKey:@"filterType"] integerValue];
	
	//NSIndexPath* indexPath = [NSIndexPath indexPathForRow:self.filters.count - 1 inSection:0];

	switch (filterType) {
		case KillNetFilterTypeStartDate:
		case KillNetFilterTypeEndDate: {
			GroupedCell* cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ValueCell"];
			cell.textLabel.text = [filter valueForKey:@"title"];
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yyyy.MM.dd"];
			cell.detailTextLabel.text = [formatter stringFromDate:[filter valueForKey:@"value"]];
			filter[@"cell"] = cell;
			break;
		}
			
		case KillNetFilterTypeSolarSystem:
		case KillNetFilterTypeRegion:
		case KillNetFilterTypeVictimShip:
		case KillNetFilterTypeVictimShipClass:
		case KillNetFilterTypeAttackerShip:
		case KillNetFilterTypeAttackerShipClass:
		case KillNetFilterTypeCombinedShip:
		case KillNetFilterTypeCombinedShipClass: {
			GroupedCell* cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ValueCell"];
			cell.textLabel.text = [filter valueForKey:@"title"];
			cell.detailTextLabel.text = [filter valueForKey:@"value"];
			filter[@"cell"] = cell;
			break;
		}
			
		case KillNetFilterTypeVictimPilot:
		case KillNetFilterTypeVictimCorp:
		case KillNetFilterTypeVictimAlliance:
		case KillNetFilterTypeAttackerPilot:
		case KillNetFilterTypeAttackerCorp:
		case KillNetFilterTypeAttackerAlliance:
		case KillNetFilterTypeCombinedPilot:
		case KillNetFilterTypeCombinedCorp:
		case KillNetFilterTypeCombinedAlliance: {
			KillNetFilterTextCellView* cell = [KillNetFilterTextCellView cellWithNibName:@"KillNetFilterTextCellView" bundle:nil reuseIdentifier:@"KillNetFilterTextCellView"];
			cell.delegate = self;
			cell.textField.caption = [filter valueForKey:@"title"];
			cell.textField.delegate = self;
			filter[@"cell"] = cell;
			
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[cell.textField becomeFirstResponder];
			});
			break;
		}
		default:
			break;
	}
	
	//[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView reloadData];
	[self reload];
}

#pragma mark - KillNetFilterTextCellViewDelegate

- (void) killNetFilterTextCellViewDidPressDefaultButton:(KillNetFilterTextCellView*) cell {
	EVEAccount* account = [EVEAccount currentAccount];
	if (!account)
		return;
	
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	NSDictionary* filter = [self.filters objectAtIndex:indexPath.row];
	KillNetFilterType filterType = [[filter valueForKey:@"filterType"] integerValue];
	
	switch (filterType) {
		case KillNetFilterTypeVictimPilot:
		case KillNetFilterTypeAttackerPilot:
		case KillNetFilterTypeCombinedPilot:
			cell.textField.text = account.characterSheet.name;
			break;
		case KillNetFilterTypeVictimCorp:
		case KillNetFilterTypeAttackerCorp:
		case KillNetFilterTypeCombinedCorp:
			cell.textField.text = account.characterSheet.corporationName;
			break;
		case KillNetFilterTypeVictimAlliance:
		case KillNetFilterTypeAttackerAlliance:
		case KillNetFilterTypeCombinedAlliance:
			cell.textField.text = account.characterSheet.allianceName;
			break;
		default:
			break;
	}
	[self reload];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	[self reload];

	UITableViewCell* cell = (UITableViewCell*) [[textField superview] superview];
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	NSInteger n = self.filters.count;

	for (NSInteger i = indexPath.row + 1; i < n; i++) {
		KillNetFilterTextCellView* cell = [[self.filters objectAtIndex:i] valueForKey:@"cell"];
		if ([cell isKindOfClass:[KillNetFilterTextCellView class]]) {
			[cell.textField becomeFirstResponder];
			return YES;
		}
	}
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - KillNetFilterDBViewControllerDelegate

- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item {
	NSMutableDictionary* filter = [self.filters objectAtIndex:self.modifiedIndexPath.row];
	[filter setValue:[item valueForKey:@"name"] forKey:@"value"];
	GroupedCell* cell = filter[@"cell"];
	cell.detailTextLabel.text = [item valueForKey:@"name"];

	[self dismiss];
	[self reload];
}

#pragma mark - KillNetFilterDateViewControllerDelegate

- (void) killNetFilterDateViewController:(KillNetFilterDateViewController*) controller didSelectDate:(NSDate*) date {
	NSMutableDictionary* filter = [self.filters objectAtIndex:self.modifiedIndexPath.row];
	[filter setValue:date forKey:@"value"];
	
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy.MM.dd"];
	GroupedCell* cell = filter[@"cell"];
	cell.detailTextLabel.text = [formatter stringFromDate:date];

	[self dismiss];
	[self reload];
}


#pragma mark - Private

- (void) reload {
	NSDictionary* logFilter = [self logFilter];
	if (logFilter.count > 0) {
		EUOperation* operation = [EUOperation operationWithIdentifier:@"KillboardKillNetFilterViewController+Preload" name:NSLocalizedString(@"Loading...", nil)];
		__weak EUOperation* weakOperation = operation;

		__block NSInteger count = 0;
		[operation addExecutionBlock:^{
			EVEKillNetLog* killNetLog = [EVEKillNetLog logWithFilter:logFilter mask:EVEKillNetLogMaskInternalKillID error:nil progressHandler:nil];
			count = killNetLog.killLog.count;
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled])
				self.searchResultsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Search Results", nil), count];
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else
		self.searchResultsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Search Results", nil), 0];
}

- (IBAction)onSearch:(id)sender {
	NSDictionary* logFilter = [self logFilter];
	if (logFilter.count > 0) {
		EUOperation* operation = [EUOperation operationWithIdentifier:@"KillboardKillNetFilterViewController+Search" name:NSLocalizedString(@"Searching...", nil)];
		__weak EUOperation* weakOperation = operation;
		__block NSError* error = nil;
		__block EVEKillNetLog* killNetLog = nil;
		
		[operation addExecutionBlock:^{
			@autoreleasepool {
				killNetLog = [EVEKillNetLog logWithFilter:logFilter mask:EVEKillNetLogMaskShort error:&error progressHandler:nil];
			}
		}];
		
		[operation setCompletionBlockInMainThread:^{
			if (![weakOperation isCancelled]) {
				if (error)
					[[UIAlertView alertViewWithError:error] show];
				else {
					KillboardKillNetViewController* controller = [[KillboardKillNetViewController alloc] initWithNibName:@"KillboardKillNetViewController" bundle:nil];
					controller.killLog = killNetLog;
					[self.navigationController pushViewController:controller animated:YES];
				}
			}
		}];
		
		[[EUOperationQueue sharedQueue] addOperation:operation];
	}
	else
		self.searchResultsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Search Results", nil), 0];
}

- (NSDictionary*) logFilter {
	NSMutableDictionary* logFilter = [NSMutableDictionary dictionary];
	for (NSDictionary* filter in self.filters) {
		NSObject* value = [filter valueForKey:@"value"];
		if (!value) {
			KillNetFilterTextCellView* cell = [filter valueForKey:@"cell"];
			if ([cell isKindOfClass:[KillNetFilterTextCellView class]])
				value = cell.textField.text;
		}
		else if ([value isKindOfClass:[NSDate class]]) {
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
			[formatter setDateFormat:@"yyyy-MM-dd_HH.mm.ss"];
			value = [formatter stringFromDate:(NSDate*) value];
		}
		if (value)
			[logFilter setValue:value forKey:[filter valueForKey:@"key"]];
	}
	return logFilter;
}

@end
