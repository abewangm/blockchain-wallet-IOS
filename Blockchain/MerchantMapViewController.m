//
//  MerchantMapViewController.m
//  Blockchain
//
//  Created by User on 12/18/14.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import "MerchantMapViewController.h"

#import "MerchantMapDetailViewController.h"

#import "Merchant.h"

#import "MerchantLocation.h"

#import "RootService.h"

#import "NSString+JSONParser_NSString.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MerchantMapViewController () <CLLocationManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (assign, nonatomic) CLLocationCoordinate2D location;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *startLocation;

@property (strong, nonatomic) NSMutableDictionary *allMerchants;
@property (strong, nonatomic) NSMutableDictionary *merchantsLocationAnnotations;
@property (strong, nonatomic) NSArray *filteredMerchants;

@property (strong, nonatomic) NSDictionary *visibleMerchantTypes;

@property (strong, nonatomic) NSOperationQueue *merchantLocationNetworkQueue;

@property (strong, nonatomic) CLLocation *lastCenterLocation;

@end

@implementation MerchantMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.merchantLocationNetworkQueue = [[NSOperationQueue alloc] init];
    [self.merchantLocationNetworkQueue setName:@"com.blockchain.merchantQueue"];
    
    self.allMerchants = [[NSMutableDictionary alloc] init];
    self.merchantsLocationAnnotations = [[NSMutableDictionary alloc] init];
    self.visibleMerchantTypes = [[NSMutableDictionary alloc] init];
    
    // Adding filter to indicate what business types to display, by default we show all of them
    // We store "merchant categories" and mark the category as visible by setting the "value" to "1".  If we want to
    // hide the category we set it to @0
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeBeverage]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeBar]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeFood]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeBusiness]];
    [self.visibleMerchantTypes setValue:@1 forKey:[NSString stringWithFormat:@"%lu", (unsigned long)BCMerchantLocationTypeOther]];

    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT);
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBarView];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_TOP_BAR_TEXT];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = BC_STRING_MERCHANT_MAP;
    [topBarView addSubview:headerLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
    closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
    closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    closeButton.center = CGPointMake(closeButton.center.x, headerLabel.center.y);
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:closeButton];
    closeButton.titleLabel.adjustsFontSizeToFitWidth = YES;

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // For iOS 8 we need to request authorization to get access to the user's location
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    [self addTrackingBarButtonItem];
    
    self.mapView.showsUserLocation = YES;
    
    [self updateDisplayedMerchants];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.locationManager stopUpdatingLocation];
    
    self.mapView.showsUserLocation = NO;
    
    [self.toolbar setItems:nil];
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
}

- (void)clearMerchantAnnotations
{
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MerchantLocation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    [self.merchantsLocationAnnotations removeAllObjects];
}

- (void)addTrackingBarButtonItem
{
    // Button to center user location on map
    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.toolbar.tintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [self.toolbar setItems:[NSArray arrayWithObjects:buttonItem, nil]];
}

