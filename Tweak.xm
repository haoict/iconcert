#import "Tweak.h"

NSString *defaultWhitelistBundleIdsStr = @"science.xnu.undecimus,com.rileytestut.AltStore";

static BOOL enable;
static BOOL animation;
static double opacity;
static int timeFormat;
static NSArray *whitelistBundleIds;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  enable = [[settings objectForKey:@"enable"] ?: @(YES) boolValue];
  animation = [[settings objectForKey:@"animation"] ?: @(NO) boolValue];
  opacity = ([settings objectForKey:@"opacity"] == nil ? 80.0 : [[settings objectForKey:@"opacity"] doubleValue]) / 100.0;
  timeFormat = [[settings objectForKey:@"timeFormat"] intValue] ?: 0;
  NSString *whitelistBundleIdsStr = [[settings objectForKey:@"whitelistBundleIds"] ?: defaultWhitelistBundleIdsStr stringValue];
  whitelistBundleIds = [whitelistBundleIdsStr componentsSeparatedByString:@","];
}

static NSTimeInterval getExpirationTimeLeft(NSURL *bundleUrl) {
    NSError *error;
    NSPropertyListFormat plistFormat;
    NSURL *mobileProvisionUrl = [bundleUrl URLByAppendingPathComponent:@"embedded.mobileprovision"];
    NSString *plistDataString = [[NSString alloc] initWithContentsOfFile:mobileProvisionUrl.path encoding:NSISOLatin1StringEncoding error:nil];
    NSScanner *scanner = [[NSScanner alloc] initWithString:plistDataString];
    [scanner scanUpToString:@"<plist" intoString:nil];
    
    NSString *extractedPlist;
    if ([scanner scanUpToString:@"</plist>" intoString:&extractedPlist]) {
        NSData *plistData = [[extractedPlist stringByAppendingString:@"</plist>"] dataUsingEncoding:NSISOLatin1StringEncoding];
        NSMutableDictionary *plistDictionary = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&plistFormat error:&error];
        NSDate *ExpirationDate = [plistDictionary valueForKey:@"ExpirationDate"];
        return [ExpirationDate timeIntervalSinceNow];
    } else {
        return ERROR_TIMELEFT;
    }
}

static NSString* formatTime(double second) {
  if (second <= 0) {
    return @"expired";
  }

  // [HCommon showAlertMessage:[NSString stringWithFormat:@"%dd %dh", days, hours] withTitle:@"" viewController:nil];
  switch (timeFormat) {
    case 1: {
      double days = second / (60 * 60 * 24);
      return [NSString stringWithFormat:@"%.1fd", days];
    }
    case 2: {
      int hours = second / (60 * 60);
      return [NSString stringWithFormat:@"%dh", hours];
    }
    case 3: {
      return [NSString stringWithFormat:@"%.0fs", second];
    }
    default: {
      int days = second / (60 * 60 * 24);
      int hours = second / (60 * 60) - 24 * days;
      return [NSString stringWithFormat:@"%dd %dh", days, hours];
    }
  }
}

%group Core

  %hook SBIconImageView
    %property (nonatomic, retain) UIView *badgeView;
    %property (nonatomic, retain) UILabel *timeLeftLabel;

    - (id)initWithFrame:(CGRect)arg1 {
      id orig = %orig;
      // Fix crash due to conflict with SnowBoard
      if ([self respondsToSelector:@selector(setupBadgeView)]) {
        [self setupBadgeView];
      }
      return orig;
    }

    -(void)updateImageAnimated:(BOOL)arg1 {
      %orig;
      // Fix crash due to conflict with SnowBoard
      if ([self respondsToSelector:@selector(updateBadgeView)]) {
        [self updateBadgeView];
      }
    }

    %new
    - (void)updateBadgeView {
      self.badgeView.alpha = 0;

      BOOL enable = FALSE;
      for (NSString *whitelistBundleId in whitelistBundleIds) {
        if ([self.iconView.applicationBundleIdentifierForShortcuts containsString:whitelistBundleId]) {
          enable = TRUE;
          break;
        }
      }

      if (!enable) {
        return;
      }

      NSTimeInterval timeLeft = getExpirationTimeLeft(self.iconView.applicationBundleURLForShortcuts);
      if (timeLeft <= ERROR_TIMELEFT) {
        self.timeLeftLabel.text = @"error";
      } else {
        self.timeLeftLabel.text = formatTime(timeLeft);
      }
      

      if (animation) {
        [UIView animateWithDuration:0.85 animations:^{ self.badgeView.alpha = opacity; } completion:^(BOOL finished) {}];
      } else {
        self.badgeView.alpha = opacity;
      }
    }

    %new
    - (void)setupBadgeView {
      self.badgeView = [[UIView alloc] init];
      self.badgeView.frame = CGRectMake(6.0, 5.0, 48.0, 16.0);
      self.badgeView.alpha = 0;
      self.badgeView.layer.cornerRadius = 6.5;
      self.badgeView.backgroundColor = [UIColor blackColor];
      // self.badgeView.center = CGPointMake(CGRectGetMidX(self.iconView.bounds), self.iconView.center.y);

      [self addSubview:self.badgeView];
      self.badgeView.translatesAutoresizingMaskIntoConstraints = false;
      [self.badgeView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5.0].active = YES;
      [self.badgeView.bottomAnchor constraintEqualToAnchor:self.topAnchor constant:21.0].active = YES;
      [self.badgeView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:6.0].active = YES;
      [self.badgeView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-6.0].active = YES;


      UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(4.0, 2.0, 12.0, 12.0)];
      imageView.translatesAutoresizingMaskIntoConstraints = false;
      [imageView setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/iconcert/keyicon.png"]];
      [self.badgeView addSubview:imageView];

      UIFont * customFont = [UIFont fontWithName:@"Arial-BoldMT" size:10]; //custom font
      self.timeLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 0.0, 30.0, 16.0)];
      self.timeLeftLabel.translatesAutoresizingMaskIntoConstraints = false;
      self.timeLeftLabel.text = @"0d 0h";
      self.timeLeftLabel.font = customFont;
      self.timeLeftLabel.adjustsFontSizeToFitWidth = true;
      self.timeLeftLabel.textAlignment = NSTextAlignmentCenter;
      self.timeLeftLabel.textColor = [UIColor whiteColor];
      [self.badgeView addSubview:self.timeLeftLabel];

      NSDictionary *views = @{ @"imageView":imageView, @"timeLeftLabel":self.timeLeftLabel }; //NSDictionaryOfVariableBindings(imageView, self.timeLeftLabel);
      [self.badgeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-3-[imageView(10)]-2-[timeLeftLabel]-2-|" options:0 metrics:nil views:views]];
      [self.badgeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-3-[imageView(10)]" options:0 metrics:nil views:views]];
      [self.badgeView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[timeLeftLabel]-2-|" options:0 metrics:nil views:views]];
    }
  %end

%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  if (enable) {
    %init(Core);
  }
}
