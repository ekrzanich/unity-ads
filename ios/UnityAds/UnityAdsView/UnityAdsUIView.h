//
//  UnityAdsUIView.h
//  UnityAds
//
//  Created by Pekka Palmu on 4/15/13.
//  Copyright (c) 2013 Unity Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UnityAdsUIView : UIView
  @property (nonatomic, assign) BOOL drawSpinner;
  @property (nonatomic, strong) UIView *spinner;
@end
