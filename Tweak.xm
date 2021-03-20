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
  NSError *error = nil;
  // NSURL *bundleUrl = [[%c(LSBundleProxy) bundleProxyForIdentifier:@"science.xnu.undecimus.32CDKB8PZH"] bundleURL];
  NSURL *mobileProvisionUrl = [bundleUrl URLByAppendingPathComponent:@"embedded.mobileprovision"];
  NSString *mobileProvisionContent = [NSString stringWithContentsOfURL:mobileProvisionUrl encoding:NSASCIIStringEncoding error:&error];

  if ([mobileProvisionContent length] == 0) {
    // [HCommon showAlertMessage:[error localizedDescription] withTitle:@"Error" viewController:nil];
    return ERROR_TIMELEFT;
  }
  
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<date>(.*)</date>" options:NSRegularExpressionCaseInsensitive error:&error];
  NSArray *matchesInString = [regex matchesInString:mobileProvisionContent options:0 range:NSMakeRange(0, [mobileProvisionContent length])];

  if (matchesInString == nil || [matchesInString count] < 1) {
    // [HCommon showAlertMessage:@"Can't find match <date>(.*)</date> string" withTitle:@"Error" viewController:nil];
    return ERROR_TIMELEFT;
  }

  // get ExpirationDate, its index is 1, the index 0 is CreationDate
  NSTextCheckingResult *match = matchesInString[1];
  // get date string only in regex group (.*). If you want to get all match string, use [match range];
  NSString* expirationDateStr = [mobileProvisionContent substringWithRange:[match rangeAtIndex:1]];

  // calculate diff between expire date to now
  NSDate *now = [NSDate date];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
  NSDate *capturedStartDate = [dateFormatter dateFromString:expirationDateStr];

  NSTimeInterval diff = [capturedStartDate timeIntervalSinceDate:now];
  return diff;
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
      [self setupBadgeView];
      return orig;
    }

    -(void)updateImageAnimated:(BOOL)arg1 {
      %orig;

      [self updateBadgeView];
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