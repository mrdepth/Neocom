//
//  AssemblyLinesViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AssemblyLinesViewController.h"
#import "POSFittingViewController.h"
#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "POSFit.h"
#import "EVEDBAPI.h"
#import "NSArray+GroupBy.h"

#import "ItemInfo.h"

@implementation AssemblyLinesViewController
@synthesize posFittingViewController;
@synthesize tableView;

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
	//	[self update];
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
	self.tableView = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}


- (void) dealloc {
	[tableView release];
	[assemblyLines release];
	[super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return assemblyLines.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[assemblyLines objectAtIndex:section] count] ;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = [[assemblyLines objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	EVEDBRamAssemblyLineType* assemblyLineType = [row valueForKey:@"assemblyLineType"];
	
	static NSString *cellIdentifier = @"ModuleCellView";
	ModuleCellView *cell = (ModuleCellView*) [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%@)", assemblyLineType.assemblyLineTypeName, [row valueForKey:@"count"]];
	
	cell.iconView.image = [UIImage imageNamed:assemblyLineType.activity.iconImageName];
	cell.stateView.image = nil;
	
	return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	return [[[[[assemblyLines objectAtIndex:section] objectAtIndex:0] valueForKey:@"assemblyLineType"] activity] activityName];
}


#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
	UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 22)] autorelease];
	header.opaque = NO;
	header.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
	
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 22)] autorelease];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.text = aTableView == self.searchDisplayController.searchResultsTableView ? nil : [self tableView:aTableView titleForHeaderInSection:section];
	label.textColor = [UIColor whiteColor];
	label.font = [label.font fontWithSize:12];
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[header addSubview:label];
	return header;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [[self tableView:aTableView cellForRowAtIndexPath:indexPath] frame].size.height;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark FittingSection

- (void) update {
	NSMutableArray *assemblyLinesTmp = [NSMutableArray array];
	POSFittingViewController* aPosFittingViewController = posFittingViewController;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"AssemblyLinesViewController+Update" name:@"Updating Assembly Lines"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(posFittingViewController) {
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary dictionary];

			float n = structuresList.size();
			float j = 0;
			for (i = structuresList.begin(); i != end; i++) {
				operation.progress = j++ / n;
				if ((*i)->getState() >= eufe::Module::STATE_ACTIVE) {
					ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:*i error:nil];
					if (itemInfo) {
						for (EVEDBRamInstallationTypeContent* installation in itemInfo.installations) {
							NSString* key = [NSString stringWithFormat:@"%d", installation.assemblyLineTypeID];
							NSDictionary* value = [assemblyLinesTypes valueForKey:key];
							if (!value) {
								value = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 installation.assemblyLineType, @"assemblyLineType",
										 [NSNumber numberWithInteger:installation.quantity], @"count", nil];
								[assemblyLinesTypes setValue:value forKey:key];
							}
							else {
								int count = [[value valueForKey:@"count"] integerValue] + installation.quantity;
								[value setValue:[NSNumber numberWithInteger:count] forKey:@"count"];
							}
						}
					}
				}
			}
			NSArray* rows = [[assemblyLinesTypes allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"assemblyLinesType.assemblyLineTypeName" ascending:YES]]];
			rows = [rows arrayGroupedByKey:@"assemblyLineType.activityID"];
			rows = [rows sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NSDictionary* a = [obj1 objectAtIndex:0];
				NSDictionary* b = [obj2 objectAtIndex:0];
				return [[a valueForKeyPath:@"assemblyLineType.activity.activityName"] compare:[b valueForKeyPath:@"assemblyLineType.activity.activityName"]];
			}];
			[assemblyLinesTmp addObjectsFromArray:rows];
		}

		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			if (assemblyLines)
				[assemblyLines release];
			assemblyLines  = [assemblyLinesTmp retain];
			[tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end