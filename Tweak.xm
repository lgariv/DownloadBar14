@import Foundation;
@import UIKit;
@import UserNotifications;

#import <UserNotifications/UserNotifications.h>

@interface BBSectionIconVariant : NSObject
@property (nonatomic,copy) NSData * imageData;
@end

@interface BBSectionIcon : NSObject
-(void)addVariant:(BBSectionIconVariant *)arg1 ;
@end

@interface BBBulletin : NSObject
@property (nonatomic,readonly) NSString * sectionDisplayName;
@property (nonatomic,copy) NSString * header;
@property (nonatomic,copy) NSString * section;
@property (nonatomic,copy) NSString * sectionID;
@property (nonatomic,copy) NSSet * subsectionIDs;
@property (nonatomic,copy) NSString * recordID;
@property (nonatomic,copy) NSString * publisherBulletinID;
@property (nonatomic,copy) NSString * dismissalID;
@property (nonatomic,copy) NSString * categoryID;
@property (nonatomic,copy) NSString * threadID;
@property (nonatomic,copy) NSArray * peopleIDs;
@property (nonatomic,copy) NSString * bulletinID;
@property (nonatomic,retain) NSDate *lastInterruptDate;
@property (assign,nonatomic) BOOL clearable;
@property (nonatomic,retain) NSDate *date;
@property (nonatomic,copy) NSString *message;
@property (nonatomic,retain) NSDate *publicationDate;
@property (assign,nonatomic) BOOL showsMessagePreview;
@property (nonatomic,copy) NSString *title;
+(id)bulletinWithBulletin:(id)arg1 ;
-(void)setLockScreenPriority:(long long)arg1 ;
-(BOOL)prioritizeAtTopOfLockScreen ;
@end

@interface BBBulletinRequest : BBBulletin
-(void)generateNewBulletinID;
@end

@interface BBServer : NSObject
-(void)publishBulletinRequest:(BBBulletinRequest*)arg1 destinations:(unsigned long long)arg2;
@end

static BBServer *sharedServer;
#include <dlfcn.h>
extern dispatch_queue_t __BBServerQueue;

%hook BBServer
-(id)initWithQueue:(id)arg1 {
	sharedServer = %orig;
	return sharedServer;
}
%end

#define PROGRESSBAR_INSET 7

@interface SBIconProgressView : UIView
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UIView *progressBar;
@property (nonatomic, strong) UIView *progressBarBackground;
@property (nonatomic, strong) NSString *bundleId;
@property (nonatomic, assign) double displayedFraction;
-(void)setupSubviews;
@end

@interface SBIcon : NSObject
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *uniqueIdentifier;
@end

@interface SBDownloadingIcon : NSObject
@property (nonatomic, strong) NSString *realDisplayName;
@end

@interface SBIconImageView : UIView
@property (nonatomic,readonly) __kindof SBIcon *icon;
@end

%hook SBIconProgressView
%property (nonatomic, strong) UILabel *progressLabel;
%property (nonatomic, strong) UIView *progressBar;
%property (nonatomic, strong) UIView *progressBarBackground;
%property (nonatomic, strong) NSString *bundleId;

-(void)setFrame:(CGRect)arg1 {
	%orig;
	if (arg1.size.width != 0) {
		[self setupSubviews];
	}
}

-(id)initWithFrame:(CGRect)arg1 {
	if ((self = %orig)) {
		self.progressBar = [[UIView alloc] init];
		self.progressBar.backgroundColor = [UIColor colorWithRed:67.f/255.f green:130.f/255.f blue:232.f/255.f alpha:1.0f];
		self.progressBar.layer.cornerRadius = 2.5;

		self.progressBarBackground = [[UIView alloc] init];
		self.progressBarBackground.backgroundColor = UIColor.darkGrayColor;
		self.progressBarBackground.layer.cornerRadius = 2.5;

		self.progressLabel = [[UILabel alloc] init];
		self.progressLabel.font = [UIFont boldSystemFontOfSize:10];
		self.progressLabel.textAlignment = NSTextAlignmentCenter;
		self.progressLabel.text = @"0%%";

		[self addSubview: self.progressBarBackground];
		[self addSubview: self.progressBar];
		[self addSubview: self.progressLabel];
	}
	return self;
}

-(void)didMoveToSuperview{
	%orig;
	
	SBIconImageView *viewview = (SBIconImageView*)self.superview;
	if (viewview != nil) {
		SBIcon *icon = [viewview icon];
		self.bundleId = [icon isKindOfClass:NSClassFromString(@"SBLeafIcon")] ? MSHookIvar<NSString*>(icon, "_applicationBundleID") : icon.uniqueIdentifier;

		BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
		[bulletin setHeader:icon.displayName];
		[bulletin setTitle:@"Downloading"];
		[bulletin setMessage:@"com.miwix.downloadbar14-progressbar"];
		
		NSString *bulletinUUID = [[NSUUID UUID] UUIDString];
		
		//Temporary Fix because AppStore Notifications don't work on my device
		//[bulletin setSection:@"com.apple.AppStore"];
		//[bulletin setSectionID:@"com.apple.AppStore"];
		[bulletin setSection:@"com.apple.Preferences"];
		[bulletin setSectionID:@"com.apple.Preferences"];
		
		[bulletin setBulletinID:bulletinUUID];
		[bulletin setRecordID:bulletinUUID];
		[bulletin setThreadID:self.bundleId];
		[bulletin setPublisherBulletinID:[NSString stringWithFormat:@"com.miwix.downloadbar14/%@", self.bundleId]];
		[bulletin setDate:[NSDate date]];
		
		dispatch_async(__BBServerQueue, ^{
			[sharedServer publishBulletinRequest:bulletin destinations:2];
		});
	}
}

