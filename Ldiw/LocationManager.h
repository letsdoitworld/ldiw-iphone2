//
//  LocationManager.h
//  Munizapp
//
//  Created by Lauri Eskor on 11/12/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate> {
  void (^_locationBlock)(CLLocation *currentLocation);
  void (^_errorBlock)(NSError *error);
  void (^_geocodeBlock)(NSArray *placemarks);
}

@property (nonatomic, strong) CLLocationManager *locManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSDate *locationManagerStart;

+ (LocationManager *)sharedManager;
- (void)locationWithBlock:(void (^)(CLLocation *currentLocation)) locationBlock errorBlock:(void (^)(NSError *error))errorBlock;
- (void)reverseGeoCodeLocation:(CLLocation *)locationToCode withBlock:(void (^)(NSArray *placemarks)) geocodeBlock errorBlock:(void (^)(NSError *error))errorBlock;

@end
