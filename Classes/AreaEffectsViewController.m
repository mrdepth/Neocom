//
//  AreaEffectsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AreaEffectsViewController.h"
#import "EVEDBAPI.h"
#import "AreaEffectCellView.h"
#import "UITableViewCell+Nib.h"
#import "Globals.h"
#import "ItemViewController.h"

@interface AreaEffectsViewController(Private)
- (void) reload;
@end

@implementation AreaEffectsViewController
@synthesize tableView;
@synthesize delegate;
@synthesize mainViewController;
@synthesize selectedArea;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Area Effects", nil);
	[self reload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.tableView = nil;
	[sections release];
	sections = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)dealloc {
	[tableView release];
	[sections release];
	[selectedArea release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return sections.count;
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
	return [[sections objectAtIndex:section] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"AreaEffectCellView";
    
    AreaEffectCellView *cell = (AreaEffectCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [AreaEffectCellView cellWithNibName:@"AreaEffectCellView" bundle:nil reuseIdentifier:cellIdentifier];
    }
	EVEDBInvType *row = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.titleLabel.text = row.typeName;
	cell.stateView.image = selectedArea && selectedArea.typeID == row.typeID ? [UIImage imageNamed:@"checkmark.png"] : nil;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
	NSString *s = [self tableView:aTableView titleForHeaderInSection:section];
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = s;
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 36;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	[delegate areaEffectsViewController:self didSelectAreaEffect:[[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)aTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	EVEDBInvType *row = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	ItemViewController *controller = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
	
	controller.type = row;
	[controller setActivePage:ItemViewControllerActivePageInfo];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		navController.modalPresentationStyle = UIModalPresentationFormSheet;
		[mainViewController presentModalViewController:navController animated:YES];
		[navController release];
	}
	else
		[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	popoverController.popoverContentSize = CGSizeMake(320, 1100);
}

@end


@implementation AreaEffectsViewController(Private)

- (void) reload {
	NSMutableArray *sectionsTmp = [NSMutableArray array];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AreaEffectsViewController+Load" name:NSLocalizedString(@"Loading Area Effects", nil)];
	[operation addExecutionBlock:^(void) {
		if ([operation isCancelled])
			return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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
			[database execWithSQLRequest:@"SELECT * from invTypes WHERE groupID=920 ORDER BY typeName" resultBlock:^(NSDictionary *record, BOOL *needsMore) {
				if (![operation isCancelled]) {
					EVEDBInvType* type = [EVEDBInvType invTypeWithDictionary:record];
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
		
		[sectionsTmp addObject:blackHole];
		[sectionsTmp addObject:cataclysmic];
		[sectionsTmp addObject:magnetar];
		[sectionsTmp addObject:pulsar];
		[sectionsTmp addObject:redGiant];
		[sectionsTmp addObject:wolfRayet];
		[sectionsTmp addObject:incursion];
		[sectionsTmp addObject:other];
		
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			[sections release];
			sections = [sectionsTmp retain];
			[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end