- (void)updateDisplayedMerchants
{
    // Send approximate coordinates for merchant lookup
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URL_MERCHANT]];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:app.certificatePinner delegateQueue:self.merchantLocationNetworkQueue];
    session.sessionDescription = urlRequest.URL.host;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            DLog(@"Error retrieving Merchants: %@", [error localizedDescription]);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                NSArray *merchantData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                for (NSDictionary *merchantDict in merchantData) {
                    Merchant *merchant = [Merchant merchantWithDict:merchantDict];
                    if (!merchant) {
                        [self showErrorOnLoadingMerchant];
                        return;
                    }
                    [self.allMerchants setObject:merchant forKey:merchant.merchantId];
                }
                [self displayFilteredMerchants];
            });
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (void)displayFilteredMerchants
{
    // Filtering out displayable merchants from all the merchants we know about
    NSMutableArray *merchantsToAdd = [NSMutableArray arrayWithArray:[self.allMerchants allValues]];
    NSMutableArray *merchantsToRemove = [NSMutableArray new];
    for (Merchant *merchant in [self.allMerchants allValues]) {
        NSString *merchantType = [NSString stringWithFormat:@"%lu", (unsigned long)merchant.locationType];
        if ([[self.visibleMerchantTypes objectForKey:merchantType]  isEqual: @0]) {
            [merchantsToRemove addObject:merchant];
        }
    }
    
    // Removing the merchant from our collection and the mapview
    for (Merchant *merchant in merchantsToRemove) {
        MerchantLocation *location = [self.merchantsLocationAnnotations objectForKey:merchant.merchantId];
        [self.mapView removeAnnotation:location];
        [merchantsToAdd removeObject:merchant];
        [self.merchantsLocationAnnotations removeObjectForKey:merchant.merchantId];
    }
    
    self.filteredMerchants = [merchantsToAdd copy];
    
    // Adding new merchant annotations back to the map if they aren't on the map already
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Merchant *merchant in self.filteredMerchants) {
            if (![self.merchantsLocationAnnotations objectForKey:merchant.merchantId]) {
                MerchantLocation *location = [[MerchantLocation alloc] init];
                location.merchant = merchant;
                [self.merchantsLocationAnnotations setObject:location forKey:merchant.merchantId];
                [self.mapView addAnnotation:location];
            }
        }
    });
}

#pragma mark Actions

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cafeAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBeverage imageName:@"cafe" sender:sender];
}

- (IBAction)drinkAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBar imageName:@"drink" sender:sender];
}

- (IBAction)eatAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeFood imageName:@"eat" sender:sender];
}

- (IBAction)spendAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeBusiness imageName:@"spend" sender:sender];
}

- (IBAction)atmAction:(id)sender
{
    [self toggleFilterForMerchantType:BCMerchantLocationTypeOther imageName:@"atm" sender:sender];
}

- (void)toggleFilterForMerchantType:(BCMerchantLocationType)locationType imageName:(NSString *)imageName sender:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSString *merchantType = [NSString stringWithFormat:@"%lu", (unsigned long)locationType];
    if ([[self.visibleMerchantTypes objectForKey:merchantType]  isEqual: @1]) {
        // We need to deactivate it
        [self.visibleMerchantTypes setValue:@0 forKey:merchantType];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"marker_%@_off", imageName]] forState:UIControlStateNormal];
    } else {
        // Activate it
        [self.visibleMerchantTypes setValue:@1 forKey:merchantType];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"marker_%@", imageName]] forState:UIControlStateNormal];
    }
    [self displayFilteredMerchants];
}

- (void)showErrorOnLoadingMerchant
{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_MERCHANT_DIRECTORY_UNAVAILABLE preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self closeButtonClicked:nil];
    }];
    [errorAlert addAction:okAction];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - CCLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog(@"LocationManager: didFailWithError: %@", [error description]);
    
    [self.locationManager stopUpdatingLocation];

    switch ([error code]) {
        case kCLErrorLocationUnknown:{
            // This also happens in airplane mode
            DLog(@"LocationManager: location unknown.");
        }
        break;
        case kCLErrorNetwork:{
            // This is the usual airplane mode/no connection error
            DLog(@"LocationManager: network error.");
        }
        break;
        case kCLErrorDenied:{
            // The user has denied location access
            DLog(@"LocationManager: denied.");
        }
        break;
        default:{
            DLog(@"LocationManager: unknown location error.");
        }
        break;
    }
    
    // Default to London
    CLLocationCoordinate2D londonCoordinate;
    londonCoordinate.latitude = 51.508663f;
    londonCoordinate.longitude = -0.117380f;
    [self showUserOnMapAtLocation:londonCoordinate];
}

