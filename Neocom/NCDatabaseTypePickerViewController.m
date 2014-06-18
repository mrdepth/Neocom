//
//  NCDatabaseTypePickerViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypePickerViewController.h"
#import "UIViewController+Neocom.h"
#import "EVEDBAPI.h"
#import <objc/runtime.h>
#import "NSString+MD5.h"
#import "NCDatabase.h"

@interface EVEDBInvMarketGroup (NCDatabaseTypePickerViewController)
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

@interface NCDatabaseTypePickerViewController ()
@property (nonatomic, strong) NSArray* conditions;
@property (nonatomic, copy) void (^completionHandler)(NCDBInvType* type);
@property (nonatomic, strong) NSArray* groups;
@property (nonatomic, strong) NSSet* conditionsTables;
@property (nonatomic, strong) NSMutableDictionary* cache;
@property (nonatomic, strong) NCDBEufeItemCategory* category;

@end

@implementation NCDatabaseTypePickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.cache = [NSMutableDictionary new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	@synchronized(self) {
		[self.cache removeAllObjects];
	}
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.completionHandler = nil;
}

- (void) presentWithConditions:(NSArray*) conditions inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(EVEDBInvType* type)) completion {

	if (![self.conditions isEqualToArray:conditions]) {
		self.conditions = conditions;
		self.groups = nil;
		self.conditionsTables = nil;

		for (UIViewController* controller in self.viewControllers)
			if ([controller.searchDisplayController isActive])
				[controller.searchDisplayController setActive:NO animated:NO];

		if (self.viewControllers.count > 1)
			[self setViewControllers:@[[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerContentViewController"]] animated:NO];
		
		[self.viewControllers[0] setGroups:nil];
		[self.viewControllers[0] setGroupID:0];
	}
	[self.viewControllers[0] setTitle:self.title];
	
//	self.completionHandler = completion;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[controller presentViewControllerInPopover:self fromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
	else {
		[[self.viewControllers[0] navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)]];
		[controller presentViewController:self animated:animated completion:nil];
	}
}

- (void) presentWithCategory:(NCDBEufeItemCategory*) category inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(NCDBInvType* type)) completion {
	if (![self.category isEqual:category]) {
		self.category = category;
		for (UIViewController* controller in self.viewControllers)
			if ([controller.searchDisplayController isActive])
				[controller.searchDisplayController setActive:NO animated:NO];
		
		if (self.viewControllers.count > 1)
			[self setViewControllers:@[[self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerContentViewController"]] animated:NO];
	}
	[self.viewControllers[0] setTitle:self.title];
	
	self.completionHandler = completion;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[controller presentViewControllerInPopover:self fromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
	else {
		[[self.viewControllers[0] navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:controller action:@selector(dismissAnimated)]];
		[controller presentViewController:self animated:animated completion:nil];
	}
}


- (void) setTitle:(NSString *)title {
	[super setTitle:title];
	if (self.viewControllers.count > 0)
		[self.viewControllers[0] setTitle:self.title];
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
		//NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invMarketGroups.marketGroupID=invTypes.marketGroupID", @"invTypes.published=1", nil];
		NSMutableArray* allConditions = [[NSMutableArray alloc] initWithObjects:@"invTypes.published=1", nil];
		
		[allTables unionSet:self.conditionsTables];
		[allConditions addObjectsFromArray:self.conditions];
		
		NSString* request = [NSString stringWithFormat:@"SELECT invMarketGroups.* FROM invMarketGroups WHERE marketGroupID IN \
							 (SELECT invTypes.marketGroupID FROM %@ WHERE %@ GROUP BY invTypes.marketGroupID)",
							 [[allTables allObjects] componentsJoinedByString:@","], [allConditions componentsJoinedByString:@" AND "]];
		
		id key = [request md5];
		@synchronized(self) {
			_groups = self.cache[key];
		}

		if (!_groups) {
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
			
			@synchronized(self) {
				_cache[key] = _groups;
			}
		}
	}
	return _groups;
}

@end
