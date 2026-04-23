//
//  SceneDelegate+CULPlugin.h
//
//  Category on CDVSceneDelegate that routes UIScene user activities
//  (Universal Links) into CULPlugin. The sibling AppDelegate+CULPlugin
//  category only fires on pre-scene cordova-ios apps; in cordova-ios 8+,
//  UIKit delivers `scene:continueUserActivity:` to the scene delegate and
//  never calls the AppDelegate's continueUserActivity method.
//

#import <Cordova/CDVSceneDelegate.h>
#import <UIKit/UIKit.h>

@interface CDVSceneDelegate (CULPlugin)
@end
