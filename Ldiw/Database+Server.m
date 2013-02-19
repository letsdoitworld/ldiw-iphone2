//
//  Database+Server.m
//  Ldiw
//
//  Created by Lauri Eskor on 2/19/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//

#import "Database+Server.h"
#import "Server.h"

@implementation Database (Server)

- (void)addServerWithBaseUrl:(NSString *)baseUrl andSafeBBox:(NSString *)safeBBox {
  MSLog(@"Save server with baseUrl %@", baseUrl);
  
  // Note that returned api_base_url may or may not include a query portion ('?').
  // This requires correct handling for functions needing GET parameters:
  // if api_base_url includes '?', then additional GET parameters must be appended to URL using '&';
  // otherwise, the first GET parameter must be appended using '?'.
  
  NSString *suffix = @"?";
  NSArray *urlPartsArray = [baseUrl componentsSeparatedByString:@"?"];
  if ([urlPartsArray count] > 1) {
    suffix = [NSString stringWithFormat:@"?%@", [urlPartsArray objectAtIndex:1]];
  }
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"baseUrl == %@", baseUrl];
  Server *server = [self findCoreDataObjectNamed:@"Server" withPredicate:predicate];

  if (server) {
    [self.managedObjectContext deleteObject:server];
  }
  
  server = [Server insertInManagedObjectContext:self.managedObjectContext];
  [server setBaseUrlSuffix:suffix];
  [server setBaseUrl:baseUrl];
  [server setSafeBBox:safeBBox];
}

- (NSString *)serverBaseUrl {
  Server *server = [self findCoreDataObjectNamed:@"Server" withPredicate:nil];
  return server.baseUrl;
}

- (NSString *)serverSuffix {
  Server *server = [self findCoreDataObjectNamed:@"Server" withPredicate:nil];
  return server.baseUrlSuffix;
}

@end