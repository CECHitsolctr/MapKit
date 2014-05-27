//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@implementation MapKitView


-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
    NSDictionary *options = [[NSDictionary alloc] init];
    [self createViewWithOptions:options];
}

- (void)createViewWithOptions:(NSDictionary *)options {

    //This is the Designated Initializer
    
    NSLog(@"%@", options);
    
    // defaults
    float height = [options objectForKey:@"height"] ? [[options objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    float width = [options objectForKey:@"width"] ? [[options objectForKey:@"width"] floatValue] : self.webView.bounds.size.width;
    float x = [options objectForKey:@"xOrigin"] ? [[options objectForKey:@"xOrigin"] floatValue] : self.webView.bounds.origin.x;
    float y = [options objectForKey:@"yOrigin"] ? [[options objectForKey:@"yOrigin"] floatValue] : self.webView.bounds.origin.y;
    NSString *fallbackLink = [options objectForKey:@"fallbackLink"] ? [options objectForKey:@"fallbackLink"] : @"http://www.connectedafield.com/marketing/contact";
    NSString *page = [options objectForKey:@"page"] ? [options objectForKey:@"page"] : @"oldLocation";
    
    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
    self.mapView.showsUserLocation = YES;
    
    
    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
    CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];
    
    MKCoordinateRegion region=[self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord, diameter * (height / self.webView.bounds.size.width), diameter * (height / self.webView.bounds.size.width))];
    
    [self.mapView setRegion:region animated:YES];
    [self.childView addSubview:self.mapView];
    
    self.adImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"empty_ad"]];
    
    self.AdURL = fallbackLink;
    
    [self getAdForLocation:@{@"lat": [NSNumber numberWithFloat: [[options objectForKey:@"lat"] floatValue]], @"lng": [NSNumber numberWithFloat: [[options objectForKey:@"lon"] floatValue]], @"page": @"oldLocation"} completion:^(NSString *imageURL, NSString *adURL) {
        
        self.AdURL = adURL;
        
        if (imageURL) {
            self.adImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        } else {
            self.adImageView.image = [UIImage imageNamed:@"ad"];
        }
    }];
    
    //add the tap recognizer to the image and call the javascript file to open the page
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerAdTapped:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [self.adImageView addGestureRecognizer:singleTap];
    [self.adImageView setUserInteractionEnabled:YES];
    [self.adImageView setFrame:CGRectMake(0,63,self.childView.bounds.size.width,50)];
    
    [self.childView addSubview:self.adImageView];
    
    //puts textfield over the map if the page is newLocation
    if ([page isEqualToString:@"newLocation"]) {
        self.txtField = [[UITextField alloc] initWithFrame:CGRectMake(10, 155, 300, 40)];
        self.txtField.borderStyle = UITextBorderStyleRoundedRect;
        self.txtField.font = [UIFont systemFontOfSize:15];
        self.txtField.placeholder = @"Nickname";
        self.txtField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.txtField.keyboardType = UIKeyboardTypeDefault;
        self.txtField.returnKeyType = UIReturnKeyDone;
        self.txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.txtField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.txtField.delegate = self;
        [self.childView addSubview:self.txtField];
    }
    
    // Puts crosshair over the map
    UIImageView *crosshairView = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"crosshair_orange"]];
    [crosshairView setCenter:self.mapView.center];
    
    [self.childView addSubview:crosshairView];
    
    [[[self viewController] view] addSubview:self.childView];
}

- (void)initPlugin:(CDVInvokedUrlCommand *)command {
    self.mapView = [[MKMapView alloc] init];
    NSLog(@"Loading the plugin");
}

- (void)getAdForLocation:(NSDictionary *)location completion:(void (^)(NSString *imageURL, NSString *adURL))block {
    //send the get request
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.connectedafield.com/api/ad?page=%@&lat=%@&lng=%@",[location objectForKey:@"page"], [location objectForKey:@"lat"], [location objectForKey:@"lng"]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    
    //retreive the data from the server
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            block(nil, @"http://www.connectedafield.com/marketing/contact");
        } else {
            NSError *error = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (error) {
                block(nil, @"http://www.connectedafield.com/marketing/contact");
            } else {
                block([result objectForKey:@"image"], [result objectForKey:@"url"]);
            }
        }
    }];
}

-(void)bannerAdTapped:(UIGestureRecognizer *)gestureRecognizer {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"bannerAdClicked('%@')", self.AdURL]];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
	if (self.mapView)
	{
		[ self.mapView removeAnnotations:self.mapView.annotations];
		[ self.mapView removeFromSuperview];

		self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
		//[ self.imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
		self.imageButton = nil;

	}
	if(self.childView)
	{
		[ self.childView removeFromSuperview];
		self.childView = nil;
	}
    self.buttonCallback = nil;
}

