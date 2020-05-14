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
@property (nonatomic, strong) NSString* assemblyLineTypeName;
@property (nonatomic, strong) NSString* activityName;
@property (nonatomic, assign) int32_t activityID;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, assign) NSInteger count;
@end

@implementation NCFittingPOSAssemblyLinesViewControllerRow

@end

@interface NCFittingPOSAssemblyLinesViewController()
@property (nonatomic, strong) NSArray* sections;

@end

@implementation NCFittingPOSAssemblyLinesViewController

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	if (self.controller.engine) {
		[self.controller.engine performBlock:^{
			auto controlTower = self.controller.engine.engine->getControlTower();
			
			NSMutableDictionary* assemblyLinesTypes = [NSMutableDictionary new];
			
			for (const auto& structure: controlTower->getStructures()) {
				if (structure->getState() >= dgmpp::Module::STATE_ACTIVE) {
					NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:structure->getTypeID()];
					if (type) {
						for (NCDBRamInstallationTypeContent* installation in type.installationTypeContents) {
							NCFittingPOSAssemblyLinesViewControllerRow* row = assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)];
							if (!row) {
								row = [NCFittingPOSAssemblyLinesViewControllerRow new];
								row.assemblyLineTypeName = installation.assemblyLineType.assemblyLineTypeName;
								row.activityID = installation.assemblyLineType.activity.activityID;
								row.activityName = installation.assemblyLineType.activity.activityName;
								row.count = 1;
								row.image = installation.assemblyLineType.activity.icon.image.image;
								assemblyLinesTypes[@(installation.assemblyLineType.assemblyLineTypeID)] = row;
							}
							else
								row.count++;
						}
					}
				}
			}
			NSArray* sections = [[assemblyLinesTypes allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"assemblyLineTypeName" ascending:YES]]];
			sections = [sections arrayGroupedByKey:@"activityID"];
			sections = [sections sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NCFittingPOSAssemblyLinesViewControllerRow* a = [obj1 objectAtIndex:0];
				NCFittingPOSAssemblyLinesViewControllerRow* b = [obj2 objectAtIndex:0];
				return [a.activityName compare:b.activityName];
			}];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				completionBlock();
			});
		}];
	}
	else
		completionBlock();
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
	//return self.view.window ? self.sections.count : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return [(NSArray*) self.sections[section] count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NCFittingPOSAssemblyLinesViewControllerRow* row = self.sections[section][0];
	return row.activityName;
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

- (id) identifierForSection:(NSInteger)sectionIndex {
	NCFittingPOSAssemblyLinesViewControllerRow* row = self.sections[sectionIndex][0];
	return @(row.activityID);
}


#pragma mark - Private

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(NCDefaultTableViewCell*) cell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingPOSAssemblyLinesViewControllerRow* row = self.sections[indexPath.section][indexPath.row];
	cell.titleLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.assemblyLineTypeName, (int32_t) row.count];
	cell.iconView.image = row.image ?: self.defaultTypeImage;
	cell.subtitleLabel.text = nil;
	cell.accessoryView = nil;
}

@end
