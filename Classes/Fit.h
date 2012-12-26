//
//  Fit.h
//  EVEUniverse
//
//  Created by Mr. Depth on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "eufe.h"

@class EVEAssetListItem;
@class KillMail;
@interface Fit : NSObject {
	NSString* fitID;
	NSString* fitName;
	NSURL* fitURL;
	eufe::Character* character;
}

+ (id) fitWithFitID:(NSString*) fitID fitName:(NSString*) fitName character:(eufe::Character*) character;
+ (id) fitWithDictionary:(NSDictionary*) dictionary character:(eufe::Character*) character;
+ (id) fitWithCharacter:(eufe::Character*) character error:(NSError **)errorPtr;
+ (id) fitWithBCString:(NSString*) string character:(eufe::Character*) character;
+ (id) fitWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
+ (id) fitWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
+ (id) fitWithDNA:(NSString*) dna character:(eufe::Character*) character;

+ (NSString*) allFitsEveXML;

- (id) initWithFitID:(NSString*) aFitID fitName:(NSString*) aFitName character:(eufe::Character*) aCharacter;
- (id) initWithDictionary:(NSDictionary*) dictionary character:(eufe::Character*) aCharacter;
- (id) initWithCharacter:(eufe::Character*) character error:(NSError **)errorPtr;
- (id) initWithBCString:(NSString*) string character:(eufe::Character*) character;
- (id) initWithAsset:(EVEAssetListItem*) asset character:(eufe::Character*) character;
- (id) initWithKillMail:(KillMail*) killMail character:(eufe::Character*) character;
- (id) initWithDNA:(NSString*) dna character:(eufe::Character*) character;
- (NSDictionary*) dictionary;
- (NSString*) dna;
- (NSString*) eveXML;

@property (nonatomic, copy) NSString* fitID;
@property (nonatomic, copy) NSString* fitName;
@property (nonatomic, readonly) eufe::Character* character;
@property (nonatomic, retain) NSURL* fitURL;

- (void) save;

@end
