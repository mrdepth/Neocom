//
//  AccessMaskViewController.m
//  EVEUniverse
//
//  Created by Shimanski on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AccessMaskViewController.h"
#import "UIAlertView+Error.h"
#import "EUOperationQueue.h"
#import "NSArray+GroupBy.h"
#import "UITableViewCell+Nib.h"
#import "AccessMaskCellView.h"

@implementation AccessMaskViewController
@synthesize accessMaskTableView;
@synthesize accessMask;
@synthesize corporate;

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
	self.title = @"Access Mask";
	
	__block NSArray *sectionsTmp = nil;
	NSMutableDictionary *groupsTmp = [NSMutableDictionary dictionary];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AccessMaskViewController+viewDidLoad" name:@"Loading Access Mask"];
	[operation addExecutionBlock:^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSError *error = nil;
		EVECalllist *calllist = [EVECalllist calllistWithError:&error];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			for (EVECalllistCallGroupsItem *callGroup in calllist.callGroups) {
				[groupsTmp setObject:callGroup.name forKey:[NSString stringWithFormat:@"%d", callGroup.groupID]];
			}

			NSIndexSet *indexes = [calllist.calls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
				return corporate ^ ([(EVECalllistCallsItem*) obj type] == EVECallTypeCharacter);
			}];
			
			sectionsTmp = [[calllist.calls objectsAtIndexes:indexes] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
			sectionsTmp = [sectionsTmp arrayGroupedByKey:@"groupID"];
			sectionsTmp = [[sectionsTmp sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NSInteger groupID1 = [[obj1 objectAtIndex:0] groupID];
				NSInteger groupID2 = [[obj2 objectAtIndex:0] groupID];
				NSString *name1 = [groupsTmp valueForKey:[NSString stringWithFormat:@"%d", groupID1]];
				NSString *name2 = [groupsTmp valueForKey:[NSString stringWithFormat:@"%d", groupID2]];
				return [name1 compare:name2];
			}] retain];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		[sections release];
		sections = sectionsTmp;
		[groups release];
		groups = [groupsTmp retain];
		[accessMaskTableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.accessMaskTableView = nil;
	[sections release];
	sections = nil;
	[groups release];
	groups = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[accessMaskTableView release];
	[sections release];
	[groups release];
    [super dealloc];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [groups valueForKeyPath:[NSString stringWithFormat:@"%d", [[[sections objectAtIndex:section] objectAtIndex:0] groupID]]];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"AccessMaskCellView";
    
    AccessMaskCellView *cell = (AccessMaskCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		cell = [AccessMaskCellView cellWithNibName:@"AccessMaskCellView" bundle:nil reuseIdentifier:cellIdentifier];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
		cell.textLabel.shadowColor = [UIColor blackColor];
		cell.textLabel.shadowOffset = CGSizeMake(1, 1);
    }
	EVECalllistCallsItem *call = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = call.name;
	UISwitch *switchView = (UISwitch*) cell.accessoryView;
	switchView.on = (accessMask & call.accessMask) > 0;
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
