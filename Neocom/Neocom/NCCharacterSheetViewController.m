//
//  NCCharacterSheetViewController.m
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCCharacterSheetViewController.h"
#import "NCProgressHandler.h"
#import "NCDataManager.h"
#import "NCManagedObjectObserver.h"
#import "NCTableViewHeaderCell.h"
#import "NCDefaultTableViewCell.h"

@interface NCCharacterSheetViewControllerRow : NSObject
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, strong) void (^configurationBlock) (__kindof UITableViewCell* cell);
@end

@implementation NCCharacterSheetViewControllerRow

- (instancetype) initWithCellIdentifier:(NSString*) cellIdentifier configurationBlock:(void(^)(__kindof UITableViewCell* cell)) block {
	if (self = [super init]) {
		self.cellIdentifier = cellIdentifier;
		self.configurationBlock = block;
	}
	return self;
}

@end

@interface NCCharacterSheetViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray<NCCharacterSheetViewControllerRow*>* rows;
@end

@implementation NCCharacterSheetViewControllerSection

- (instancetype) initWithTitle:(NSString*) title rows:(NSArray<NCCharacterSheetViewControllerRow*>*) rows {
	if (self = [super init]) {
		self.title = title;
		self.rows = rows;
	}
	return self;
}

@end

@interface NCCharacterSheetViewController ()
@property (nonatomic, strong) NCManagedObjectObserver* observer;
@property (nonatomic, strong) EVECharacterSheet* characterSheet;
@property (nonatomic, strong) UIImage* characterImage;
@property (nonatomic, strong) UIImage* corporationImage;	
@property (nonatomic, strong) UIImage* allianceImage;
@property (nonatomic, strong) NSArray<NCCharacterSheetViewControllerSection*>* sections;
@end

@implementation NCCharacterSheetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.estimatedRowHeight = self.tableView.rowHeight;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.refreshControl = [UIRefreshControl new];
	[self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
	
	[self reloadWithCachePolicy:NSURLRequestUseProtocolCachePolicy];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASTreeControllerDelegate

- (nonnull id)treeController:(nonnull ASTreeController *)treeController child:(NSInteger)index ofItem:(nullable id)item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]]) {
		return [(NCCharacterSheetViewControllerSection*) item rows][index];
	}
	else
		return self.sections[index];
}

- (NSInteger) treeController:(nonnull ASTreeController *)treeController numberOfChildrenOfItem:(nullable id)item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]])
		return [(NCCharacterSheetViewControllerSection*) item rows].count;
	else if (!item)
		return self.sections.count;
	else
		return 0;
}

- (nonnull NSString*) treeController:(nonnull ASTreeController *)treeController cellIdentifierForItem:(nonnull id) item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]])
		return @"NCTableViewHeaderCell";
	else if ([item isKindOfClass:[NCCharacterSheetViewControllerRow class]])
		return [(NCCharacterSheetViewControllerRow*) item cellIdentifier];
	else
		return nil;
}

