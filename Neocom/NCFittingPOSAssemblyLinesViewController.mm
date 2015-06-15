//
//  NCFittingPOSAssemblyLinesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 15.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSAssemblyLinesViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NSArray+Neocom.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingPOSAssemblyLinesViewControllerRow : NSObject
@property (nonatomic, strong) NCDBRamAssemblyLineType* assemblyLineType;
@property (nonatomic, assign) NSInteger count;
@end

@implementation NCFittingPOSAssemblyLinesViewControllerRow

@end

@interface NCFittingPOSAssemblyLinesViewController()
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCFittingPOSAssemblyLinesViewController

- (void) reload {
	__block NSArray* sections = nil;
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														//@synchronized(self.controller) {
														eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
														
														NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary new];
														
														float n = controlTower->getStructures().size();
														float j = 0;
														for (auto structure: controlTower->getStructures()) {
															task.progress = j++ / n;
															if (structure->getState() >= eufe::Module::STATE_ACTIVE) {
																NCDBInvType* type = [self.controller typeWithItem:structure];
																if (type) {
																	for (NCDBRamInstallationTypeContent* installation in type.installationTypeContents) {
																		NCFittingPOSAssemblyLinesViewControllerRow* row = assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)];
																		if (!row) {
																			row = [NCFittingPOSAssemblyLinesViewControllerRow new];
																			row.assemblyLineType = installation.assemblyLineType;
																			row.count = 1;
																			assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)] = row;
																		}
																		else
																			row.count++;
																	}
																}
															}
														}
														sections = [[assemblyLinesTypes allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assemblyLineType.assemblyLineTypeName" ascending:YES]]];
														sections = [sections arrayGroupedByKey:@"assemblyLineType.activity.activityID"];
														sections = [sections sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
															NCFittingPOSAssemblyLinesViewControllerRow* a = [obj1 objectAtIndex:0];
															NCFittingPOSAssemblyLinesViewControllerRow* b = [obj2 objectAtIndex:0];
															return [a.assemblyLineType.activity.activityName compare:b.assemblyLineType.activity.activityName];
														}];
														//}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.sections = sections;
												
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
											}
										}];
}


/*- (NCFittingShipDronesTableHeaderView*) tableHeaderView {
 if (!_tableHeaderView) {
 _tableHeaderView = [NCFittingShipDronesTableHeaderView viewWithNibName:@"NCFittingShipDronesTableHeaderView" bundle:nil];
 }
 return _tableHeaderView;
 }*/

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return [(NSArray*) self.sections[section] count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NCFittingPOSAssemblyLinesViewControllerRow* row = self.sections[section][0];
	return row.assemblyLineType.activity.activityName;
}

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		view.textLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	return title ? 44 : 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingPOSAssemblyLinesViewControllerRow* row = self.sections[indexPath.section][indexPath.row];
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.assemblyLineType.assemblyLineTypeName, (int32_t) row.count];
	cell.iconView.image = row.assemblyLineType.activity.icon ? row.assemblyLineType.activity.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
	cell.subtitleLabel.text = nil;
	cell.accessoryView = nil;
}

@end
