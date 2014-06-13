//
//  NCDBEveIconImage.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBEveIcon;

@interface NCDBEveIconImage : NSManagedObject

@property (nonatomic, retain) id image;
@property (nonatomic, retain) NCDBEveIcon *icon;

@end
