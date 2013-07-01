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
@property (nonatomic, strong) NSString * boosters;
@property (nonatomic, strong) NSString * drones;
@property (nonatomic, strong) NSString * implants;
@property (nonatomic, strong) NSString * hiSlots;
@property (nonatomic, strong) NSString * medSlots;
@property (nonatomic, strong) NSString * lowSlots;
@property (nonatomic, strong) NSString * rigSlots;
@property (nonatomic, strong) NSString * subsystems;
@property (nonatomic, strong) NSString * cargo;

+ (id) shipFitWithFitName:(NSString*) fitName character:(eufe::Character*) character;
+ (id) shipFitWithBCString:(NSString*) string character:(eufe::Character*) character;
+ (id) shipFitWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
+ (id) shipFitWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
+ (id) shipFitWithDNA:(NSString*) dna character:(eufe::Character*) character;
+ (id) shipFitWithCanonicalName:(NSString*) canonicalName character:(eufe::Character*) character;

+ (NSArray*) allFits;
+ (NSString*) allFitsEveXML;

- (id) initWithFitName:(NSString*) aFitName character:(eufe::Character*) aCharacter;
- (id) initWithCharacter:(eufe::Character*) character;
- (id) initWithBCString:(NSString*) string character:(eufe::Character*) character;
- (id) initWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
- (id) initWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
- (id) initWithDNA:(NSString*) dna character:(eufe::Character*) character;
- (id) initWithCanonicalName:(NSString*) canonicalName character:(eufe::Character*) character;
- (NSString*) dna;
- (NSString*) eveXML;
- (NSString*) fitXML;
- (NSString*) canonicalName;


@end
