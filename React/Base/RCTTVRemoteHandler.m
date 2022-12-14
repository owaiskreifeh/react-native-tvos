/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTTVRemoteHandler.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTRootView.h"
#import "RCTTVNavigationEventEmitter.h"
#import "RCTUIManager.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "UIView+React.h"

#if __has_include("RCTDevMenu.h")
#import "RCTDevMenu.h"
#endif

NSString *const RCTTVRemoteEventMenu = @"menu";
NSString *const RCTTVRemoteEventPlayPause = @"playPause";
NSString *const RCTTVRemoteEventSelect = @"select";

NSString *const RCTTVRemoteEventLongPlayPause = @"longPlayPause";
NSString *const RCTTVRemoteEventLongSelect = @"longSelect";

NSString *const RCTTVRemoteEventLeft = @"left";
NSString *const RCTTVRemoteEventRight = @"right";
NSString *const RCTTVRemoteEventUp = @"up";
NSString *const RCTTVRemoteEventDown = @"down";

NSString *const RCTTVRemoteEventLongLeft = @"longLeft";
NSString *const RCTTVRemoteEventLongRight = @"longRight";
NSString *const RCTTVRemoteEventLongUp = @"longUp";
NSString *const RCTTVRemoteEventLongDown = @"longDown";

NSString *const RCTTVRemoteEventSwipeLeft = @"swipeLeft";
NSString *const RCTTVRemoteEventSwipeRight = @"swipeRight";
NSString *const RCTTVRemoteEventSwipeUp = @"swipeUp";
NSString *const RCTTVRemoteEventSwipeDown = @"swipeDown";


@implementation RCTTVRemoteHandler {
  NSMutableDictionary<NSString *, UIGestureRecognizer *> *_tvRemoteGestureRecognizers;
    int _panXSteps;
    int _panYSteps;
    CGFloat _panXFactor;
    CGFloat _panYFactor;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _tvRemoteGestureRecognizers = [NSMutableDictionary dictionary];
      _panXSteps = 0;
      _panYSteps = 0;
      _panXFactor = 0.2;
      _panYFactor = 0.2;

    // Recognizers for Apple TV remote buttons
    // Menu recognizer
    self.tvMenuKeyRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuPressed:)];
    self.tvMenuKeyRecognizer.allowedPressTypes = @[@(UIPressTypeMenu)];

    // Play/Pause
    [self addTapGestureRecognizerWithSelector:@selector(playPausePressed:)
                                    pressType:UIPressTypePlayPause
                                         name:RCTTVRemoteEventPlayPause];

    // Select
    [self addTapGestureRecognizerWithSelector:@selector(selectPressed:)
                                    pressType:UIPressTypeSelect
                                         name:RCTTVRemoteEventSelect];

    // Up
    [self addTapGestureRecognizerWithSelector:@selector(tappedUp:)
                                    pressType:UIPressTypeUpArrow
                                         name:RCTTVRemoteEventUp];

    // Down
    [self addTapGestureRecognizerWithSelector:@selector(tappedDown:)
                                    pressType:UIPressTypeDownArrow
                                         name:RCTTVRemoteEventDown];

    // Left
    [self addTapGestureRecognizerWithSelector:@selector(tappedLeft:)
                                    pressType:UIPressTypeLeftArrow
                                         name:RCTTVRemoteEventLeft];

    // Right
    [self addTapGestureRecognizerWithSelector:@selector(tappedRight:)
                                    pressType:UIPressTypeRightArrow
                                         name:RCTTVRemoteEventRight];

    // Recognizers for long button presses
    // We don't intercept long menu press -- that's used by the system to go to the home screen

    [self addLongPressGestureRecognizerWithSelector:@selector(longPlayPausePressed:)
                                          pressType:UIPressTypePlayPause
                                               name:RCTTVRemoteEventLongPlayPause];

    [self addLongPressGestureRecognizerWithSelector:@selector(longSelectPressed:)
                                          pressType:UIPressTypeSelect
                                               name:RCTTVRemoteEventLongSelect];
      
      
      [self addLongPressGestureRecognizerWithSelector:@selector(longUpPressed:)
                                            pressType:UIPressTypeUpArrow
                                                 name:RCTTVRemoteEventLongUp];
      
      [self addLongPressGestureRecognizerWithSelector:@selector(longDownPressed:)
                                            pressType:UIPressTypeDownArrow
                                                 name:RCTTVRemoteEventLongDown];
      
      [self addLongPressGestureRecognizerWithSelector:@selector(longRightPressed:)
                                            pressType:UIPressTypeRightArrow
                                                 name:RCTTVRemoteEventLongRight];
      
      [self addLongPressGestureRecognizerWithSelector:@selector(longLeftPressed:)
                                            pressType:UIPressTypeLeftArrow
                                                 name:RCTTVRemoteEventLongLeft];
      
    // Recognizers for Apple TV remote trackpad swipes

    // Up
    [self addSwipeGestureRecognizerWithSelector:@selector(swipedUp:)
                                      direction:UISwipeGestureRecognizerDirectionUp
                                           name:RCTTVRemoteEventSwipeUp];

    // Down
    [self addSwipeGestureRecognizerWithSelector:@selector(swipedDown:)
                                      direction:UISwipeGestureRecognizerDirectionDown
                                           name:RCTTVRemoteEventSwipeDown];

    // Left
    [self addSwipeGestureRecognizerWithSelector:@selector(swipedLeft:)
                                      direction:UISwipeGestureRecognizerDirectionLeft
                                           name:RCTTVRemoteEventSwipeLeft];

    // Right
    [self addSwipeGestureRecognizerWithSelector:@selector(swipedRight:)
                                      direction:UISwipeGestureRecognizerDirectionRight
                                           name:RCTTVRemoteEventSwipeRight];
      
      [self addPanGestureRecognizerWithSelector:@selector(pan:)
                                           name:@"pan"];

  }

  return self;
}

