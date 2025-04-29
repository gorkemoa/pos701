 // FLTFirebaseMessagingPlugin.h patched version
#import <Flutter/Flutter.h>

// Avoid direct Firebase.h import
@class FIRMessaging;

@interface FLTFirebaseMessagingPlugin : NSObject<FlutterPlugin>
@property(nonatomic, retain) NSObject<FlutterPluginRegistrar>* _Nonnull registrar;
@property(nonatomic, retain) FlutterMethodChannel* _Nonnull channel;
@property(nonatomic, retain) NSMutableDictionary<NSString*, FlutterEventChannel*>* _Nonnull eventChannels;
@property(nonatomic, retain) NSMutableDictionary<NSString*, NSMutableArray<FlutterEventSink>*>* _Nonnull eventSinks;
@property(nonatomic, retain) FIRMessaging* _Nullable messaging;
@end 