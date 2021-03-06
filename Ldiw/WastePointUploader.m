//
//  WastePointUploader.m
//  Ldiw
//
//  Created by Johannes Vainikko on 2/28/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "WastePointUploader.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "Database+Server.h"
#import "Database+WP.h"
#import "User.h"
#import "Reachability.h"
#import "Image.h"
#import "CustomValue.h"

#define kCreateNewWPPath @"?q=api/wp.json"

@implementation WastePointUploader


+ (void)uploadWP:(WastePoint *)point withSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  NSString *lat = [NSString stringWithFormat:@"%g", point.latitudeValue];
  NSString *lon = [NSString stringWithFormat:@"%g", point.longitudeValue];
  
  [parameters setObject:lat forKey:@"lat"];
  [parameters setObject:lon forKey:@"lon"];
  
  for (CustomValue *val in point.customValues) {
    [parameters setObject:val.value forKey:val.fieldName];
  }
  MSLog(@"UPLOADING NEW WP WITH INFO:%@", parameters);
  
  Image *image = point.images.anyObject;
  NSData *imgData = [NSData dataWithContentsOfFile:image.localURL];
  
  NSURL *serverBaseUrl = [NSURL URLWithString:[[Database sharedInstance] serverBaseUrl]];
  AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:serverBaseUrl];

  NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:kCreateNewWPPath parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    if (imgData) {
      [formData appendPartWithFileData:imgData name:@"photo_file_1" fileName:@"file" mimeType:@"application/octet-stream"];
    }
  }];
  [request setHTTPShouldHandleCookies:YES];
    
  AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    if ([responseObject isKindOfClass:[NSData class]]) {
      NSError *error;
      responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
    }
    MSLog(@"Wastepoint upload request response Response %@", responseObject);
    success(responseObject);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    MSLog(@"Error: %@", error);
    failure(error);
  }];
  
  MSLog(@"All header fields: %@", request.allHTTPHeaderFields);
  [httpClient enqueueHTTPRequestOperation:operation];
}

+ (void)uploadAllLocalWPs {
  NSMutableArray *localWPs = [NSMutableArray arrayWithArray:[[Database sharedInstance] listWastePointsWithNoId]];
  MSLog(@"LOCAL WPs COUNT: %i", localWPs.count);

  if (localWPs.count <= 0 ) {
    return;
  }
  
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  [reachability startNotifier];
  
  NetworkStatus status = [reachability currentReachabilityStatus];
  int userUploadSetting = [[Database sharedInstance] currentUser].uploadWifiOnlyValue;
  
  if(status == NotReachable)
  {
    //No internet
    MSLog(@"No Internet connection");
  }
  else if (status == ReachableViaWiFi && (userUploadSetting == ReachableViaWiFi || userUploadSetting == kUploadWifiAnd3G))
  {
    MSLog(@"-- Upload over WIFI");
    [WastePointUploader uploadAllLocalWPsWithArray:localWPs];
  }
  else if (status == ReachableViaWWAN && userUploadSetting == kUploadWifiAnd3G)
  {
    MSLog(@"-- Upload over 3G");
    [WastePointUploader uploadAllLocalWPsWithArray:localWPs];
  } else {
    MSLog(@"No 3G or WIFI reachable");
  }
}

+ (void)uploadAllLocalWPsWithArray:(NSMutableArray *)WPs {
  WastePoint *wp = [WPs objectAtIndex:0];
  [WPs removeObject:wp];
  __block WastePoint *blockWP = wp;
  
  [WastePointUploader uploadWP:wp withSuccess:^(NSDictionary* result) {
    NSDictionary *responseWP = [result objectForKey:[result.allKeys objectAtIndex:0]];
    [[[Database sharedInstance] managedObjectContext] deleteObject:blockWP];
    [[Database sharedInstance] createWastePointWithDictionary:responseWP forViewType:ViewTypeNewPoint];
    
    MSLog(@"UPLOAD SUCCESSFUL FOR WP");
    
    if (WPs.count > 0) {
      [self uploadAllLocalWPsWithArray:WPs];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUploadsComplete object:nil];
    }
  } failure:^(NSError *error) {
    MSLog(@"UPLOAD FAILED FOR: %@", wp);
  }];
}

@end
