//
//  LoginRequest.m
//  Ldiw
//
//  Created by sander on 2/20/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "LoginRequest.h"
#import "LoginViewController.h"
#import "LoginClient.h"
#import "Database+Server.h"
#import "Server.h"
#import "User.h"
#import "AFHTTPRequestOperation.h"

@implementation LoginRequest

#define kLoginPath @"?q=api/user/login.json"
#define kFBLoginPath @"?q=api/user/fbconnect.json"

+ (void)logInWithParameters:(NSDictionary *)parameters andFacebook:(BOOL)faceBookLogin success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure
{
  NSString *loginPath;
  if (faceBookLogin) {
    loginPath = kFBLoginPath;
  } else {
    loginPath = kLoginPath;
  }
  
  NSURL *url = [[[LoginClient sharedLoginClient] baseURL] URLByAppendingPathComponent:loginPath];
  MSLog(@"Login url %@", url);
  NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
  for (NSHTTPCookie *cookie in cookies)
  {
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
  }
  
  [[LoginClient sharedLoginClient] postPath:loginPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if ([responseObject isKindOfClass:[NSData class]]) {
      NSError *error;
      responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];

    }
    if (success) {

      [self loginUserToDatabaseWithDictionary:responseObject];
      success(responseObject);
    }
    
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    MSLog(@"Error %@", error);
    MSLog(@"%d", [operation.response statusCode]);
    NSError *myError = [[NSError alloc] initWithDomain:error
                        .domain code:[operation.response statusCode] userInfo:error.userInfo];

    failure(myError);
  }];
}

+ (void)loginUserToDatabaseWithDictionary:(NSDictionary *)inputDictionary {
  if (inputDictionary) {
    User *userinfo = [[Database sharedInstance] currentUser];
    userinfo.sessid = [inputDictionary objectForKey:@"sessid"];
    userinfo.session_name = [inputDictionary objectForKey:@"session_name"];
  }
}

@end