- (void)showUserOnMapAtLocation:(CLLocationCoordinate2D)location
{
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location, 0.2 * METERS_PER_MILE, 5 * METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!self.startLocation) {
        self.startLocation = userLocation.location;
        
        // We need to update the merchant locations on the map
        CLLocationCoordinate2D userLocationCoordinate;
        
        userLocationCoordinate.latitude = userLocation.coordinate.latitude;
        userLocationCoordinate.longitude = userLocation.coordinate.longitude;
        
        [self showUserOnMapAtLocation:userLocationCoordinate];
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    DLog(@"MapView didFinishLoadingMap");
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MerchantLocation";
    
    if ([annotation isKindOfClass:[MerchantLocation class]]) {
        UIImage *pinImage;
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [infoButton setFrame:CGRectMake(0, 0, CGRectGetWidth(infoButton.frame) + 10, CGRectGetHeight(infoButton.frame))];
            [infoButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
            [annotationView setRightCalloutAccessoryView:infoButton];
        }
        
        MerchantLocation *merchantLocation = (MerchantLocation *)annotation;
        switch (merchantLocation.merchant.locationType) {
            case BCMerchantLocationTypeBeverage:
                pinImage = [UIImage imageNamed:@"marker_cafe"];
                break;
            case BCMerchantLocationTypeBar:
                pinImage = [UIImage imageNamed:@"marker_drink"];
                break;
            case BCMerchantLocationTypeFood:
                pinImage = [UIImage imageNamed:@"marker_eat"];
                break;
            case BCMerchantLocationTypeBusiness:
                pinImage = [UIImage imageNamed:@"marker_spend"];
                break;
            case BCMerchantLocationTypeOther:
                pinImage = [UIImage imageNamed:@"marker_atm"];
                break;
            default:
                break;
        }
        
        annotationView.image = pinImage;
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[MerchantLocation class]]) {
        MerchantMapDetailViewController *merchantDetail = [[MerchantMapDetailViewController alloc] initWithNibName:@"MerchantDetailView" bundle:[NSBundle mainBundle]];
        MerchantLocation *merchantLocation = view.annotation;
        merchantDetail.merchant = merchantLocation.merchant;
        [self presentViewController:merchantDetail animated:YES completion:nil];
    }
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (self.toolbar.items == nil ) {
        // The only way to stop the spinner on the trackingBarButtonItem is to change the mapView's userTrackingMode, which calls this delegate method. When exiting from an alertView, do not prompt the user again for permissions.
        return;
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied) {
            // Ask to go to Settings for the app to enable location services
            [self askUserToEnableLocationServicesInSettingsForApp];
        }
    } else {
        [self askUserToEnableLocationServicesGlobally];
        // Ask to go to Settings in Privacy to globally enable location services
    }
}

- (void)askUserToEnableLocationServicesInSettingsForApp
{
    UIAlertController *alertToEnableLocationServicesInSettingsForApp = [UIAlertController alertControllerWithTitle:BC_STRING_MERCHANT_MAP_ASK_TO_ENABLE_LOCATION_SERVICES_ALERTVIEW_TITLE message:BC_STRING_MERCHANT_MAP_ASK_TO_ENABLE_LOCATION_SERVICES_ALERTVIEW_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
    [alertToEnableLocationServicesInSettingsForApp addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.toolbar setItems:nil];
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        [self addTrackingBarButtonItem];
    }]];
    [alertToEnableLocationServicesInSettingsForApp addAction:[UIAlertAction actionWithTitle:BC_STRING_GO_TO_SETTINGS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            DLog(@"Going to settings");
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL];
    }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertToEnableLocationServicesInSettingsForApp animated:YES completion:nil];
    });
}


- (void)askUserToEnableLocationServicesGlobally
{
    UIAlertController *alertToEnableLocationServicesInSettingsForApp = [UIAlertController alertControllerWithTitle:BC_STRING_MERCHANT_MAP_ASK_TO_ENABLE_LOCATION_SERVICES_ALERTVIEW_TITLE message:BC_STRING_MERCHANT_MAP_ASK_TO_ENABLE_LOCATION_SERVICES_ALERTVIEW_MESSAGE_GLOBALLY_IOS_8_AND_ABOVE preferredStyle:UIAlertControllerStyleAlert];
    [alertToEnableLocationServicesInSettingsForApp addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.toolbar setItems:nil];
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
        [self addTrackingBarButtonItem];
    }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertToEnableLocationServicesInSettingsForApp animated:YES completion:nil];
    });
}

@end
