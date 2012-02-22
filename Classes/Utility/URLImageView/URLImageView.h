//
//  URLImageView.h
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URLImageViewManager.h"

@class URLImageView;
@protocol URLImageViewDelegate

- (void) imageView: (URLImageView*) imageView didReceiveImage: (UIImage*) image;
- (void) imageView: (URLImageView*) imageView didFailWithError: (NSError*) error;

@end


@interface URLImageView : UIImageView<URLImageViewManagerDelegate> {
	NSObject<URLImageViewDelegate> *_delegate;
	NSURL *_url;
	BOOL _isLoading;
	UIActivityIndicatorView *_activityIndicatorView;
	float _scale;
}

@property (nonatomic, assign) IBOutlet NSObject<URLImageViewDelegate> *delegate;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicatorView;

- (void) setImageWithContentsOfURL: (NSURL*) url;
- (void) setImageWithContentsOfURL: (NSURL*) url scale: (float) scale;

@end
