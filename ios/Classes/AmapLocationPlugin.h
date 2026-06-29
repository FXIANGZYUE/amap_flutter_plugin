#import <Flutter/Flutter.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface AmapLocationPlugin : NSObject <FlutterPlugin, AMapLocationManagerDelegate>
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) FlutterMethodChannel *channel;
@end
