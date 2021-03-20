#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libhdev/HUtilities/HCommon.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.iconcertpref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.iconcertpref/PrefChanged"

#define ERROR_TIMELEFT -1000000.0

@interface LSBundleProxy : NSObject
+(LSBundleProxy *)bundleProxyForIdentifier:(NSString *)arg1;
-(NSURL *)bundleURL;
@end

@interface SBIconView : UIView
@property (nonatomic,copy,readonly) NSURL * applicationBundleURLForShortcuts;
@property (nonatomic,copy,readonly) NSString * applicationBundleIdentifierForShortcuts;
@end

@interface SBIconImageView : UIView
@property (assign,nonatomic) SBIconView * iconView;
@property (nonatomic, retain) UIView *badgeView; // new
@property (nonatomic, retain) UILabel *timeLeftLabel; // new
- (NSTimeInterval)getExpirationTimeLeft:(NSURL *)bundleUrl; // new
- (NSString *)formatTime:(double)second; // new
- (void)setupBadgeView; // new
- (void)updateBadgeView; // new
@end
