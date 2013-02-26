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

#define kLoginPath @"user/login.json"
#define kFBLoginPath @"http://test.letsdoitworld.org/?q=api/user/fbconnect.json"

+ (void)logInWithParameters:(NSDictionary *)parameters andFacebook:(BOOL)faceBookLogin success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure
{
  NSString *loginPath;
  if (faceBookLogin) {
    loginPath = kFBLoginPath;
  } else {
    loginPath = kLoginPath;
  }
  
  [[LoginClient sharedLoginClient] postPath:loginPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
      User *userinfo = [[Database sharedInstance] currentUser];
      userinfo.sessid = [responseObject objectForKey:@"sessid"];
      userinfo.session_name = [responseObject objectForKey:@"session_name"];
    }
    if (success) {
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

@end