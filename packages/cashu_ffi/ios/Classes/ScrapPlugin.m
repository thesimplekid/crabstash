#import "CashuPlugin.h"
#if __has_include(<cashu/cashu-Swift.h>)
#import <cashu/cashu-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cashu-Swift.h"
#endif

@implementation CashuPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCashuPlugin registerWithRegistrar:registrar];
}
@end
