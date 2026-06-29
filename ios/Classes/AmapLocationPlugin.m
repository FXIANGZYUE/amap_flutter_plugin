#import "AmapLocationPlugin.h"
#import <CoreLocation/CoreLocation.h>

@implementation AmapLocationPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"com.example.amap_flutter_plugin/location"
              binaryMessenger:[registrar messenger]];
    AmapLocationPlugin* instance = [[AmapLocationPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        NSString *apiKey = call.arguments[@"apiKey"];
        [self initLocation:apiKey];
        result(nil);
    } else if ([@"getLocation" isEqualToString:call.method]) {
        [self getLocation:result];
    } else if ([@"startLocationStream" isEqualToString:call.method]) {
        [self startLocationStream];
        result(nil);
    } else if ([@"stopLocationStream" isEqualToString:call.method]) {
        [self stopLocationStream];
        result(nil);
    } else if ([@"dispose" isEqualToString:call.method]) {
        [self dispose];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initLocation:(NSString *)apiKey {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
    
    [AMapLocationServices updatePrivacyShow:YES privacyInfo:YES];
    [AMapLocationServices updatePrivacyAgree:YES];
    
    [AMapLocationServices sharedServices].apiKey = apiKey;
    
    self.locationManager = [[AMapLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.locationManager.locationTimeout = 10;
}

- (void)getLocation:(FlutterResult)result {
    if (!self.locationManager) {
        result([FlutterError errorWithCode:@"NOT_INIT" message:@"Location manager not initialized" details:nil]);
        return;
    }
    
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *reGeocode, NSError *error) {
        if (error) {
            result([FlutterError errorWithCode:@"LOCATION_FAILED" message:error.localizedDescription details:nil]);
            return;
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"latitude"] = @(location.coordinate.latitude);
        dict[@"longitude"] = @(location.coordinate.longitude);
        dict[@"accuracy"] = @(location.horizontalAccuracy);
        dict[@"provider"] = @"amap";
        
        if (reGeocode) {
            dict[@"address"] = reGeocode.formattedAddress ?: @"";
            dict[@"province"] = reGeocode.province ?: @"";
            dict[@"city"] = reGeocode.city ?: @"";
            dict[@"district"] = reGeocode.district ?: @"";
            dict[@"country"] = @"中国";
        }
        
        result(dict);
    }];
}

- (void)startLocationStream {
    if (!self.locationManager) return;
    
    self.locationManager.distanceFilter = 10;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocationStream {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)dispose {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
        self.locationManager.delegate = nil;
        self.locationManager = nil;
    }
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    if (!location) return;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"latitude"] = @(location.coordinate.latitude);
    dict[@"longitude"] = @(location.coordinate.longitude);
    dict[@"accuracy"] = @(location.horizontalAccuracy);
    dict[@"provider"] = @"amap";
    
    if (reGeocode) {
        dict[@"address"] = reGeocode.formattedAddress ?: @"";
        dict[@"province"] = reGeocode.province ?: @"";
        dict[@"city"] = reGeocode.city ?: @"";
        dict[@"district"] = reGeocode.district ?: @"";
        dict[@"country"] = @"中国";
    }
    
    [self.channel invokeMethod:@"onLocationUpdate" arguments:dict];
}

- (void)dealloc {
    [self dispose];
}

@end
