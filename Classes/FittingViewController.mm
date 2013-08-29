//
//  FittingViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FittingViewController.h"
#import "Globals.h"
#import "EVEAccount.h"
#import "ShipFit.h"
#import "ItemInfo.h"
#import "DamagePattern.h"
#import "RequiredSkillsViewController.h"
#import "PriceManager.h"
#import "UIActionSheet+Block.h"
#import "ItemViewController.h"
#import "appearance.h"
#import "UIViewController+Neocom.h"

#include "eufe.h"

#define ActionButtonBack NSLocalizedString(@"Back", nil)
#define ActionButtonSetName NSLocalizedString(@"Set Fit Name", nil)
#define ActionButtonSave NSLocalizedString(@"Save Fit", nil)
#define ActionButtonCharacter NSLocalizedString(@"Switch Character", nil)
#define ActionButtonViewInBrowser NSLocalizedString(@"View in Browser", nil)
#define ActionButtonAreaEffect NSLocalizedString(@"Select Area Effect", nil)
#define ActionButtonClearAreaEffect NSLocalizedString(@"Clear Area Effect", nil)
#define ActionButtonSetDamagePattern NSLocalizedString(@"Set Damage Pattern", nil)
#define ActionButtonRequiredSkills NSLocalizedString(@"Required Skills", nil)
#define ActionButtonExport NSLocalizedString(@"Export", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDuplicate NSLocalizedString(@"Duplicate Fit", nil)
#define ActionButtonShowShipInfo NSLocalizedString(@"Ship Info", nil)

@interface FittingViewController()
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, readwrite) eufe::Engine* fittingEngine;
@property (nonatomic, strong, readwrite) NSMutableArray* fits;
@property (nonatomic, strong, readwrite) NCItemsViewController* itemsViewController;

- (void) save;
- (void) performExport;

@end

@implementation FittingViewController
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
	self.view.backgroundColor = [UIColor colorWithNumber:AppearanceBackgroundColor];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onBack:)];
	
	self.fitNameTextField.text = self.fit.fitName;
	self.damagePattern = [DamagePattern uniformDamagePattern];

	self.priceManager = [[PriceManager alloc] init];
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onMenu:)]];
	[self update];
	
	self.tableView.tableHeaderView = self.modulesDataSource.tableHeaderView;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self save];
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc {
	for (ShipFit* shipFit in self.fits)
		[shipFit unload];
	delete self.fittingEngine;
}

- (IBAction) didChangeSection:(id) sender {
	FittingDataSource* dataSources[] = {self.modulesDataSource, self.dronesDataSource, self.implantsDataSource, self.fleetDataSource, self.shipStatsDataSource};
	self.tableView.dataSource = dataSources[self.sectionSegmentControl.selectedSegmentIndex];
	self.tableView.delegate = dataSources[self.sectionSegmentControl.selectedSegmentIndex];
	self.tableView.tableHeaderView = dataSources[self.sectionSegmentControl.selectedSegmentIndex].tableHeaderView;
	[dataSources[self.sectionSegmentControl.selectedSegmentIndex] reload];
}

