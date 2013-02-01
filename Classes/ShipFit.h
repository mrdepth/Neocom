//
//  ShipFit.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 28.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Fit.h"

@class EVEAssetListItem;
@class KillMail;
@class EVEDBInvType;

@interface ShipFit : Fit

@property (nonatomic, assign) eufe::Character* character;

//CoreData
@property (nonatomic, retain) NSString * boosters;
@property (nonatomic, retain) NSString * drones;
@property (nonatomic, retain) NSString * implants;
@property (nonatomic, retain) NSString * hiSlots;
@property (nonatomic, retain) NSString * medSlots;
@property (nonatomic, retain) NSString * lowSlots;
@property (nonatomic, retain) NSString * rigSlots;
@property (nonatomic, retain) NSString * subsystems;
@property (nonatomic, retain) NSString * cargo;

+ (id) shipFitWithFitName:(NSString*) fitName character:(eufe::Character*) character;
+ (id) shipFitWithBCString:(NSString*) string character:(eufe::Character*) character;
+ (id) shipFitWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
+ (id) shipFitWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
+ (id) shipFitWithDNA:(NSString*) dna character:(eufe::Character*) character;

+ (NSArray*) allFits;
+ (NSString*) allFitsEveXML;

- (id) initWithFitName:(NSString*) aFitName character:(eufe::Character*) aCharacter;
- (id) initWithCharacter:(eufe::Character*) character;
- (id) initWithBCString:(NSString*) string character:(eufe::Character*) character;
- (id) initWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
- (id) initWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
- (id) initWithDNA:(NSString*) dna character:(eufe::Character*) character;
- (NSString*) dna;
- (NSString*) eveXML;
- (NSString*) fitXML;


@end
