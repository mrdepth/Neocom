//
//  NCIncursionsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 05.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCIncursionsViewController.h"
#import "NCIncursionCell.h"
#import "UIImageView+URL.h"
#import "UIColor+Neocom.h"

@interface NCIncursionsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSArray* incursions;
@property (nonatomic, strong) NSDictionary* solarSystems;
@end

@implementation NCIncursionsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		self.incursions = [aDecoder decodeObjectForKey:@"incursions"];
		self.solarSystems = [aDecoder decodeObjectForKey:@"solarSystems"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.incursions forKey:@"incursions"];
	[aCoder encodeObject:self.solarSystems forKey:@"solarSystems"];
}

@end

@implementation NCIncursionsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.cacheRecordID = NSStringFromClass(self.class);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NCIncursionsViewControllerData* data = self.cacheData;
	return data ? 1 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NCIncursionsViewControllerData* data = self.cacheData;
	return data.incursions.count;
}

#pragma mark - NCTableViewController

- (void) loadCacheData:(id)cacheData withCompletionBlock:(void (^)())completionBlock {
	NCIncursionsViewControllerData* data = cacheData;
	self.backgrountText = data.incursions > 0 ? nil : NSLocalizedString(@"No Results", nil);
	completionBlock();
}

- (void) downloadDataWithCachePolicy:(NSURLRequestCachePolicy)cachePolicy completionBlock:(void (^)(NSError *))completionBlock {
	__block NSError* lastError = nil;
	NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
	
	dispatch_group_t finishGroup = dispatch_group_create();
	dispatch_group_enter(finishGroup);
	NCIncursionsViewControllerData* data = [NCIncursionsViewControllerData new];

	CRAPI* api = [CRAPI publicApiWithCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[api loadIncursionsWithCompletionBlock:^(CRIncursionCollection *incursions, NSError *error) {
		progress.completedUnitCount++;

		data.incursions = [incursions.items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"constellationName" ascending:YES]]];
		
		if (error)
			lastError = error;
		NSMutableDictionary* solarSystems = [NSMutableDictionary new];
		data.solarSystems = solarSystems;
		[progress becomeCurrentWithPendingUnitCount:1];
		NSProgress* subprogress = [NSProgress progressWithTotalUnitCount:incursions.items.count];
		[progress resignCurrent];
		for (CRIncursion* incursion in incursions.items) {
			dispatch_group_enter(finishGroup);
			[api loadSolarSystemWithSolarSystemID:incursion.solarSystemID completionBlock:^(CRSolarSystem *solarSystem, NSError *error) {
				@synchronized(solarSystems) {
					solarSystems[@(incursion.solarSystemID)] = solarSystem;
					subprogress.completedUnitCount++;
				}
				dispatch_group_leave(finishGroup);
			}];
		}
		dispatch_group_leave(finishGroup);
	}];
	
	dispatch_group_notify(finishGroup, dispatch_get_main_queue(), ^{
		[self saveCacheData:data cacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:NCCacheDefaultExpireTime]];
		completionBlock(lastError);
	});
	
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCIncursionsViewControllerData* data = self.cacheData;
	NCIncursionCell* cell = (NCIncursionCell*) tableViewCell;
	CRIncursion* incursion = data.incursions[indexPath.row];
	CRSolarSystem* solarSystem = data.solarSystems[@(incursion.solarSystemID)];
	
	cell.constellationLabel.text = incursion.constellationName;
	switch (incursion.state) {
		case CRIncursionStateMobilizing:
			cell.stateLabel.text = NSLocalizedString(@"INCURSION MOBILIZING", nil);
			break;
		case CRIncursionStateEstablished:
			cell.stateLabel.text = NSLocalizedString(@"INCURSION ESTABLISHED", nil);
			break;
		case CRIncursionStateWithdrawing:
			cell.stateLabel.text = NSLocalizedString(@"INCURSION WITHDRAWING", nil);
			break;
		default:
			cell.stateLabel.text = NSLocalizedString(@"INCURSION UNKNOWN STATE", nil);
			break;
	}
	
	NSString* ss = [NSString stringWithFormat:@"%.1f", solarSystem.securityStatus];
	NSString* s = [NSString stringWithFormat:@"%@ %@", ss, solarSystem.name];
	NSMutableAttributedString* ms = [[NSMutableAttributedString alloc] initWithString:s];
	[ms addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithSecurity:solarSystem.securityStatus] range:NSMakeRange(0, ss.length)];
	cell.solarSystemLabel.attributedText = ms;
	
	cell.hasBossImageView.alpha = incursion.hasBoss ? 1.0f : 0.3f;
	cell.ownerNameLabel.text = solarSystem.ownerName;
	cell.ownerImageView.image = nil;
	cell.influenceLabel.text = [NSString stringWithFormat:@"%.0f%%", incursion.influence * 100];
	cell.influenceLabel.progress = incursion.influence;
	[cell.ownerImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:solarSystem.ownerID size:EVEImageSizeRetina64 error:nil]];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