- (void)playPausePressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventPlayPause toView:r.view];
}

- (void)menuPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventMenu toView:r.view];
}

- (void)selectPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventSelect toView:r.view];
    NSLog(@"Saffar selectPressed");
}

- (void)longPlayPausePressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongPlayPause toView:r.view];

#if __has_include("RCTDevMenu.h") && RCT_DEV
  // If shake to show is enabled on device, use long play/pause event to show dev menu
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTShowDevMenuNotification object:nil];
#endif
}

- (void)longSelectPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongSelect toView:r.view];
}

- (void)longUpPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongUp toView:r.view];
}

- (void)longDownPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongDown toView:r.view];
}

- (void)longLeftPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongLeft toView:r.view];
}

- (void)longRightPressed:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLongRight toView:r.view];
}

- (void)swipedUp:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventSwipeUp toView:r.view];
}

- (void)swipedDown:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventSwipeDown toView:r.view];
}

- (void)swipedLeft:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventSwipeLeft toView:r.view];
}

- (void)swipedRight:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventSwipeRight toView:r.view];
}

- (void)tappedUp:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventUp toView:r.view];
}

- (void)tappedDown:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventDown toView:r.view];
}

- (void)tappedLeft:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventLeft toView:r.view];
}

- (void)tappedRight:(UIGestureRecognizer *)r
{
  [self sendAppleTVEvent:RCTTVRemoteEventRight toView:r.view];
}

- (void)pan:(UIPanGestureRecognizer *)r
{
    if (r.state == UIGestureRecognizerStateChanged) {
        CGPoint translatedPoint = [r translationInView:r.view];
        CGSize padSize = r.view.bounds.size;
        int xSteps = translatedPoint.x / (padSize.width * _panXFactor);
        int ySteps = translatedPoint.y / (padSize.height * _panYFactor);
        
//        NSLog(@"Saffar values = %f , %f", translatedPoint.x / (padSize.width * _panXFactor) , translatedPoint.y / (padSize.height * _panYFactor));
//        NSLog(@"Saffar floor = %d , %d", xSteps , ySteps);
        
        if (xSteps > _panXSteps) {
            [self swipedRight:r];
            _panXSteps = xSteps;
        } else if (xSteps < _panXSteps){
            [self swipedLeft:r];
            _panXSteps = xSteps;
        } else if (ySteps < _panYSteps){
           [self swipedUp:r];
            _panYSteps = ySteps;
        } else if (ySteps > _panYSteps){
           [self swipedDown:r];
            _panYSteps = ySteps;
        }
    } else if (r.state == UIGestureRecognizerStateBegan) {
        _panXSteps = 0;
        _panYSteps = 0;
    }
}

#pragma mark -

- (void)addLongPressGestureRecognizerWithSelector:(nonnull SEL)selector pressType:(UIPressType)pressType name:(NSString *)name
{
  UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:selector];
  recognizer.allowedPressTypes = @[@(pressType)];

  _tvRemoteGestureRecognizers[name] = recognizer;
}

- (void)addTapGestureRecognizerWithSelector:(nonnull SEL)selector pressType:(UIPressType)pressType name:(NSString *)name
{
  UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
  recognizer.allowedPressTypes = @[@(pressType)];

  _tvRemoteGestureRecognizers[name] = recognizer;
}

- (void)addSwipeGestureRecognizerWithSelector:(nonnull SEL)selector direction:(UISwipeGestureRecognizerDirection)direction name:(NSString *)name
{
  UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:selector];
  recognizer.direction = direction;

  _tvRemoteGestureRecognizers[name] = recognizer;
}

- (void)addPanGestureRecognizerWithSelector:(nonnull SEL)selector name:(NSString *)name
{
  UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:selector];
  _tvRemoteGestureRecognizers[name] = recognizer;
}

- (void)sendAppleTVEvent:(NSString *)eventType toView:(__unused UIView *)v
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTTVNavigationEventNotification
                                                      object:@{@"eventType":eventType}];
}

- (void) setPanStepFactor:(CGFloat)x yFactor:(CGFloat)y
{
    _panXFactor = x;
    _panYFactor = y;
    _panXSteps = 0;
    _panYSteps = 0;
    
//    NSLog(@"Saffar setPanStepFactor = %f , %f", x , y);
}


@end
