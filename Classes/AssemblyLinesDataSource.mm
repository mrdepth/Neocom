//
//  AssemblyLinesDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 16.08.13.
//
//

#import "AssemblyLinesDataSource.h"
#import "POSFittingViewController.h"
#import "EUOperationQueue.h"
#import "eufe.h"
#import "NSString+Fitting.h"
#import "ItemInfo.h"
#import "POSFit.h"

#import "ModuleCellView.h"
#import "UITableViewCell+Nib.h"
#import "NSArray+GroupBy.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface AssemblyLinesDataSource()
@property (nonatomic, strong) NSArray* assemblyLines;

@end

@implementation AssemblyLinesDataSource

- (void) reload {
	NSMutableArray *assemblyLinesTmp = [NSMutableArray array];
	EUOperation *operation = [EUOperation operationWithIdentifier:@"AssemblyLinesDataSource+reload" name:NSLocalizedString(@"Updating Assembly Lines", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary dictionary];
			
			float n = structuresList.size();
			float j = 0;
			for (i = structuresList.begin(); i != end; i++) {
				weakOperation.progress = j++ / n;
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
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.assemblyLines  = assemblyLinesTmp;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.assemblyLines.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[self.assemblyLines objectAtIndex:section] count] ;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary* row = [[self.assemblyLines objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	EVEDBRamAssemblyLineType* assemblyLineType = [row valueForKey:@"assemblyLineType"];
	
	static NSString *cellIdentifier = @"ModuleCellView";
	ModuleCellView *cell = (ModuleCellView*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [ModuleCellView cellWithNibName:@"ModuleCellView" bundle:nil reuseIdentifier:cellIdentifier];
	}
	
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%@)", assemblyLineType.assemblyLineTypeName, [row valueForKey:@"count"]];
	
	cell.iconView.image = [UIImage imageNamed:assemblyLineType.activity.iconImageName];
	cell.stateView.image = nil;
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	cell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	return [[[[[self.assemblyLines objectAtIndex:section] objectAtIndex:0] valueForKey:@"assemblyLineType"] activity] activityName];
}


#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		view.collapsImageView.hidden = YES;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
