//
//  FBHelper.m
//  Ldiw
//
//  Created by Lauri Eskor on 2/26/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "FBHelper.h"
#import "User.h"
#import "Database+Server.h"
#import "LoginRequest.h"

@implementation FBHelper

+ (BOOL)FBSessionOpen {
  BOOL result = YES;
  if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
    [FBHelper openSession];
    result = YES;
  } else {
    result = FBSession.activeSession.isOpen;
  }
  return result;
}

+ (void)openSession {
  MSLog(@"Open FB session");
  [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session,FBSessionState state, NSError *error) {
    [self sessionStateChanged:session state:state error:error];
  }];
}

#pragma mark Facebook SDK
+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
  MSLog(@"FB session state changed to %u", state);
  switch (state) {
    case FBSessionStateOpen: {
      [[FBRequest requestForMe] startWithCompletionHandler:
       ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
           MSLog(@"FB session opened");
           User *currentUser = [[Database sharedInstance] currentUser];
           [currentUser setUid:user.id];
           [currentUser setToken:[[FBSession activeSession] accessToken]];
           [[Database sharedInstance] saveContext];
           
           NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:[[Database sharedInstance] currentUser].uid, kFBUIDKey, [[Database sharedInstance] currentUser].token, kAccessTokenKey, nil];
           [LoginRequest logInWithParameters:parameters andFacebook:YES success:^(NSDictionary *success) {
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFBLoginSuccess object:nil];
           } failure:^(NSError *error) {
             MSLog(@"LoginRequest error: %@", error);
             if (error.code == kUserAlreadyLoggedInErrorCode) {
               MSLog(@"User Already Logged in");
               [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFBLoginSuccess object:nil];
             }
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFBLoginError object:nil];
           }];
         } else {
           MSLog(@"FB session open error %@", error);
           [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFBLoginError object:nil];
         }
       }];
    }
      break;
    case FBSessionStateClosed: {
      MSLog(@"FB SESSION CLOSED!");
    }
      break;
    case FBSessionStateClosedLoginFailed:
      // Once the user has logged in, we want them to
      // be looking at the root view.
      MSLog(@"FB session login failed");
      [FBSession.activeSession closeAndClearTokenInformation];
      
      break;
    default:
      break;
  }
  
  if (error) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationFBLoginError object:nil];
  }
}

@end
