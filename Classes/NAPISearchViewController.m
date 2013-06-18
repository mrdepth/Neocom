//
//  NAPISearchViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import "NAPISearchViewController.h"
#import "UITableViewCell+Nib.h"
#import "EVEDBAPI.h"

@interface NAPISearchViewController ()
@property (nonatomic, strong) EVEDBInvType* ship;
@property (nonatomic, strong) EVEDBInvGroup* group;
@property (nonatomic, strong) UIPopoverController* popoverController;
@property (nonatomic, assign) BOOL flags;

@end

@implementation NAPISearchViewController
@synthesize popoverController;

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
	self.title = NSLocalizedString(@"Community Fits", nil);
	self.fittingItemsViewController.marketGroupID = 4;
	self.fittingItemsViewController.title = NSLocalizedString(@"Ships", nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClose:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 3;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 2) {
		NSString *cellIdentifier = @"NAPISearchTitleCellView";
		
		NAPISearchTitleCellView *cell = (NAPISearchTitleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [NAPISearchTitleCellView cellWithNibName:@"NAPISearchTitleCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.delegate = self;
		}
		cell.accessoryType = UITableViewCellAccessoryNone;
		if (indexPath.row == 0) {
			if (!self.ship) {
				cell.titleLabel.text = NSLocalizedString(@"Select Ship", nil);
				cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
				cell.clearButton.hidden = YES;
			}
			else {
				cell.titleLabel.text = self.ship.typeName;
				cell.iconImageView.image = [UIImage imageNamed:[self.ship typeSmallImageName]];
				cell.clearButton.hidden = NO;
			}
		}
		else {
			cell.iconImageView.image = [UIImage imageNamed:@"Icons/icon09_05.png"];
			if (!self.group) {
				cell.titleLabel.text = NSLocalizedString(@"Select Ship Class", nil);
				cell.clearButton.hidden = YES;
			}
			else {
				cell.titleLabel.text = self.group.groupName;
				cell.clearButton.hidden = NO;
			}
		}
		return cell;
	}
	else {
		NSString *cellIdentifier = @"NAPISearchSwitchCellView";
		
		NAPISearchSwitchCellView *cell = (NAPISearchSwitchCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [NAPISearchSwitchCellView cellWithNibName:@"NAPISearchSwitchCellView" bundle:nil reuseIdentifier:cellIdentifier];
			cell.delegate = self;
		}
		if (indexPath.row == 2) {
			cell.titleLabel.text = NSLocalizedString(@"Only Cap Stable Fits", nil);
			cell.iconImageView.image = [UIImage imageNamed:@"capacitor.png"];
		}
		return cell;
	}
	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.row == 0) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.fittingItemsNavigationController];
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			[self presentModalViewController:self.fittingItemsNavigationController animated:YES];
		}
	}
	else if (indexPath.row == 1) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.shipClassesNavigationController];
			[self.popoverController presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else {
			[self presentModalViewController:self.shipClassesNavigationController animated:YES];
		}
	}
	return;
}

#pragma mark - FittingItemsViewControllerDelegate

- (void) fittingItemsViewController:(FittingItemsViewController*) controller didSelectType:(EVEDBInvType*) type {
	self.ship = type;
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - KillNetFilterDBViewControllerDelegate

- (void) killNetFilterDBViewController:(KillNetFilterDBViewController*) controller didSelectItem:(NSDictionary*) item {
	self.ship = nil;
	self.group = [EVEDBInvGroup invGroupWithGroupID:[item[@"itemID"] integerValue] error:nil];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.popoverController dismissPopoverAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - NAPISearchTitleCellViewDelegate

- (void) searchTitleCellViewDidClear:(NAPISearchTitleCellView*) cellView {
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cellView];
	if (indexPath.row == 0) {
		self.ship = nil;
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	}
	else if (indexPath.row == 1) {
		self.group = nil;
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)viewDidUnload {
	[self setTableView:nil];
	self.fittingItemsViewController = nil;
	self.fittingItemsNavigationController = nil;
	[self setShipClassesViewController:nil];
	[self setShipClassesNavigationController:nil];
	[super viewDidUnload];
}

@end