- (void)clearMapPins:(CDVInvokedUrlCommand *)command
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)addMapPins:(CDVInvokedUrlCommand *)command
{

    NSArray *pins = command.arguments[0];

  for (int y = 0; y < pins.count; y++)
    {
        NSDictionary *pinData = [pins objectAtIndex:y];
		CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
		NSString *title=[[pinData valueForKey:@"title"] description];
		NSString *subTitle=[[pinData valueForKey:@"snippet"] description];
		NSInteger index=[[pinData valueForKey:@"index"] integerValue];
		BOOL selected = [[pinData valueForKey:@"selected"] boolValue];

        NSString *pinColor = nil;
        NSString *imageURL = nil;

        if([[pinData valueForKey:@"icon"] isKindOfClass:[NSNumber class]])
        {
            pinColor = [[pinData valueForKey:@"icon"] description];
        }
        else if([[pinData valueForKey:@"icon"] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *iconOptions = [pinData valueForKey:@"icon"];
            pinColor = [[iconOptions valueForKey:@"pinColor" ] description];
            imageURL=[[iconOptions valueForKey:@"resource"] description];
        }

		CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
		annotation.pinColor=pinColor;
		annotation.selected = selected;

		[self.mapView addAnnotation:annotation];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
	}

}

-(void)showMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView)
	{
        [self createViewWithOptions:command.arguments[0]];
	}
    [self.mapView setMapType:MKMapTypeHybrid];
	self.childView.hidden = NO;
	self.mapView.showsUserLocation = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)hideMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES) 
	{
		return;
	}
	// disable location services, if we no longer need it.
	self.mapView.showsUserLocation = NO;
	self.childView.hidden = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)changeMapType:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
	{
		return;
	}

    int mapType = ([command.arguments[0] objectForKey:@"mapType"]) ? [[command.arguments[0] objectForKey:@"mapType"] intValue] : 0;

    switch (mapType) {
        case 4:
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        case 2:
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [self.mapView setMapType:MKMapTypeStandard];
            break;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)saveNewLocation:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult = nil;
    NSString* locationString = [[NSString alloc] initWithFormat: @"%f, %f, %@", self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude,self.txtField.text];
    [self.txtField resignFirstResponder];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: locationString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)focusOnTextField:(CDVInvokedUrlCommand *)command {
    [self.txtField becomeFirstResponder];
}

- (void)showLoadingView:(CDVInvokedUrlCommand *)command {
    [SVProgressHUD showWithStatus:@"Saving Location" maskType:SVProgressHUDMaskTypeBlack];
}

- (void)hideLoadingView:(CDVInvokedUrlCommand *)command {
    [SVProgressHUD dismiss];
}

-(void)centerMapOnLocation:(CDVInvokedUrlCommand *)command {
    
    NSDictionary* options2 = command.arguments[0];
    
    CLLocationCoordinate2D centerCoord = { [[options2 objectForKey:@"lat"] floatValue] , [[options2 objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[options2 objectForKey:@"diameter"] floatValue];
    float height = ([options2 objectForKey:@"height"]) ? [[options2 objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    
	MKCoordinateRegion region=[self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                diameter*(height / self.webView.bounds.size.width),
                                                                                                diameter*(height / self.webView.bounds.size.width))];
    [self.mapView setRegion:region animated:YES];
    
}

//Might need this later?
/*- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.2;
    mapRegion.span.longitudeDelta = 0.2;

    [self.mapView setRegion:mapRegion animated: YES];
}


- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
{
    NSLog(@"region did change animated");
    float currentLat = theMapView.region.center.latitude;
    float currentLon = theMapView.region.center.longitude;
    float latitudeDelta = theMapView.region.span.latitudeDelta;
    float longitudeDelta = theMapView.region.span.longitudeDelta;

    NSString* jsString = nil;
    jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    [jsString autorelease];
}
 */


- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {
  
  if ([annotation class] != CDVAnnotation.class) {
    return nil;
  }

	CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
	NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];

	MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];

	if (annView!=nil) return annView;

	annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];

	annView.animatesDrop=YES;
	annView.canShowCallout = YES;
	if ([phAnnotation.pinColor isEqualToString:@"120"])
		annView.pinColor = MKPinAnnotationColorGreen;
	else if ([phAnnotation.pinColor isEqualToString:@"270"])
		annView.pinColor = MKPinAnnotationColorPurple;
	else
		annView.pinColor = MKPinAnnotationColorRed;

	AsyncImageView* asyncImage = [[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)];
	asyncImage.tag = 999;
	if (phAnnotation.imageURL)
	{
		NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL];
		[asyncImage loadImageFromURL:url];
	} 
	else 
	{
		[asyncImage loadDefaultImage];
	}

	annView.leftCalloutAccessoryView = asyncImage;


	if (self.buttonCallback && phAnnotation.index!=-1)
	{

		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		myDetailButton.tag=phAnnotation.index;
		annView.rightCalloutAccessoryView = myDetailButton;
		[ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

	}

	if(phAnnotation.selected)
	{
		[self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
	}

	return annView;
}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
	[ self.mapView selectAnnotation:annotation animated:YES];  
	
}

- (void) checkButtonTapped:(id)button 
{
	UIButton *tmpButton = button;
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)dealloc
{
    if (self.mapView)
	{
		[ self.mapView removeAnnotations:self.mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
        self.imageButton = nil;
	}
	if(self.childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
}

@end
