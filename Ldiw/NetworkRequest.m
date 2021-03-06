//
//  NetworkRequest.m
//  Ldiw
//
//  Created by Lauri Eskor on 2/18/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "NetworkRequest.h"
#import "AFJSONRequestOperation.h"
#import "Database+Server.h"
#import "LocationManager.h"


@implementation NetworkRequest

+ (id)sharedHTTPClient
{
  static NetworkRequest *_sharedClient = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSURL *serverBaseUrl = [NSURL URLWithString:[[Database sharedInstance] serverBaseUrl]];
    _sharedClient = [[NetworkRequest alloc] initWithBaseURL:serverBaseUrl];
  });

  NSURL *serverBaseUrl = [NSURL URLWithString:[[Database sharedInstance] serverBaseUrl]];
  if (![_sharedClient.baseURL isEqual:serverBaseUrl]) {
    MSLog(@"Change base url for shared client");
    _sharedClient = [[NetworkRequest alloc] initWithBaseURL:serverBaseUrl];
  }
  
  return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
  if (!url) {
    return nil;
  }
  self = [super initWithBaseURL:url];
  if (!self) {
    return nil;
  }
    
  [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
  self.parameterEncoding = AFJSONParameterEncoding;
  return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
  NSString *pathWithPrefix = [NSString stringWithFormat:@"%@/%@", [[Database sharedInstance] serverSuffix], path];
  NSMutableURLRequest *request = [super requestWithMethod:method path:pathWithPrefix parameters:parameters];

  NSString *language = [LocationManager getPhoneLanguage];
  if (language) {
    [request setValue:language forHTTPHeaderField:kLanguageCodeKey];
  }
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPShouldHandleCookies:YES];
  return request;
}

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation
{
  MSLog(@"Enque operation with method %@ and header %@", operation.request.HTTPMethod, operation.request.allHTTPHeaderFields);
  [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRea)
   {
     // NSLog(@"DOWNLOAD PROGRESS %i, %lld, %lld", bytesRead, totalBytesRead, totalBytesExpectedToRead);
   }];
  
  [super enqueueHTTPRequestOperation:operation];
}

@end
