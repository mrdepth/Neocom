//
//  NAPIValuesViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 19.06.13.
//
//

#import <UIKit/UIKit.h>

@interface NAPIValuesViewController : UITableViewController
@property (nonatomic, strong) NSArray* values;
@property (nonatomic, strong) NSArray* titles;
@property (nonatomic, strong) NSArray* icons;
@property (nonatomic, strong) NSNumber* selectedValue;
@property (nonatomic, copy) void (^completionHandler)(NSValue* value);


@end
