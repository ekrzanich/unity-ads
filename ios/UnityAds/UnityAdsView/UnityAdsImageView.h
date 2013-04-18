//
//  UnityAdsImageView.h
//  UnityAds
//
//  Created by Pekka Palmu on 4/17/13.
//  Copyright (c) 2013 Unity Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UnityAdsImageView : UIImageView <NSURLConnectionDelegate>
- (void)loadImageFromURL:(NSURL*)url applyScaling:(BOOL)runScaling;
@end