- (IBAction) onMenu:(id) sender {
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	void (^clearAreaEffect)() = ^() {
		self.fittingEngine->clearArea();
		[self update];
	};
	
	void (^shipInfo)() = ^() {
		ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:self.fit.character->getShip() error:nil];
		ItemViewController *itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		
		[itemInfo updateAttributes];
		itemViewController.type = itemInfo;
		[itemViewController setActivePage:ItemViewControllerActivePageInfo];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemViewController];
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navController animated:YES completion:nil];
		}
		else
			[self.navigationController pushViewController:itemViewController animated:YES];
	};
	
	void (^rename)() = ^() {
		self.fitNameTextField.text = self.fit.fitName;
		self.navigationItem.titleView = self.fitNameTextField;
		[self.fitNameTextField becomeFirstResponder];
	};
	
	void (^save)() = ^() {
		[self.fit save];
	};

	void (^duplicate)() = ^() {
		ShipFit* shipFit = [[ShipFit alloc] initWithEntity:[NSEntityDescription entityForName:@"ShipFit" inManagedObjectContext:self.fit.managedObjectContext] insertIntoManagedObjectContext:self.fit.managedObjectContext];
		shipFit.typeID = self.fit.typeID;
		shipFit.typeName = self.fit.typeName;
		shipFit.imageName = self.fit.imageName;
		shipFit.fitName = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), self.fit.fitName ? self.fit.fitName : @""];
		shipFit.character = self.fit.character;
		[self.fits replaceObjectAtIndex:[self.fits indexOfObject:self.fit] withObject:shipFit];
		self.fit = shipFit;
		self.fitNameTextField.text = shipFit.fitName;
		[self update];
	};
	
	void (^setCharacter)() = ^() {
		CharactersViewController *controller = [[CharactersViewController alloc] initWithNibName:@"CharactersViewController" bundle:nil];
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		
		controller.completionHandler = ^(id<Character> character) {
			eufe::Character* eufeCharacter = self.fit.character;
			eufeCharacter->setSkillLevels(*[character skillsMap]);
			eufeCharacter->setCharacterName([character.name cStringUsingEncoding:NSUTF8StringEncoding]);
			[self update];
		};
		
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navigationController animated:YES completion:nil];
	};

	void (^viewInBrowser)() = ^() {
		BrowserViewController *controller = [[BrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
		//controller.delegate = self;
		controller.startPageURL = [NSURL URLWithString:self.fit.url];
		[self presentViewController:controller animated:YES completion:nil];
	};

	void (^setAreaEffect)() = ^() {
		AreaEffectsViewController* controller = [[AreaEffectsViewController alloc] initWithNibName:@"AreaEffectsViewController" bundle:nil];
		controller.delegate = self;
		eufe::Item* area = self.fittingEngine->getArea();
		controller.selectedArea = area != NULL ? [ItemInfo itemInfoWithItem:area error:nil] : nil;

		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			[self presentViewControllerInPopover:navigationController fromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		else {
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
			[self presentViewController:navigationController animated:YES completion:nil];
		}
		

	};

	void (^setDamagePattern)() = ^() {
		DamagePatternsViewController *damagePatternsViewController = [[DamagePatternsViewController alloc] initWithNibName:@"DamagePatternsViewController" bundle:nil];
		damagePatternsViewController.delegate = self;
		damagePatternsViewController.currentDamagePattern = self.damagePattern;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:damagePatternsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentViewController:navController animated:YES completion:nil];
	};

	void (^requiredSkills)() = ^() {
		RequiredSkillsViewController *requiredSkillsViewController = [[RequiredSkillsViewController alloc] initWithNibName:@"RequiredSkillsViewController" bundle:nil];
		requiredSkillsViewController.fit = self.fit;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:requiredSkillsViewController];
		navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			navController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentViewController:navController animated:YES completion:nil];
	};

	void (^exportFit)() = ^() {
		[self performExport];
	};

	if (self.fittingEngine->getArea() != NULL)
		[actions addObject:clearAreaEffect];

	[actions addObject:shipInfo];
	[buttons addObject:ActionButtonShowShipInfo];
	
	[actions addObject:rename];
	[buttons addObject:ActionButtonSetName];

	if (!self.fit.managedObjectContext) {
		[actions addObject:save];
		[buttons addObject:ActionButtonSave];
	}
	else {
		[actions addObject:duplicate];
		[buttons addObject:ActionButtonDuplicate];
	}

	[actions addObject:setCharacter];
	[buttons addObject:ActionButtonCharacter];

	if (self.fit.url) {
		[actions addObject:viewInBrowser];
		[buttons addObject:ActionButtonViewInBrowser];
	}

	[actions addObject:setAreaEffect];
	[buttons addObject:ActionButtonAreaEffect];

	[actions addObject:setDamagePattern];
	[buttons addObject:ActionButtonSetDamagePattern];

	[actions addObject:requiredSkills];
	[buttons addObject:ActionButtonRequiredSkills];

	[actions addObject:exportFit];
	[buttons addObject:ActionButtonExport];

	if (self.actionSheet) {
		[self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
		self.actionSheet = nil;
	}
	
	
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:nil
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:self.fittingEngine->getArea() != NULL ? ActionButtonClearAreaEffect : nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
												   void (^action)() = actions[selectedButtonIndex];
												   action();
											   }
											   self.actionSheet = nil;
										   } cancelBlock:nil];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction) onDone:(id) sender {
	[self.fitNameTextField resignFirstResponder];
	self.fit.fitName = self.fitNameTextField.text;
	
	eufe::Character* character = self.fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, self.fit.fitName ? self.fit.fitName : itemInfo.typeName];
	
	if (self.tableView.dataSource == self.fleetDataSource)
		[self.fleetDataSource reload];
}

- (IBAction) onBack:(id) sender {
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
}

- (eufe::Engine*) fittingEngine {
	if (!_fittingEngine)
		_fittingEngine = new eufe::Engine(new eufe::SqliteConnector([[[NSBundle mainBundle] pathForResource:@"eufe" ofType:@"sqlite"] cStringUsingEncoding:NSUTF8StringEncoding]));
	return _fittingEngine;
}

- (NSMutableArray*) fits {
	if (!_fits)
		_fits = [[NSMutableArray alloc] init];
	return _fits;
}

- (void) update {
	[(FittingDataSource*) self.tableView.dataSource reload];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.shipStatsDataSource reload];
}

- (void) setFit:(ShipFit*) value {
	_fit = value;
	eufe::Character* character = _fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, _fit.fitName ? _fit.fitName : itemInfo.typeName];
	self.fitNameTextField.text = _fit.fitName;
}

