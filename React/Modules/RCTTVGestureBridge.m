#import "RCTTVGestureBridge.h"
#import <React/RCTRootView.h>

@implementation RCTTVGestureBridge

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(reinitializeTVRemote:(nonnull NSNumber *)withGesture)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTReinitializeTVRemoteNotification
                                                        object:nil
                                                      userInfo:@{@"withGesture": withGesture}];
}

@end
