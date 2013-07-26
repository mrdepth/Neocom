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
#import "GroupedCell.h"
#import "appearance.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "APIKey.h"

@interface AccessMaskViewController()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSDictionary *groups;


@end

@implementation AccessMaskViewController

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
	
	NSString* keyType = nil;
	if (self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeAccount)
		keyType = @"Account";
	else if (self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCharacter)
		keyType = @"Char";
	else if (self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation)
		keyType = @"Corp";
	else
		keyType = @"Unknown";
	
	self.title = [NSString stringWithFormat:@"%@ key: %d", keyType, self.apiKey.keyID];

	
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	
	__block NSArray *sectionsTmp = nil;
	NSMutableDictionary *groupsTmp = [NSMutableDictionary dictionary];
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AccessMaskViewController+viewDidLoad" name:NSLocalizedString(@"Loading Access Mask", nil)];
	[operation addExecutionBlock:^{
		NSError *error = nil;
		EVECalllist *calllist = [EVECalllist calllistWithError:&error progressHandler:nil];
		if (error) {
			[[UIAlertView alertViewWithError:error] performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		}
		else {
			for (EVECalllistCallGroupsItem *callGroup in calllist.callGroups) {
				groupsTmp[@(callGroup.groupID)] = callGroup.name;
			}
			
			BOOL corporate = self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation;

			NSIndexSet *indexes = [calllist.calls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
				return corporate ^ ([(EVECalllistCallsItem*) obj type] == EVECallTypeCharacter);
			}];
			
			sectionsTmp = [[calllist.calls objectsAtIndexes:indexes] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
			sectionsTmp = [sectionsTmp arrayGroupedByKey:@"groupID"];
			sectionsTmp = [sectionsTmp sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NSInteger groupID1 = [[obj1 objectAtIndex:0] groupID];
				NSInteger groupID2 = [[obj2 objectAtIndex:0] groupID];
				NSString *name1 = groupsTmp[@(groupID1)];
				NSString *name2 = groupsTmp[@(groupID2)];
				return [name1 compare:name2];
			}];
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		self.sections = sectionsTmp;
		self.groups = groupsTmp;
		[self.tableView reloadData];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
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
	self.sections = nil;
	self.groups = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.groups[@([self.sections[section][0] groupID])];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Cell";
    
    GroupedCell *cell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		cell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.font = [UIFont systemFontOfSize:12];
		cell.textLabel.shadowColor = [UIColor blackColor];
		cell.textLabel.textColor = [UIColor whiteColor];
    }
	EVECalllistCallsItem *call = self.sections[indexPath.section][indexPath.row];
	cell.textLabel.text = call.name;
	cell.accessoryView = (self.apiKey.apiKeyInfo.key.accessMask & call.accessMask) ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] : nil;
	
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 22;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
	view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
	return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return YES;
}

@end