-(void)setDisplayedFraction:(double)arg1 {
	%orig;
	self.progressLabel.text = [NSString stringWithFormat:@"%i%%", (int)(arg1 * 100)];
	self.progressLabel.textColor = [UIColor whiteColor];
	[self.progressLabel sizeToFit];

	NSDictionary* userInfo = @{@"fraction": [NSNumber numberWithDouble: arg1], @"bundleId": self.bundleId};
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updateProgress" object:nil userInfo:userInfo];
}

-(void)_drawOutgoingCircleWithCenter:(CGPoint)arg1 {

}

-(void)_drawIncomingCircleWithCenter:(CGPoint)arg1 {

}

-(void)_drawPauseUIWithCenter:(CGPoint)arg1 {
	%orig(CGPointMake(arg1.x, arg1.y - 10));
}

-(void)_drawPieWithCenter:(CGPoint)arg1 {
	self.progressLabel.center = CGPointMake(arg1.x, arg1.y + 7);
	self.progressBar.frame = CGRectMake(PROGRESSBAR_INSET, self.frame.size.height - 12, (self.frame.size.width - PROGRESSBAR_INSET * 2) * self.displayedFraction, 5);
	self.progressBarBackground.frame = CGRectMake(PROGRESSBAR_INSET, self.frame.size.height - 12, self.frame.size.width - PROGRESSBAR_INSET * 2, 5);
}

%new
-(void)setupSubviews {
	self.progressBarBackground.frame = CGRectMake(PROGRESSBAR_INSET, self.frame.size.height - 12, self.frame.size.width - PROGRESSBAR_INSET * 2, 5);
	self.progressBar.frame = CGRectMake(PROGRESSBAR_INSET, self.frame.size.height - 12, (self.frame.size.width - PROGRESSBAR_INSET * 2) * self.displayedFraction, 5);
	self.progressLabel.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2 + 7);
}
%end

@interface UIImage()
+(instancetype)_applicationIconImageForBundleIdentifier:(NSString*)bundleId format:(int)format;
@end

@interface PLPlatterView : UIView
@end

@interface NCNotificationRequest : NSObject
@property BBBulletin *bulletin;
@end

@interface NCNotificationViewControllerView : UIView
@property PLPlatterView *contentView;
@end

@interface NCNotificationContentView : UIView
@property(getter=_secondaryLabel,nonatomic,readonly) UILabel *secondaryLabel;
@end

@interface NCNotificationShortLookView : PLPlatterView
@property(getter=_notificationContentView,nonatomic,readonly) NCNotificationContentView *notificationContentView;
@end

@interface NCNotificationShortLookViewController : UIViewController
@property NCNotificationRequest *notificationRequest;

@property UIProgressView *progressView;
@end

%hook BBBulletin
-(BBSectionIcon *)sectionIcon{
	if ([self.publisherBulletinID hasPrefix:@"com.miwix.downloadbar14/"]) {
		UIImage *img = [UIImage _applicationIconImageForBundleIdentifier:[self.publisherBulletinID substringFromIndex:[self.publisherBulletinID rangeOfString:@"/"].location + 1] format:1];

		BBSectionIconVariant *variant = [[BBSectionIconVariant alloc] init];
		[variant setImageData:UIImagePNGRepresentation(img)];

		BBSectionIcon *icon = [[BBSectionIcon alloc] init];
		[icon addVariant:variant];

		return icon;
	} else return %orig;
}
%end

%hook NCNotificationShortLookViewController
%property(nonatomic, strong) UIProgressView *progressView;

-(void)viewDidLoad{
	%orig;
	
	if ([self.notificationRequest.bulletin.publisherBulletinID hasPrefix:@"com.miwix.downloadbar14/"]) {
		self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		[self.progressView setProgress:0 animated:false];
	}
}

-(void)viewWillAppear:(BOOL)animated{
	%orig;

	if ([self.notificationRequest.bulletin.publisherBulletinID hasPrefix:@"com.miwix.downloadbar14/"]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"updateProgress" object:nil];
		
		NCNotificationContentView *content = ((NCNotificationShortLookView*)((NCNotificationViewControllerView*)self.view).contentView).notificationContentView;
		UILabel *label = content.secondaryLabel;
		label.hidden = true;
		
		self.progressView.translatesAutoresizingMaskIntoConstraints = false;
		
		self.progressView.progressTintColor = [UIColor systemBlueColor];
		self.progressView.trackTintColor = [UIColor lightGrayColor];
		
		[self.progressView removeFromSuperview];
		[content addSubview:self.progressView];
		
		[self.progressView.centerYAnchor constraintEqualToAnchor:label.centerYAnchor].active = true;
		[self.progressView.leadingAnchor constraintEqualToAnchor:label.leadingAnchor].active = true;
		[self.progressView.trailingAnchor constraintEqualToAnchor:label.trailingAnchor].active = true;
	}
}

%new
-(void)receiveNotification:(NSNotification *)notification {
	NSDictionary* userInfo = notification.userInfo;
	if(![userInfo[@"bundleId"] isEqualToString:[self.notificationRequest.bulletin.publisherBulletinID substringFromIndex:[self.notificationRequest.bulletin.publisherBulletinID rangeOfString:@"/"].location + 1]]) return;

	double fraction = [userInfo[@"fraction"] doubleValue];
	[self.progressView setProgress:fraction animated:true];
}
%end
