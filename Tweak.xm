#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

@interface SPUISearchViewController : UIViewController
- (BOOL)_shouldShowFirstTimeView;
- (void)firstTimeViewControllerDidSelectLearnMoreAction:(id)arg1;
- (void)firstTimeViewControllerDidSelectContinueAction:(id)arg1;
@end

@interface SPUISearchFirstTimeViewController : UIViewController
- (SPUISearchViewController *)delegate;
@end

extern "C" void setSPLogLevel(int);

extern "C" Boolean MGGetBoolAnswer(CFStringRef);
MSHook(Boolean, MGGetBoolAnswer, CFStringRef string)
{
	#define k(key) CFEqual(string, CFSTR(key))
	if (k("s+gaKNe68Gs3PfqKrZhi1w"))
		return NO;
	return _MGGetBoolAnswer(string);
}

extern "C" CFPropertyListRef MGCopyAnswer(CFStringRef);
MSHook(CFPropertyListRef, MGCopyAnswer, CFStringRef string)
{
	#define k(key) CFEqual(string, CFSTR(key))
	if (k("s+gaKNe68Gs3PfqKrZhi1w"))
		return kCFBooleanFalse;
	return _MGCopyAnswer(string);
}

MSHook(Boolean, CFPreferencesGetAppBooleanValue, CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat)
{
	if (CFEqual(key, CFSTR("SpotlightIndexEnabled")))
		return YES;
	return _CFPreferencesGetAppBooleanValue(key, applicationID, keyExistsAndHasValidFormat);
}

%hook NSUserDefaults

- (id)objectForKey:(NSString *)key
{
	/*if ([key isEqualToString:@"SPLogLevel"])
		return @(8);*/
	if ([key isEqualToString:@"SpotlightIndexEnabled"])
		return @(YES);
	/*if ([key isEqualToString:@"SPDefaultSearch"])
		return @(YES);*/
	return %orig;
}

%end

%group SpringBoard

%hook SPUISearchViewController

- (void)loadView
{
	%orig;
	if ([self _shouldShowFirstTimeView])
		[self firstTimeViewControllerDidSelectContinueAction:self];
}

- (BOOL)_shouldUpdateZKWContent:(BOOL)arg1
{
	return YES;
}

%end

%end

%group Parsec

/*%hook PRSSharedParsecSession

- (NSString *)userAgent
{
	NSString *r = [%orig stringByReplacingOccurrencesOfString:@"iPhone4,1" withString:@"iPhone5,1"];
	NSLog(@"---> %@", r);
	return r;
}

%end*/

%end

%group coreduetd

%hook CDDWatchKitAdmissionController

- (id)companionBundleFromWatchBundle:(id)arg1
{
	return nil;
}

- (BOOL)isWatchkitApp:(id)arg1
{
	return NO;
}

%end

%hook CDDWatchUpdateController

- (void)receiveWatchfaceInfo:(id)arg1 device:(id)arg2
{
	return;
}

%end

/*%hook CDDCoreData

- (NSManagedObjectModel *)model
{
	NSManagedObjectModel *orig = %orig;
	NSLog(@"%@", orig);
	return orig;
}

%end*/

%end

%group SP

%hook SPDeviceConnection

- (void)createXPCConnectionIfNecessary
{
	return;
}

- (void)fetchInstalledApplicationsWithCompletion:(id)arg1
{
	return;
}

%end

%end

%hook _DECDeviceInfo

+ (BOOL)_isLowEndHardware
{
	return NO;
}

%end

int (*sandbox_extension_issue_file)(const char *, const char *, int, int);
MSHook(int, sandbox_extension_issue_file, const char *ext, const char *path, int reserved, int flags)
{
	return _sandbox_extension_issue_file(ext, path, 0, flags);
}

%ctor
{
	setSPLogLevel(8);
	dlopen("/System/Library/PrivateFrameworks/DuetExpertCenter.framework/DuetExpertCenter", RTLD_LAZY);
	%init;
	if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.Preferences"])
		dlopen("/System/Library/PreferenceBundles/SearchSettings.bundle/SearchSettings", RTLD_LAZY);
	MSHookFunction(MGGetBoolAnswer, MSHake(MGGetBoolAnswer));
	MSHookFunction(MGCopyAnswer, MSHake(MGCopyAnswer));
	MSHookFunction(CFPreferencesGetAppBooleanValue, MSHake(CFPreferencesGetAppBooleanValue));
	if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
		dlopen("/System/Library/PrivateFrameworks/SpotlightUI.framework/SpotlightUI", RTLD_LAZY);
		%init(SpringBoard);
	}
	dlopen("/System/Library/Frameworks/WatchKit.framework/WatchKit", RTLD_LAZY);
	if (%c(SPDeviceConnection)) {
		NSLog(@"SP on");
		%init(SP);
	}
	if (%c(PRSSharedParsecSession)) {
		NSLog(@"Parsec on");
		%init(Parsec);
	}
	if (%c(CDDWatchKitAdmissionController)) {
		NSLog(@"CDD on");
		%init(coreduetd);
	}
	if (%c(PKDPlugIn) && [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.pkd"]) {
		MSImageRef ref = MSGetImageByName("/usr/lib/system/libsystem_sandbox.dylib");
		sandbox_extension_issue_file = (int (*)(const char *, const char *, int, int))MSFindSymbol(ref, "_sandbox_extension_issue_file");
		//NSLog(@"%d", sandbox_extension_issue_file != NULL);
		MSHookFunction(sandbox_extension_issue_file, MSHake(sandbox_extension_issue_file));
	}
}