//
//  KillNetFiltersViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import <UIKit/UIKit.h>
#import "KillNetFilterDateViewController.h"
#import "KillNetFilterShipsViewController.h"
#import "KillNetFilterShipClassesViewController.h"
#import "KillNetFilterRegionsViewController.h"
#import "KillNetFilterSolarSystemsViewController.h"

typedef enum {
	KillNetFilterTypeStartDate,
	KillNetFilterTypeEndDate,
	KillNetFilterTypeSolarSystem,
	KillNetFilterTypeRegion,
	KillNetFilterTypeVictimPilot,
	KillNetFilterTypeVictimCorp,
	KillNetFilterTypeVictimAlliance,
	KillNetFilterTypeVictimShip,
	KillNetFilterTypeVictimShipClass,
	KillNetFilterTypeAttackerPilot,
	KillNetFilterTypeAttackerCorp,
	KillNetFilterTypeAttackerAlliance,
	KillNetFilterTypeAttackerShip,
	KillNetFilterTypeAttackerShipClass,
	KillNetFilterTypeCombinedPilot,
	KillNetFilterTypeCombinedCorp,
	KillNetFilterTypeCombinedAlliance,
	KillNetFilterTypeCombinedShip,
	KillNetFilterTypeCombinedShipClass
} KillNetFilterType;

@class KillNetFiltersViewController;
@protocol KillNetFiltersViewControllerDelegate <NSObject>

- (void) killNetFiltersViewController:(KillNetFiltersViewController*) controller didSelectFilter:(NSDictionary*) filter;

@end

@interface KillNetFiltersViewController : UIViewController<FittingItemsViewControllerDelegate, KillNetFilterDBViewControllerDelegate, KillNetFilterDateViewControllerDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) NSArray* usedFilters;
@property (nonatomic, assign) id<KillNetFiltersViewControllerDelegate> delegate;

@end