- (void) treeController:(nonnull ASTreeController *)treeController configureCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id) item {
	if ([item isKindOfClass:[NCCharacterSheetViewControllerSection class]]) {
		NCTableViewHeaderCell* tableHeaderCell = (NCTableViewHeaderCell*) cell;
		tableHeaderCell.titleLabel.text = [(NCCharacterSheetViewControllerSection*) item title];
	}
	else {
		[(NCCharacterSheetViewControllerRow*) item configurationBlock](cell);
	}
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpandable:(nonnull id)item {
	return [item isKindOfClass:[NCCharacterSheetViewControllerSection class]];
}

- (BOOL) treeController:(nonnull ASTreeController *)treeController isItemExpanded:(nonnull id)item {
	return YES;
}

- (void) treeController:(nonnull ASTreeController *)treeController didSelectCell:(nonnull __kindof UITableViewCell*) cell withItem:(nonnull id)item {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
}


#pragma mark - Private

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	NCProgressHandler* progressHandler = [NCProgressHandler progressHandlerForViewController:self withTotalUnitCount:1];
	
	NCAccount* account = NCAccount.currentAccount;
	NCDataManager* dataManager = [NCDataManager defaultManager];
	
	//[progressHandler.progress becomeCurrentWithPendingUnitCount:1];
	[dataManager characterSheetForAccount:account cachePolicy:cachePolicy completionHandler:^(EVECharacterSheet *result, NSError *error, NSManagedObjectID *cacheRecordID) {
		self.characterSheet = result;
		[self reloadImagesWithCachePolicy:cachePolicy];
		__weak typeof(self) weakSelf = self;
		self.observer = [NCManagedObjectObserver observerWithObjectID:cacheRecordID block:^(NCManagedObjectObserverAction action) {
			if (action == NCManagedObjectObserverActionUpdate) {
				NCCacheRecord* record = [NCCache.sharedCache.viewContext existingObjectWithID:cacheRecordID error:nil];
				if (record.object) {
					weakSelf.characterSheet = record.object;
					[self reloadImagesWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
					[self reloadSections];
					[weakSelf.treeController reloadData];
				}
			}
		}];
		[self reloadSections];
		[progressHandler finish];
		[self.refreshControl endRefreshing];
	}];
	//[progressHandler.progress resignCurrent];
}

- (IBAction)onRefresh:(id)sender {
	[self reloadWithCachePolicy:NSURLRequestReloadIgnoringCacheData];
}

- (void) reloadImagesWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	if (!self.characterSheet)
		return;
	
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:self.characterSheet.allianceID ? 3 : 2];
	NCDataManager* dataManager = [NCDataManager defaultManager];
	[progress becomeCurrentWithPendingUnitCount:progress.totalUnitCount];
	[dataManager imageWithCharacterID:self.characterSheet.characterID preferredSize:CGSizeMake(512, 512) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
		self.characterImage = image;
		[self.tableView reloadData];
	}];
	
	[dataManager imageWithCorporationID:self.characterSheet.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
		self.corporationImage = image;
		[self.tableView reloadData];
	}];
	
	if (self.characterSheet.allianceID)
		[dataManager imageWithCorporationID:self.characterSheet.corporationID preferredSize:CGSizeMake(32, 32) scale:UIScreen.mainScreen.scale cachePolicy:cachePolicy completionBlock:^(UIImage *image, NSError *error) {
			self.allianceImage = image;
			[self.tableView reloadData];
		}];
	[progress resignCurrent];
}

- (void) reloadSections {
	if (!self.characterSheet) {
		self.sections = nil;
	}
	else {
		NSMutableArray* sections = [NSMutableArray new];
		NSMutableArray* rows = [NSMutableArray new];
		__weak typeof(self) weakSelf = self;
		
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"PortraitCell" configurationBlock:^(NCDefaultTableViewCell* cell) {
			cell.iconView.image = weakSelf.characterImage;
		}]];
		
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"CORPORATION", nil);
			cell.subtitleLabel.text = weakSelf.characterSheet.corporationName;
			cell.iconView.image = weakSelf.corporationImage;
		}]];
		
		if (self.characterSheet.allianceID)
			[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
				cell.titleLabel.text = NSLocalizedString(@"ALLIANCE", nil);
				cell.subtitleLabel.text = weakSelf.characterSheet.allianceName;
				cell.iconView.image = weakSelf.allianceImage;
			}]];
		
		[rows addObject:[[NCCharacterSheetViewControllerRow alloc] initWithCellIdentifier:@"Cell" configurationBlock:^(__kindof NCDefaultTableViewCell *cell) {
			cell.titleLabel.text = NSLocalizedString(@"DATE OF BIRTH", nil);
			cell.subtitleLabel.text = [NSDateFormatter localizedStringFromDate:weakSelf.characterSheet.DoB dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
			cell.iconView.image = nil;
		}]];
		
		[sections addObject:[[NCCharacterSheetViewControllerSection alloc] initWithTitle:NSLocalizedString(@"BIO", nil) rows:rows]];
		self.sections = sections;
	}
	[self.treeController reloadData];
}

@end
