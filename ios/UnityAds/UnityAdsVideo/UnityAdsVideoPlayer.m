//
//  UnityAdsVideo.m
//  UnityAds
//
//  Created by bluesun on 10/22/12.
//  Copyright (c) 2012 Unity Technologies. All rights reserved.
//

#import "UnityAdsVideoPlayer.h"
#import "../UnityAds.h"
#import "../UnityAdsCampaign/UnityAdsCampaign.h"
#import "../UnityAdsDevice/UnityAdsDevice.h"
#import "../UnityAdsData/UnityAdsAnalyticsUploader.h"
#import "../UnityAdsCampaign/UnityAdsCampaignManager.h"
#import "../UnityAdsWebView/UnityAdsWebAppController.h"

@interface UnityAdsVideoPlayer ()
  @property (nonatomic, assign) id timeObserver;
  @property (nonatomic, assign) id analyticsTimeObserver;
  @property (nonatomic) VideoAnalyticsPosition videoPosition;
@end

@implementation UnityAdsVideoPlayer

- (void)preparePlayer {
  [self _addObservers];
}

- (void)clearPlayer {
  [self _removeObservers];
}


#pragma mark Video Playback

- (void)playSelectedVideo {
  self.videoPosition = kVideoAnalyticsPositionUnplayed;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate videoPlaybackStarted];
  });
}

- (void)_videoPlaybackEnded:(NSNotification *)notification {
  UALOG_DEBUG(@"");
  if ([UnityAdsDevice isSimulator]) {
    self.videoPosition = kVideoAnalyticsPositionThirdQuartile;
  }
  
  [self _logVideoAnalytics];
  
  /*
;*/
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate videoPlaybackEnded];
  });
}


#pragma mark Video Observers

- (void)_addObservers {
  [self addObserver:self forKeyPath:@"self.currentItem.status" options:0 context:nil];
  [self addObserver:self forKeyPath:@"self.currentItem.error" options:0 context:nil];
  [self addObserver:self forKeyPath:@"self.currentItem.asset.duration" options:0 context:nil];
  
  __block UnityAdsVideoPlayer *blockSelf = self;
  if (![UnityAdsDevice isSimulator]) {
    self.timeObserver = [self addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
      [blockSelf _videoPositionChanged:time];
    }];
  }
  
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_videoPlaybackEnded:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentItem];
}

- (void)_removeObservers {
  UALOG_DEBUG(@"");
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
  
  if (self.timeObserver != nil) {
    [self removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
  }
	
  if (self.analyticsTimeObserver != nil) {
    [self removeTimeObserver:self.analyticsTimeObserver];
    self.analyticsTimeObserver = nil;
  }
  
  [self removeObserver:self forKeyPath:@"self.currentItem.status"];
  [self removeObserver:self forKeyPath:@"self.currentItem.error"];
  [self removeObserver:self forKeyPath:@"self.currentItem.asset.duration"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqual:@"self.currentItem.error"] && self.currentItem.error != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate videoPlaybackError];
    });
    UALOG_DEBUG(@"VIDEOPLAYER_ERROR: %@", self.currentItem.error);
  }
  else if ([keyPath isEqual:@"self.currentItem.asset.duration"]) {
    UALOG_DEBUG(@"VIDEOPLAYER_DURATION: %f", CMTimeGetSeconds(self.currentItem.asset.duration));
  }
  else if ([keyPath isEqual:@"self.currentItem.status"]) {
    UALOG_DEBUG(@"VIDEOPLAYER_STATUS: %i", self.currentItem.status);
    
    AVPlayerStatus playerStatus = self.currentItem.status;
    if (playerStatus == AVPlayerStatusReadyToPlay) {
      UALOG_DEBUG(@"videostartedplaying");
      __block UnityAdsVideoPlayer *blockSelf = self;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate videoStartedPlaying];
        [self _logVideoAnalytics];
      });
      
      Float64 duration = [self _currentVideoDuration];
      NSMutableArray *analyticsTimeValues = [NSMutableArray array];
      [analyticsTimeValues addObject:[self _valueWithDuration:duration * .25]];
      [analyticsTimeValues addObject:[self _valueWithDuration:duration * .5]];
      [analyticsTimeValues addObject:[self _valueWithDuration:duration * .75]];
      
      if (![UnityAdsDevice isSimulator]) {
        self.analyticsTimeObserver = [self addBoundaryTimeObserverForTimes:analyticsTimeValues queue:nil usingBlock:^{
          UALOG_DEBUG(@"Log position");
          [blockSelf _logVideoAnalytics];
        }];
      }
      
      [self play];
    }
    else if (playerStatus == AVPlayerStatusFailed) {
      UALOG_DEBUG(@"Player failed");
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate videoPlaybackError];
      });
    }
    else if (playerStatus == AVPlayerStatusUnknown) {
      UALOG_DEBUG(@"Player in unknown state");
    }
  }
}


#pragma mark Video Duration

- (void)_videoPositionChanged:(CMTime)time {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.delegate videoPositionChanged:time];
  });
}

- (Float64)_currentVideoDuration {
	CMTime durationTime = self.currentItem.asset.duration;
	Float64 duration = CMTimeGetSeconds(durationTime);
	
	return duration;
}

- (NSValue *)_valueWithDuration:(Float64)duration {
	CMTime time = CMTimeMakeWithSeconds(duration, NSEC_PER_SEC);
	return [NSValue valueWithCMTime:time];
}


#pragma mark Analytics

- (void)_logVideoAnalytics {
  UALOG_DEBUG(@"_logVideoAnalytics");
	self.videoPosition++;
  [[UnityAdsAnalyticsUploader sharedInstance] logVideoAnalyticsWithPosition:self.videoPosition campaign:[[UnityAdsCampaignManager sharedInstance] selectedCampaign]];
}

@end