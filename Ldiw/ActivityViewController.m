//
//  ActivityViewController.m
//  Ldiw
//
//  Created by sander on 2/18/13.
//  Copyright (c) 2013 Mobi Solutions. All rights reserved.
//
#import <FacebookSDK/FacebookSDK.h>
#import "DetailViewController.h"
#import "ActivityViewController.h"
#import "HeaderView.h"
#import "Database+Server.h"
#import "Database+WPField.h"
#import "Database+WP.h"
#import "WastepointRequest.h"
#import "WastePointCell.h"
#import "BaseUrlRequest.h"
#import "LoginViewController.h"
#import "DesignHelper.h"
#import "FBHelper.h"
#import "MBProgressHUD.h"
#import "WastePoint.h"
#import "Image.h"
#import "SuccessView.h"
#import "Constants.h"
#import "WastePointUploader.h"
#import "Image.h"
#import "CustomValue.h"
#import "PictureHelper.h"

#define kCellHeightWithPicture 160
#define kCellHeightNoPicture 80

@interface ActivityViewController ()
@property (strong, nonatomic) HeaderView *headerView;
@property (strong, nonatomic) SuccessView *successView;
@property (strong, nonatomic) NSArray *wastPointResultsArray;
@end

@implementation ActivityViewController
@synthesize tableView, headerView, successView, wastPointResultsArray, mapview, refreshHeaderView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setupPullToRefresh];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHud) name:kNotificationShowHud object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeHud) name:kNotificationRemoveHud object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeViewController) name:kNotificationDismissLoginView object:nil];
  
  [self.tabBarController setDelegate:self];
  
  UIImage *image = [UIImage imageNamed:@"logo_titlebar"];
  self.navigationItem.titleView = [[UIImageView alloc] initWithImage:image];
  
  //Segmented control in headerview
  
  UIImage *image2 = [UIImage imageNamed:@"feed_subtab_bg"];
  self.headerView = [[HeaderView alloc] initWithFrame:CGRectMake(0, 0, image2.size.width, image2.size.height)];
  [self.view addSubview:self.headerView];
  [self.headerView.nearbyButton addTarget:self action:@selector(nearbyPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.headerView.friendsButton addTarget:self action:@selector(friendsPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.headerView.showMapButton addTarget:self action:@selector(showMapPressed:) forControlEvents:UIControlEventTouchUpInside];
  
  self.headerView.nearbyButton.selected = YES;
  self.tableView.backgroundColor = kDarkBackgroundColor;
  
  //Tableview
  UINib *myNib = [UINib nibWithNibName:@"WastePointCell" bundle:nil];
  [self.tableView registerNib:myNib forCellReuseIdentifier:@"Cell"];
  [self setWastPointResultsArray:[[Database sharedInstance] listAllWastePoints]];
  [self.tableView reloadData];
  [self loadServerInformation];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = NO;
  self.tabBarController.tabBar.hidden = NO;
  if (self.wastePointAddedSuccessfully) {
    [self showSuccessBanner];
  }
  [self showLoginViewIfNeeded];
}

- (void)setupPullToRefresh {
  self.refreshHeaderView.delegate = self;
  [self.tableView addSubview:self.refreshHeaderView];
  [self.refreshHeaderView refreshLastUpdatedDate];
  [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

-(void)showSuccessBanner
{
  self.wastePointAddedSuccessfully = NO;
  self.navigationController.navigationBarHidden = YES;
  self.tabBarController.tabBar.hidden = YES;
  [[self.tabBarController.view.subviews objectAtIndex:0] setFrame:[[UIScreen mainScreen] bounds]];
  if (!successView) {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    successView = [[SuccessView alloc] initWithFrame:screenRect];
    successView.controller = self;
  }
  [self.view addSubview:self.successView];
  MSLog(@"Added wastepoint to DB: %@", [[Database sharedInstance] listWastePointsWithNoId]);
}

- (void)showLoginViewIfNeeded {
  BOOL userLoggedIn = [[Database sharedInstance] userIsLoggedIn];
  BOOL FBSessionOpen = [FBHelper FBSessionOpen];
  BOOL openLoginView = !(userLoggedIn || FBSessionOpen);
  if (openLoginView) {
    MSLog(@"User logged in %d, FBsessionOpen %d, open login view", userLoggedIn, FBSessionOpen);
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    [self presentViewController:loginVC animated:YES completion:nil];
  }
}

- (CGRect)tableViewRect
{
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  CGFloat screenHeight = screenRect.size.height;
  CGFloat tableviewheight = screenHeight - self.navigationController.navigationBar.bounds.size.height-self.tabBarController.tabBar.bounds.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.headerView.bounds.size.height;
  CGRect rect = CGRectMake(0, self.headerView.bounds.size.height, screenRect.size.width, tableviewheight);
  return rect;
}

- (void)setUpTabelview
{
  self.tableView = [[UITableView alloc] initWithFrame:[self tableViewRect]];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.view addSubview:tableView];
  UINib *myNib = [UINib nibWithNibName:@"WastePointCell" bundle:nil];
  [self.tableView registerNib:myNib forCellReuseIdentifier:@"Cell"];
  self.tableView.backgroundColor = kDarkBackgroundColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [self setupPullToRefresh];
  [self.tableView reloadData];
}

- (void)nearbyPressed:(UIButton *)sender
{
  self.headerView.nearbyButton.selected = YES;
  self.headerView.friendsButton.selected = NO;
  self.headerView.showMapButton.selected = NO;
  if (!self.tableView) {
    [self setUpTabelview];
  }
}


- (void)setUpMapView
{
  mapview = [[MapView alloc] initWithFrame:[self tableViewRect]];
  self.mapview.delegate = self;
  [self.view addSubview:mapview];
}

- (void)friendsPressed:(UIButton *)sender
{
  self.headerView.nearbyButton.selected = NO;
  self.headerView.friendsButton.selected = YES;
  self.headerView.showMapButton.selected = NO;
}

- (void)showMapPressed:(UIButton *)sender
{
  if ([[LocationManager sharedManager] locationServicesEnabled])
  {
  self.headerView.nearbyButton.selected = NO;
  self.headerView.friendsButton.selected = NO;
  self.headerView.showMapButton.selected = YES;
  [self.tableView removeFromSuperview];
  self.tableView = nil;
  [self setUpMapView];
  } else {
     [self showHudWarning];
  }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
  if (viewController == [tabBarController.viewControllers objectAtIndex:1]) {
    {
      if ([[LocationManager sharedManager] locationServicesEnabled]) {
        UIActionSheet  *sheet = [[UIActionSheet alloc]
                                 initWithTitle:NSLocalizedString(@"pleaseAddPhotoTitle", nil)
                                 delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"cancel",nil) destructiveButtonTitle:NSLocalizedString(@"skipPhoto",nil)
                                 otherButtonTitles:NSLocalizedString(@"takePhoto",nil),NSLocalizedString(@"chooseFromLibrary",nil), nil];
        sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [sheet showInView:self.tabBarController.tabBar];
      } else {
        [self showHudWarning];
      }
      
    }
    return NO;
  }
  return YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  //self.tabBarController.selectedIndex = 0;
  if (buttonIndex == 1) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
      [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
      [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    picker.delegate = self;
    self.tabBarController.selectedIndex = 0;
    [self presentViewController:picker animated:YES completion:nil];
  } else if (buttonIndex == 2) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setDelegate:self];
    [self presentViewController:picker animated:YES completion:nil];
    self.tabBarController.selectedIndex = 0;
  } else if (buttonIndex != 3) {
    self.tabBarController.selectedIndex = 0;
    [self openDetailViewWithImage:nil];
  }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *cameraImage = [info objectForKey:UIImagePickerControllerOriginalImage];
  DetailViewController *detail = [[DetailViewController alloc] initWithImage:cameraImage];
  detail.controller = self;
  [self.navigationController pushViewController:detail animated:NO];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openDetailViewWithImage:(UIImage *)image {
  DetailViewController *detail = [[DetailViewController alloc] initWithImage:image];
  detail.takePictureButton.alpha = 1.0;
  detail.controller = self;
  [self.navigationController pushViewController:detail animated:NO];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionamm
{
  return self.wastPointResultsArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  WastePoint *selectedPoint = [self.wastPointResultsArray objectAtIndex:indexPath.row];
  DetailViewController *detailView = [[DetailViewController alloc] initWithWastePoint:selectedPoint andEnableEditing:NO];
  [self.navigationController pushViewController:detailView animated:YES];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WastePointCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (!cell) {
    cell = [[WastePointCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
  }

  WastePoint *point = [self.wastPointResultsArray objectAtIndex:indexPath.row];
  [cell setWastePoint:point];
  return cell;
}

- (void)showHudWarning
{
  MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.tabBarController.selectedViewController.view];
  
  [self.tabBarController.selectedViewController.view addSubview:hud];
  hud.delegate = self;
  hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin_1"]];
  hud.mode = MBProgressHUDModeCustomView;
  hud.opacity = 0.8;
  hud.color=[UIColor colorWithRed:0.75 green:0.75 blue:0.72 alpha:1];
  hud.detailsLabelText = @"LDIW needs permission to see your location to add/see wastepoints";
  hud.detailsLabelFont = [UIFont fontWithName:kFontNameBold size:17];
  [hud showWhileExecuting:@selector(waitForSomeSeconds) onTarget:self withObject:nil animated:YES];
}

- (void)waitForSomeSeconds {
  sleep(3);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  WastePoint *point = [wastPointResultsArray objectAtIndex:indexPath.row];
  if ([point.images count] > 0) {
    return kCellHeightWithPicture;
  } else {
    return kCellHeightNoPicture;
  }
}

- (void)loadWastePointList {
  CLLocation *currentLocation = [[Database sharedInstance] currentLocation];
  MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
  MKCoordinateRegion region = MKCoordinateRegionMake(currentLocation.coordinate, span);
  
  [WastepointRequest getWPListForArea:region withSuccess:^(NSArray* responseArray) {
    MSLog(@"Response array count: %i", responseArray.count);
    self.wastPointResultsArray = [NSArray arrayWithArray:responseArray];
    [self.tableView reloadData];
    [self doneLoadingTableViewData];    
  } failure:^(NSError *error){
    MSLog(@"Failed to load WP list");
    [self doneLoadingTableViewData];
  }];
}

- (void)loadServerInformation {
  [[Database sharedInstance] needToLoadServerInfotmationWithBlock:^(BOOL result) {
    if (result) {
      MSLog(@"Need to load base server information");
      [BaseUrlRequest loadServerInfoForCurrentLocationWithSuccess:^(void) {
        [self loadWastePointList];
      } failure:^(void) {
        MSLog(@"Server info loading fail");
        [self doneLoadingTableViewData];
      }];
    }
  }];
}

- (void)showHud {
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)removeHud {
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)removeViewController {
  [self dismissViewControllerAnimated:YES completion:^(void){}];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
  
  static NSString *identifier = @"MyLoc";
  if (annotation != self.mapview.userLocation) {
    
    MKPinAnnotationView *annotationView =
    (MKPinAnnotationView *)[self.mapview dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (annotationView == nil) {
      annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    } else {
      annotationView.annotation = annotation;
    }
    
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [rightButton setTitle:annotation.title forState:UIControlStateNormal];
    [annotationView setRightCalloutAccessoryView:rightButton];
    
    return annotationView;
  }
  
  return nil;
}


- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  
  if ([(UIButton*)control buttonType] == UIButtonTypeDetailDisclosure) {
    NSString *wp = [view.annotation title];
    WastePoint *selectedWP = [[Database sharedInstance] wastepointWithId:[wp integerValue]];
    NSLog(@"Wastepoint %@", selectedWP);
    DetailViewController *detailView = [[DetailViewController alloc] initWithWastePoint:selectedWP andEnableEditing:NO];
    [self.navigationController pushViewController:detailView animated:YES];
  }
}

#pragma mark - EGORefreshTableHeaderView delegate
- (EGORefreshTableHeaderView *)refreshHeaderView
{
  if (!refreshHeaderView){
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.tableView.frame.size.width, self.tableView.bounds.size.height)];
  }
  return refreshHeaderView;
}

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
  [self loadServerInformation];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
  return NO;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
  return [NSDate date];
}

- (void)doneLoadingTableViewData {
	[refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tableView];
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


@end
