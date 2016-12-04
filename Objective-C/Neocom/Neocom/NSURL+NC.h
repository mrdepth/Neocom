//
//  NSURL+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (NC)
@property (nonatomic, readonly) NSDictionary<NSString*, NSString*>* parameters;
@end