- (void) setDamagePattern:(DamagePattern *)value {
	_damagePattern = value;
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = _damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = _damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = _damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = _damagePattern.explosiveAmount;
	for (ShipFit* item in self.fits) {
		eufe::Character* character = item.character;
		character->getShip()->setDamagePattern(eufeDamagePattern);
	}
}

- (NCItemsViewController*) itemsViewController {
	if (!_itemsViewController) {
		_itemsViewController = [[NCItemsViewController alloc] init];
	}
	return _itemsViewController;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	self.fit.fitName = self.fitNameTextField.text;
	
	eufe::Character* character = self.fit.character;
	ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:character->getShip() error:nil];
	self.navigationItem.titleView = nil;
	self.title = [NSString stringWithFormat:@"%@ - %@", itemInfo.typeName, self.fit.fitName ? self.fit.fitName : itemInfo.typeName];

	[self update];
	return YES;
}

#pragma mark BrowserViewControllerDelegate

- (void) browserViewControllerDidFinish:(BrowserViewController*) controller {
	[self dismiss];
}

#pragma mark AreaEffectsViewControllerDelegate

- (void) areaEffectsViewController:(AreaEffectsViewController*) controller didSelectAreaEffect:(EVEDBInvType*) areaEffect {
	self.fittingEngine->setArea(areaEffect.typeID);
	[self update];
	[self dismiss];
}

#pragma mark DamagePatternsViewControllerDelegate

- (void) damagePatternsViewController:(DamagePatternsViewController*) controller didSelectDamagePattern:(DamagePattern*) aDamagePattern {
	self.damagePattern = aDamagePattern;
	[self update];
	[self dismiss];
}

#pragma mark FitsViewControllerDelegate

- (void) fitsViewController:(FitsViewController*) aController didSelectFit:(ShipFit*) aFit {
	eufe::Character* character = aFit.character;
	self.fittingEngine->getGang()->addPilot(character);
	[self.fits addObject:aFit];
	
	eufe::DamagePattern eufeDamagePattern;
	eufeDamagePattern.emAmount = self.damagePattern.emAmount;
	eufeDamagePattern.thermalAmount = self.damagePattern.thermalAmount;
	eufeDamagePattern.kineticAmount = self.damagePattern.kineticAmount;
	eufeDamagePattern.explosiveAmount = self.damagePattern.explosiveAmount;
	character->getShip()->setDamagePattern(eufeDamagePattern);
	
	[self dismiss];
	[self update];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismiss];
}

#pragma mark - Private

- (void) save {
	self.fit.fitName = self.fitNameTextField.text;
	
	for (Fit* item in self.fits)
		if (item.managedObjectContext)
			[item save];
}

- (void) performExport {
	NSString* xml = [self.fit eveXML];
	NSString* dna = [self.fit dna];

	NSString* name;
	
	if (self.fit.fitName.length > 0)
		name = self.fit.fitName;
	else {
		eufe::Character* character = self.fit.character;
		eufe::Ship* ship = character->getShip();
		name = [[ItemInfo itemInfoWithItem:ship error:nil] typeName];
	}
	NSString* link = [NSString stringWithFormat:@"<a href=\"javascript:if (typeof CCPEVE != 'undefined') CCPEVE.showFitting('%@'); else window.open('fitting:%@');\">%@</a>", dna, dna, name];
	
	NSMutableArray* buttons = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Clipboard EVE XML", nil), NSLocalizedString(@"Clipboard DNA", nil), nil];
	if ([MFMailComposeViewController canSendMail])
		[buttons addObject:NSLocalizedString(@"Email", nil)];
	self.actionSheet = [UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackOpaque
													 title:NSLocalizedString(@"Export", nil)
										 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
									destructiveButtonTitle:nil
										 otherButtonTitles:buttons
										   completionBlock:^(UIActionSheet *aActionSheet, NSInteger selectedButtonIndex) {
											   if (selectedButtonIndex == aActionSheet.cancelButtonIndex)
												   return;
											   
											   
											   if (selectedButtonIndex == 0) {
												   [[UIPasteboard generalPasteboard] setString:xml];
											   }
											   else if (selectedButtonIndex == 1) {
												   [[UIPasteboard generalPasteboard] setString:link];
											   }
											   else if (selectedButtonIndex == 2) {
												   MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
												   controller.mailComposeDelegate = self;
												   [controller setMessageBody:link isHTML:YES];
												   [controller setSubject:name];
												   [controller addAttachmentData:[xml dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/xml" fileName:[NSString stringWithFormat:@"%@.xml", name]];
												   [self presentViewController:controller animated:YES completion:nil];
											   }
										   }
											   cancelBlock:nil];
	
	[self.actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

@end