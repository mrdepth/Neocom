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
@interface Fit : NSObject {
	NSInteger fitID;
	NSString* fitName;
	NSURL* fitURL;
	boost::weak_ptr<eufe::Character> character;
}

+ (id) fitWithFitID:(NSInteger) fitID fitName:(NSString*) fitName character:(boost::shared_ptr<eufe::Character>) character;
+ (id) fitWithDictionary:(NSDictionary*) dictionary character:(boost::shared_ptr<eufe::Character>) character;
+ (id) fitWithCharacter:(boost::shared_ptr<eufe::Character>) character error:(NSError **)errorPtr;
+ (id) fitWithBCString:(NSString*) string character:(boost::shared_ptr<eufe::Character>) character;
+ (id) fitWithAsset:(EVEAssetListItem*) asset character:(boost::shared_ptr<eufe::Character>) character;

- (id) initWithFitID:(NSInteger) aFitID fitName:(NSString*) aFitName character:(boost::shared_ptr<eufe::Character>) aCharacter;
- (id) initWithDictionary:(NSDictionary*) dictionary character:(boost::shared_ptr<eufe::Character>) aCharacter;
- (id) initWithCharacter:(boost::shared_ptr<eufe::Character>) character error:(NSError **)errorPtr;
- (id) initWithBCString:(NSString*) string character:(boost::shared_ptr<eufe::Character>) character;
- (id) initWithAsset:(EVEAssetListItem*) asset character:(boost::shared_ptr<eufe::Character>) character;
- (NSDictionary*) dictionary;

@property (nonatomic, assign) NSInteger fitID;
@property (nonatomic, copy) NSString* fitName;
@property (nonatomic, readonly) boost::shared_ptr<eufe::Character> character;
@property (nonatomic, retain) NSURL* fitURL;

- (void) save;

@end
