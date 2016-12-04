//
//  EVECharacterSheet+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 22.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <EVEAPI/EVEAPI.h>

@interface EVECharacterSheet (NC)
@property (nonatomic, readonly) NSDate* nextRespecDate;
@end
