//
//  NCItemsViewController.m
//  EVEUniverse
//
//  Created by mr_depth on 03.08.13.
//
//

#import "NCItemsViewController.h"
#import "NCItemsContentViewController.h"
#import "EVEDBAPI.h"
#import "GroupedCell.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"
#import "appearance.h"
#import <objc/runtime.h>
#import "UIViewController+Neocom.h"

@interface EVEDBInvMarketGroup (NCItemsViewController)
@property (nonatomic, strong, readonly) NSMutableArray* subgroups;
@end

@implementation EVEDBInvMarketGroup (NCItemsViewController)

- (NSMutableArray*) subgroups {
	NSMutableArray* subgroups = objc_getAssociatedObject(self, @"subgroups");
	if (!subgroups) {
		subgroups = [NSMutableArray new];
		objc_setAssociatedObject(self, @"subgroups", subgroups, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return subgroups;
}

@end

@interface NCItemsViewController ()
@property (nonatomic, strong) NSArray* groups;
@property (nonatomic, strong) NSSet* conditionsTables;

@end

@implementation NCItemsViewController

- (void) awakeFromNib {
	NCItemsContentViewController* controller = [[NCItemsContentViewController alloc] initWithNibName:@"NCItemsContentViewController" bundle:nil];
	controller.itemsViewController = self;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
	self.viewControllers = @[controller];
}

- (id) init {
	NCItemsContentViewController* controller = [[NCItemsContentViewController alloc] initWithNibName:@"NCItemsContentViewController" bundle:nil];
	controller.itemsViewController = self;
	if (self = [super initWithRootViewController:controller]) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	//self.conditions = @[@"invGroups.groupID = invTypes.groupID", @"invGroups.categoryID = 6"];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.viewControllers[0] setTitle:self.title];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setConditions:(NSArray *)conditions {
	if ([conditions isEqualToArray:_conditions])
		return;
	_conditions = conditions;
	_groups = nil;
	_conditionsTables = nil;
	if ([self isViewLoaded]) {
		self.navigationBarHidden = NO;
		//[[self.viewControllers[0] searchDisplayController] setActive:NO];
		NCItemsContentViewController* controller = [[NCItemsContentViewController alloc] initWithNibName:@"NCItemsContentViewController" bundle:nil];
		controller.itemsViewController = self;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
		[self setViewControllers:@[controller]];
	}
}

#pragma mark - Private

- (NSSet*) conditionsTables {
	if (!_conditionsTables) {
		NSMutableSet* conditionTables = [NSMutableSet new];
		for (NSString* condition in self.conditions) {
			
			NSError* error = nil;
			NSRegularExpression* expression = [[NSRegularExpression alloc] initWithPattern:@"\\b([a-zA-Z]{1,}?)\\.[a-zA-Z]{1,}?\\b" options:NSRegularExpressionCaseInsensitive error:&error];
			[expression enumerateMatchesInString:condition
										 options:0
										   range:NSMakeRange(0, condition.length)
									  usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
										  NSInteger n = [result numberOfRanges];
										  if (n == 2)
											  [conditionTables addObject:[condition substringWithRange:[result rangeAtIndex:1]]];
									  }];
		}
		_conditionsTables = conditionTables;
	}
	return _conditionsTables;
}

- (NSArray*) groups {
	if (!_groups) {
		NSMutableSet* allTables = [[NSMutableSet alloc] initWithObjects: @"invTypes", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invMarketGroups.marketGroupID=invTypes.marketGroupID", @"invTypes.published=1", nil];
		
		[allTables unionSet:self.conditionsTables];
		[allConditions addObjectsFromArray:self.conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invMarketGroups.* FROM invMarketGroups WHERE marketGroupID IN \
							 (SELECT invTypes.marketGroupID FROM %@ WHERE %@ GROUP BY invTypes.marketGroupID)",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		NSMutableDictionary* marketGroupsMap = [NSMutableDictionary new];
		NSMutableArray* parentGroupIDs = [NSMutableArray new];
		NSMutableArray* lastGroups = [NSMutableArray new];
		
		EVEDBDatabase* database = [EVEDBDatabase sharedDatabase];
		[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
			EVEDBInvMarketGroup* marketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
			marketGroupsMap[@(marketGroup.marketGroupID)] = marketGroup;
			if (marketGroup.parentGroupID)
				[parentGroupIDs addObject:[NSString stringWithFormat:@"%d", marketGroup.parentGroupID]];
		}];
		
		while (parentGroupIDs.count > 0) {
			request = [NSString stringWithFormat:@"SELECT * FROM invMarketGroups WHERE marketGroupID IN (%@) GROUP BY marketGroupID", [parentGroupIDs componentsJoinedByString:@","]];
			[parentGroupIDs removeAllObjects];
			
			[database execSQLRequest:request resultBlock:^(sqlite3_stmt *stmt, BOOL *needsMore) {
				EVEDBInvMarketGroup* marketGroup = [[EVEDBInvMarketGroup alloc] initWithStatement:stmt];
				marketGroupsMap[@(marketGroup.marketGroupID)] = marketGroup;
				
				if (marketGroup.parentGroupID && !marketGroupsMap[@(marketGroup.parentGroupID)])
					[parentGroupIDs addObject:[NSString stringWithFormat:@"%d", marketGroup.parentGroupID]];
			}];
		}
		
		[marketGroupsMap enumerateKeysAndObjectsUsingBlock:^(id key, EVEDBInvMarketGroup* marketGroup, BOOL *stop) {
			if (marketGroup.parentGroupID) {
				EVEDBInvMarketGroup* parentGroup = marketGroupsMap[@(marketGroup.parentGroupID)];
				[parentGroup.subgroups addObject:marketGroup];
			}
			else
				[lastGroups addObject:marketGroup];
		}];
		
		while(lastGroups.count == 1) {
			EVEDBInvMarketGroup* parentGroup = lastGroups[0];
			if (parentGroup.subgroups.count == 0)
				break;
			lastGroups = parentGroup.subgroups;
		}
		_groups = lastGroups;
		
		[marketGroupsMap enumerateKeysAndObjectsUsingBlock:^(id key, EVEDBInvMarketGroup* marketGroup, BOOL *stop) {
			[marketGroup.subgroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]]];
		}];
		[lastGroups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"marketGroupName" ascending:YES]]];


	}
	return _groups;
}

@end
