// Autogenerated from Pigeon (v4.2.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon
#import <Foundation/Foundation.h>
@protocol FlutterBinaryMessenger;
@protocol FlutterMessageCodec;
@class FlutterError;
@class FlutterStandardTypedData;

NS_ASSUME_NONNULL_BEGIN

@class BHistoryEntry;

@interface BHistoryEntry : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithState:(NSNumber *)state
    at:(NSString *)at
    source:(NSString *)source;
@property(nonatomic, strong) NSNumber * state;
@property(nonatomic, copy) NSString * at;
@property(nonatomic, copy) NSString * source;
@end

/// The codec used by BFApi.
NSObject<FlutterMessageCodec> *BFApiGetCodec(void);

@interface BFApi : NSObject
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger;
- (void)currentStateState:(NSNumber *)state completion:(void(^)(NSError *_Nullable))completion;
@end
/// The codec used by BHApi.
NSObject<FlutterMessageCodec> *BHApiGetCodec(void);

@protocol BHApi
- (void)updateStateEntry:(BHistoryEntry *)entry error:(FlutterError *_Nullable *_Nonnull)error;
@end

extern void BHApiSetup(id<FlutterBinaryMessenger> binaryMessenger, NSObject<BHApi> *_Nullable api);

NS_ASSUME_NONNULL_END
