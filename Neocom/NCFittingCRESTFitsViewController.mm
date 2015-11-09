//
//  NCFittingCRESTFitsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 06.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingCRESTFitsViewController.h"
#import <EVEAPI/EVEAPI.h>
#import "NCFittingShipViewController.h"
#import "UIAlertController+Neocom.h"

@interface NCFittingCRESTFitsViewControllerSection : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, strong) NSString* title;
@end

@implementation NCFittingCRESTFitsViewControllerSection

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.rows = [[aDecoder decodeObjectForKey:@"rows"] mutableCopy];
		self.title = [aDecoder decodeObjectForKey:@"title"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.rows forKey:@"rows"];
	[aCoder encodeObject:self.title forKey:@"title"];
}

@end

@interface NCFittingCRESTFitsViewController ()
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, strong) NSMutableSet* imported;
@end

@implementation NCFittingCRESTFitsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.cacheRecordID = [NSString stringWithFormat:@"%@.%d", NSStringFromClass(self.class), self.token.characterID];
	self.imported = [NSMutableSet new];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = [[NCShipFit alloc] initWithCRFitting:[sender object]];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSArray* data = self.cacheData;
	return data.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NSArray* data = self.cacheData;
	NCFittingCRESTFitsViewControllerSection* section = data[sectionIndex];
	return section.rows.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NSArray* data = self.cacheData;
	NCFittingCRESTFitsViewControllerSection* section = data[sectionIndex];
	return section.title;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
	}
}

- (NSArray<UITableViewRowAction*> *) tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSMutableArray* data = self.cacheData;
	NCFittingCRESTFitsViewControllerSection* section = data[indexPath.section];
	CRFitting* fitting = section.rows[indexPath.row];

	UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
		if (self.busy)
			return;
		if (self.token) {
			self.busy = YES;
			
			CRAPI* api = [CRAPI apiWithCachePolicy:NSURLRequestUseProtocolCachePolicy clientID:CRAPIClientID secretKey:CRAPISecretKey token:self.token callbackURL:[NSURL URLWithString:CRAPICallbackURLString]];
			self.progress = [NSProgress progressWithTotalUnitCount:30];
			[self simulateProgress:self.progress];
			[api deleteFittingWithID:fitting.fittingID completionBlock:^(BOOL completed, NSError *error) {
				self.progress = nil;
				self.busy = NO;
				if (completed) {
					[section.rows removeObjectAtIndex:indexPath.row];
					if (section.rows.count == 0) {
						[data removeObjectAtIndex:indexPath.section];
						[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
					}
					else
						[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
					[self saveCacheData:data cacheDate:nil expireDate:nil];
				}
				else if (error) {
					[self presentViewController:[UIAlertController alertWithError:error] animated:YES completion:nil];
				}
			}];
		}
	}];
	if (![self.imported containsObject:@(fitting.fittingID)]) {
		UITableViewRowAction* importAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Import", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
			[self.imported addObject:@(fitting.fittingID)];
			NCShipFit* fit = [[NCShipFit alloc] initWithCRFitting:fitting];
			[fit save];
			[self setEditing:NO animated:YES];
		}];
		importAction.backgroundColor = [UIColor darkGrayColor];
		return @[deleteAction, importAction];
	}
	else
		return @[deleteAction];
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	NSArray* data = self.cacheData;
	NCFittingCRESTFitsViewControllerSection* section = data[indexPath.section];
	CRFitting* fitting = section.rows[indexPath.row];
	NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:fitting.ship.typeID];
	
	cell.titleLabel.text = type.typeName ?: [NSString stringWithFormat:NSLocalizedString(@"Unknown type %d", nil), fitting.ship.typeID];
	cell.iconView.image = type.icon.image.image ?: [self.databaseManagedObjectContext defaultTypeIcon].image.image;
	cell.subtitleLabel.text = fitting.name;
	cell.object = fitting;
}

- (id) identifierForSection:(NSInteger)sectionIndex {
	NSArray* data = self.cacheData;
	NCFittingCRESTFitsViewControllerSection* section = data[sectionIndex];
	return section.title;
}


- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	if (self.token) {
		CRAPI* api = [CRAPI apiWithCachePolicy:cachePolicy clientID:CRAPIClientID secretKey:CRAPISecretKey token:self.token callbackURL:[NSURL URLWithString:CRAPICallbackURLString]];
		[api loadFittingsWithCompletionBlock:^(NSArray<CRFitting *> *result, NSError *error) {
			NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
			[databaseManagedObjectContext performBlock:^{
				NSMutableDictionary* dic = [NSMutableDictionary new];
				for (CRFitting* fitting in result) {
					NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:fitting.ship.typeID];
					if (type) {
						NCFittingCRESTFitsViewControllerSection* section = dic[@(type.group.groupID)];
						if (!section) {
							dic[@(type.group.groupID)] = section = [NCFittingCRESTFitsViewControllerSection new];
							section.rows = [NSMutableArray new];
							section.title = type.group.groupName;
						}
						[(NSMutableArray*) section.rows addObject:fitting];
					}
				}
				NSMutableArray* sections = [[[dic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]] mutableCopy];
				for (NCFittingCRESTFitsViewControllerSection* section in sections)
					[section.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"ship.name" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[self saveCacheData:sections cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
					completionBlock(error);
				});
			}];
		} progressBlock:nil];
	}
	else
		completionBlock(nil);
}

@end
