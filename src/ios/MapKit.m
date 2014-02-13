//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;
@synthesize AdURL;
@synthesize txtField;


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

    // defaults
    float height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    float width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] floatValue] : self.webView.bounds.size.width;
    float x = ([options objectForKey:@"xOrigin"]) ? [[options objectForKey:@"xOrigin"] floatValue] : self.webView.bounds.origin.x;
    float y = ([options objectForKey:@"yOrigin"]) ? [[options objectForKey:@"yOrigin"] floatValue] : self.webView.bounds.origin.y;
    NSString* page = ([options objectForKey:@"page"]) ? [options objectForKey:@"page"] : @"oldLocation";
   // NSString* page=@"oldLocation";
   // BOOL atBottom = ([options objectForKey:@"atBottom"]) ? [[options objectForKey:@"atBottom"] boolValue] : NO;
    BOOL atBottom = NO;
    
    if(atBottom) {
        y += self.webView.bounds.size.height - height;
    }

    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x,y,width,height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
	self.mapView.showsUserLocation = YES;
	//self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];

	MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                diameter*(height / self.webView.bounds.size.width),
                                                                                                diameter*(height / self.webView.bounds.size.width))];
    [self.mapView setRegion:region animated:YES];
	[self.childView addSubview:self.mapView];
    
    
    //Puts ad over the map
     NSString* adImageURL=[self getAdURLAtCoordinateLat:[[options objectForKey:@"lat"] floatValue] Long:[[options objectForKey:@"lon"] floatValue] Page:page];
    
    UIImage* adImage= [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:adImageURL]]];
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithImage:adImage];
    //add the tap recognizer to the image and call the javascript file to open the page
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerAdTapped:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [imageView2 addGestureRecognizer:singleTap];
    [imageView2 setUserInteractionEnabled:YES];
    [imageView2 setFrame:CGRectMake(0,63,self.childView.bounds.size.width,50)];
    
    [self.childView addSubview:imageView2];
    
    //puts textfield over the map if the page is newLocation
        if ([page isEqualToString:@"newLocation"]) {
            self.txtField = [[UITextField alloc] initWithFrame:CGRectMake(10, 125, 300, 40)];
            self.txtField.borderStyle = UITextBorderStyleRoundedRect;
            self.txtField.font = [UIFont systemFontOfSize:15];
            self.txtField.placeholder = @"Nickname";
            self.txtField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.txtField.keyboardType = UIKeyboardTypeDefault;
            self.txtField.returnKeyType = UIReturnKeyDone;
            self.txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.txtField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            self.txtField.delegate=self;
            [self.childView addSubview:txtField];
        }
    
    
    
    
    // Puts crosshair over the map
    NSString *base64String = @"data:image/png;base64,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";
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL: [NSURL URLWithString:base64String]]]];
    [imageView setCenter:self.mapView.center];
    
    [self.childView addSubview:imageView];
    
	[ [ [ self viewController ] view ] addSubview:self.childView];
    //[self.childView bringSubviewToFront:imageView];
    
}

- (NSString*)getAdURLAtCoordinateLat:(double)lat Long:(double)lng Page:(NSString*)page {
    //send the get request
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.connectedafield.com/api/ad?page=%@&lat=%f&lng=%f",page,lat,lng]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    
    //retreive the data from the server
    NSError *error;
    NSURLResponse *response;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSString* adImageURL = [[NSString alloc] init];
    //if there is no response from the server, display the defalut ad
    if (responseData==nil) {
        adImageURL=@"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAScAAAAyCAMAAAAp6O3vAAADAFBMVEWSdlq4YCe/hVh9OxFcLxK0dEV8WTyJQhQKCQmhbUTUzMHTZR+amZhoRyziax98SiebXTHKaiztbh5STUiZTBs6NS5OSUTLw7dCJg9oNhWtUxmlnpcvLCmunILhcytWUU7AvryUioAfHBmyqqFtaWZIREBdWVcVEQ4iEwaejG9POyG4s67U0tHPzcxxQB7HvKcOBQCJc1e/urN+eXapnY6wr61wXEA9ODWelpBmYl7BtZ6Zh2ulknZCPjuMhH3GxcODfnt7Z0q7sZyoo5+Oi4qqqagsHA1GNB7n5eQtHxE1JBJ4dXTGXRtRSEDf3t10cG6bi3VeV003MCpZRy3r6+v6cx25rZaHhYJ+dW2DdmaQgW3Z2Nbw8PCUkY5dSzFjUTWAblOUgmr19fRpVjtxZ1+He3CwpJC3qI9OPSeLeWBWQig7KhcmGA2Rf2NjWFGbj3+RhHBqWUIcEQlmWk97cGZwYVOWiXmvoIlkVDxuXUeml4CMf3JzYUg/LxxXT0c6LSNvZFuRhHWBb1lIOCQyJRmgkXyom4ZOPy0WDAb4dCAwKCFrXUppX1f6+vp1ZE02JxqUhnCMfGYnHxqFd2pwY09mW1M4LSZ4altmWkdXRjJ1aFx7a1NeUkehlYN2bGOIfGpTQzFYSDaBdGFsX06ViXMvIhYtJB5uYlhdTkGAc2U6LB9bSzhSQi2Ec1w4Kh1CMiJqWkg/NC1qXVJURjZRRT4hGBJ6bWCbjnlyZVNURz5gUT5fTjhvX01ORDxXST5yZVdSRDViU0RHPDaGdmJcT0eHemVkVkhUSkJtYFNiVEFURzphVElDNy8/Myn+/v5KOilDNipeUUN3Z1JQQTNnWUt+cV9dUksxJR0fFQ7/eCF7a1dXTENAMiZZTD52aFdGOCkqHhYtIhpGOS1jVkx8bls8MSpNQDVqXE5EOjNSRDk9LyE2KyNBNi5MQTpPQjdaTkNKPzdKPTM8MCY0KCBDNSZmV0OMf2r9diFHOzFcTT1NPjFYSjpKPC4mGxP0cyH///9m4kiDAAAyuUlEQVR42lSZCUBaV9r3fb+ZLvO2M923afN2b5om7bSZJk3GLM2krYlTU5d0Rk1iNGrjEjWu0bhv0ajRuOEaN1RAUNnEKAKiCAgYRRCMCLLIJjuCZR0+oLFNH8Bzz7nnnsP58X+e+5yrDyosa0W+ZeELhYDtBeWoY3qjjC9fUlK1NLrWOKHlGi2IVa5C6FzPTGmCV1eU+s0zHboipYxpOKucEMt0ICZGVzYRI1NSrdY+eE/t7HxJVPbheOwGn0wvBlm0aIYWrd02LKwT+kzT9+fh3dWoXIJDUI4tGV+rDdzExkeGxM/23u+fKrk1t1w+B1sOh6+VA1tXVmy6dFkh3WDUGhaQGB4vA8+QQ6xkCBXVjAY0ZyiCXw0YlM4o1IyqBgBgrEo6Nni8YVAqrBQZnVwx95rNnt9mrRNL1oeYqKF129bWtElMmM1OiL6Mna1PnSSLS7EhftDAjoThfSG1N9d6lzsSorMT7RLxiIRqs5pL52dhtVGzMBQSvxyYE+G7zwdmrt7JtbNW7GKZbAllNs9bezaqySwy22ENs0/LHQ55rJ6rtowMwW9drYXCzL3WTKCVSLahMplEpslhv5UiXjrr1FGne/smzYGRIVHZ0fuSLkctJ/aGVchTNkYktHV+C4pY7TCXD5tv3sSG95tX+ufNgfGpgVHRgVcPH94TfXjPGrb8Zt6NqzkdNyNT94yb++vnJ1umh8gQpa6YrCQ7wFm5fDCGuNFS39vXZ8VnSBzNHKemIHgVgVNtL6StGhvSAIq0qqrV1ZGRLaatzEQzmapzsNERcT3mnl5o/qgVaMrvrZjOG7582Df68rH4kEViW0TS5bioPadOHSupjSpJDLkafzgP2gO0r+Nb2uI6fPOihhMir5pL2fKcpKunTt3wuT8HtHdTqWHMpW2D0kEULI6SaWAq37oC7+leq5gSbDhikUNGUuHH9s0dwfwAHr9FDptmyclbcjZLzhaL2aAyJ4O7zZPVWcn5tfHQHPd8+07FwVl1BPJZKlO4JNkQd2+i7k/NC3agwzenoGbidEuuY6q8Glu/jPWdjeuozy6pr00tv5t39Ubv2q37fSn3mZmELTbE4NYjLRdjmdBp8RCQiUYwOQR2RzsITeHgEBrFNgDh5NZohACpcFXqFCJEewdFaWW0jXXT1haevQEdjgjJyQvJqTWN5i9a51GJi9O20tqOaN/ITyKPXfZntbSVdJTCr+75BDtLtK6lYm8eS23DttqJhhE+sQ3av0bcyckrH7cNZERFJ+VFdPgww3JphPYwCN6woOpcn14h0lqALAHBRgRCzbXYnlm4jQ3BD8jwZ+uWtljMkUXiYt0Uex0cptWxtUtyWl3ZurFyG801alUj9q3RWqhfZHzqcDm0h1WmpC4t4S0D/KbetX74VD08v6nPPBdoH0VSmbntDvBOJry8A1u/WT27OVkSiF3+93LfT9eB9xptoAzDQjtV1p6BV7aTlO0SLV0yMAGR2TBgEx9pIcXMjAFIIilPWjkodfJIbkLSMZFRyFU0jIm2R2ysoaF1o5hqX1yujYOVtMHMk6P5qOlpuLWOBb58al92W2p0RN7hUmHLSlu2nTzse8oPtja6XN7be+t6PnQufyPd4ggf94POj6A2c+LWGrnIv+WlLk+xfHQOAtmAlDRm6XAqCp0mZztsZPBGS4tpvs+cU980CZ9chDTabC2OdZlMTCMyrdbFDSDYxmau49uVNPqSDJlh5M4Atg2qa0u20QqrX1tgbfZaNUvJWzB0LhmQeHFj9+Rmffb4zd75WzutWe1DOvfKMWottcVafn1ekJWZ2TgFvxU4f2OnZy2LTMQgtUEcRnKoHpdLL6RnoDXJakY62iCJlSglE0YdnjtDkgqDNEKpZrtKDRAitiuFUufYAlcoVVUKaRsm2sa1EdZZFrHUL683sRqemAj1P2tlmcDk0cWV6JDUqTpYUohfZM4APaviu17yZMmxy37hbf4lJW2bWT0VAvYGTUIovpkaNy+ww/vnRwmGjwNvptamkH3StYZOi4Fp6aQ359akdxYaJHhWC9PeYnXMhsPmdnqsYWRwcSYT0uIY0WqV9EyWmDnNrIZiNydZuQQbVb6lzZJvF+ILV3WyOjzZfz7Of7m+rW0KvE7ttID4Yi3SYAmlslbM1QLgNCGFD0SKtyW87YnkCUssRHCvEdVIAHePQ5vG5cRxMp9MsHR2WRQ1PEVyjYFUg1sAzajQM0a0BK0ASXAkXqGKguAqmgdFHIRTQxkUMbhpAMTnQoBIqDSuDooqDfJ1k9ZoNBWuL5ph2JzoUmxqYi/0u1GgbcNGHO3zDfFfXIwrif+kJIp1bWMtDibAfpIUVZqa6oft6OjJgeZvEHRGpdwadSwiInDN3IgckLmXPZvX1ifwKSCpF4LUBt0CJSioCBRUhESCCFRMRWuTVRBeO9UPrSgurjBvVrdCpreW6OtajF3Zzp5emVpMbeoBtvBZjeTFTIzhrEErNFrSxOSzo9ZSf0HrFhFikyAtFiStkCmZSAdtodZQJjlpiY4hLJAYquQZLo/jFgsbk0XXgpDk3BW7gCrDxPIN7RLjRI1aU4NTJ3MApBqAvnmmijKj0sSQcBK0iMfhAiYWFiZwKmmAyKlRrHJ5qm2GcEytLpNphavBDasGksGCN5ZNbyVC4djsJGxICdTftDjqIOONS6WwpuX8xMk4+DAszmwdqFwriSiZTbjsC08siQqJ3tOR2INaAoG40szJhH3HIi6fqq2gmdbBrQ7mdSxs1kdtCQAEBCmCgkQBM+pkjT4Zl5trz1yxAsPhfYHmpsxRW2MYtHUH2Bq2NEAn0doJNpTczmohbBA3J6s34WagvQLSYirsNKrQhnUWGGy1bm0A7dNs/joYpORLCvEYiLXpvmmeYGNkWMpAjaQJyfYMB6Fupizg6brGWAupkU7HaPHp6ZZ2jJpXJBXS9YCgGoAiBidtrlEEJDuFHACgq2tmJkgtBaGdRpJaFcRz6gukCN7gKm+mclUtFCmHypQTq071KiBdy9UbTBuO0dLa1JDhyIS8NRPLOmIDMoVl0MlFKzEfC18cnW/znySebdt3KsQcmVe71oM99sXhfTcPl1Z0kiQaFXMtJHLP1ehTe05hzYujVqTuer+52qdgm4KTcniKoGBFchWAIp2hbNPS1aDmgi9zmcU7FexMO3O8tSf8upxNszmQuiUtXkbLZIExdtbsDrR+rnd+DQVMkU9TJcoFd/ySE6ZtTAeRrWS281m5chtVYuJntfbeNaNW2DJSl1IXy1FQkhnoGqk+hqJvL9KB0sUZGbLOrhpJDdrSnmzBd6InQJ2krhiNhqfQcxRjGp5ThWY0x2iMGrRwG6dYAPGMXJ5RyKEINQVuNINpokLnyPTWuhKRFqxxigzbCzLZiMNeih2OztsTHbeWmm9CsVBg3khPXxts2Zo4mZO4fDcuEYX3nw2Ma/NNSsjJizh1M/LwMd82cjHCSOKBl30jv7j6xeEbVyMOJ5WU0pXkufs9PjVVimS3nAr0AQEFFGlQgYL3VQP+z8/96fk//b8ngbF8WzfEfr9+XvBTLFgusDe1dOogVHtfN6q6Cbp219zUb4Ze73ZkrpDZ7bIRi26dhpm2Eci0FbkjM5NFwNBYYZMbLYLJlZ35eQKSDkHKMhqlM7ESRjJlG8ex6GM6tUgbH0J3RyUDrpnCaOYxOkEyHkRs6eKIcM3bCIoU18xY1VOklC6dBW3hqjWa5HT1qrpAJNWIBmdUlYPqykq8rWzavq6kpI3phasLWwNLBNvWJKyiI/tyfMcnISV+iWCmki4Z8ReUZHesLOYnnbocH+Xnr2PUsTcXQ/blRQx3xF2/kZNzw7wFpq1vk6fMN5PyfP8dGf8Pn8PHjqXaTUbgzqZPwcygokZBycABCgI4BdKCl97688vP/PfnH3/+8cf/PvPEFzVFKSvVszuTfVntuC/+z23PuN/e4oXe2bvmtfqe3vAWFNCdgUHWBzontBgCC0yl8TFyMVtgBwqswNnW3pU1+PU+c0ssGdkoFsdKjDEZhTgJQ1gzgWjuknXen5ZAOG51cTldGhISsZBBxrfgRww1emMzB8BIxil420LkhIoO0S7pFlQ8jltoKiFJM7ZtHHPqG9K4orN2a35F9bRS5k7GtYVlNNMQRr41ioXF5WQnnIr2O7ycvyGnOWjgdfbNvOzwZf/U+NSOW8uJdeJrW92ZbUlJsJz6qZ7rWahqdlmZVldGvA6rvRkZffXfqb5Xo6P/HThqRJMEKT4KjXoMF6PX1Ch4zbiggK+efOH2w5//67Xbt3+8/cKTRcVN5uuCCnJx0As/33bbjz/e9tjDZ2RT4/WwtdleeMokqribTVCKZUiemKZ0sORiYgvK3t03mTUHFaz03C+fMo8v94a10KhEsZJq0BZpJ3QSBl6iIOVC5CsEWXqNprnIaIjhGOnUJSoEjCcwtUqkhRHDA6BJCwY0VwaRKanaIaXOYNG5gxBulcuRrkpnxlarGsYMG4lYbD50RWm0qNKMEwM2u2mjdejjRXg+1jc1ISkvMQ9a52DjWUSlQzDflp3qV5p1f3Q2vPS7HmvPPNF8uaN3Uc7fAhMcZ1nMpSG5nVa8E510Iylyz/LyMd9ewT15Hedd65SPRs1RDzZTgpM5eg7llYDn/+uB9Jv9+OLzzRibjbZO/9cTPz5+4ufvNa2b/b099Zs9aztMwa3GTqSAf19gV2LkSgxkGjiF2syaXB6fh/bPwpaX55fXzPCVTAeR7MC3p2vpnUsSqozeZaGF2ZnFnYZm3QSoSMHrWmDU8LQYiE1O0Dl5Oq7WHe95jDKdRIZpFA+l02kSutqoNG5rJkSDGpFTDfg8LRhQyIQllo7W0eiFIoPI6QCbFs1DFfa60b7lhHjfw5FJITCoqYxM3tjgj2xMVbcllEAroPltJXn+QxB2HaolD04Aryt1lnX8ek/4ck8FzcAuX8u5cfVUXm3H8M2c0iakVhPbSPR5qUrBk6pqNIoCBOBD2f88fJyFV1Q//5XBUxq0GVN/uf17TjObvYLNKcH4Gjy8m9mY1cxraQVu3sdDcsntxYLJpk3z3M78SjdrfqcJujyXU9sPb7ond7AzbQTqliwjXdsul1GZhenspfbGdFp710TMhJQjYVhAOl47xiChGlUTDIOOuiBOxysxOnwxUizBKBd4WrGBZDBK1E7FjFPIGKt0og32qdJEh1A0Ix1DMAaWgD1+w9jEDVsdPCok74vIkJL4OBNrw0aznx3ljxICoyJm10b9clIjsuOuqbQ0IzulFxVLNy4YBhzLeZFJ2T38Zi1rcy3v5rGIWt+8jviOVCJVhm8k+yQjROoCFY7ToA4IVr6wK6bH7eFfX+EUzBz/n11v3OWkElgdkBTz5l14dYpAqytCKzqLtMh0Nyg2ubja/NPc1HgfKmwFNVVuXr45bA6cgwumNmgEMr871kYgKGmxBDpSuVTUaUmn6kC5pAkORaPjWXAgkjoZjejswis7J8RI0FBmLk2C1Ora0w1FyMKFIkOZTDfA0HDHZhBCrn5sjEQu3ZwaKJM2qHHbXL3FNlldap6NM4FtFfFRIYePnUqobfNHgTesAuIIisWa3VfrToLbIpMuh5iV1xZmjIVIS5kufZsrscf5RiVgodbtZHrhys2c2hu+l48di0i6GrlIbKlob/QJKFAj9KpVjcIZcPw3Nf0e1MvvaV5K8ADyVr7/+RdOThuZz87ahG5uLk7T8fqiGgCnK4CUwUZ2E8E7fb3dgea5FFZvLrDnbnjq8J7h5RuzPdXgdWIKG9jNtEMwtLBiApgs5oEk4naILJ2unqjRz3QlAzg1aVKekdRMtyjblemxdGYj1ZGutBg4E7xOhqUzfcmoY2zrNUKhVJi2LapSUEvz1+oqFYi0KobQyHeYalNhyyv56+nQhGOR0ZFJn8RVozbY1gq7YHQUTDR3+C5+FxWf40YwyRepdboRrthUp1SqiOGpHUk5MGjmNUWyDBx+K6djT23teH100j+IdbPVFVk+ryBwiMEAqZNS1fDcr2r6+eFD99sLxhvP3xjUPJLaw+/37nKqUmJ2qjdvjNum8UZtp4GX0axoLqK3ZyiRjS3sHTi0uwXVd9+6kiXYDFzLLr8xtRwOt6/YHcV9k8DN6difCOQvc5Wd7kDVNUHL4FuQEj0PRCHFMKQ8NVdfM0GKbVfGtluo7RZ68cQCSAKwxOiF0m2VfoJrwQFEeoCTy01bVTWM4c35WPPZBa0wbWF7dYhZPRkfkT1XMQCuDqn1TTp8KicOOzvf28qqsKO2xJip7GGr/+yN2uF9OddUaq7jfrVfXF5iaTXYBiYumstT/chKKUCzIOk3lzaxHbQMMLiYXmYOT832eUWEC14NpjirPhz5y65nPfz+D398442nnnGT2oXz2cNfAP7l2nu7nNSd9O5cQXcufqE5Q61PpnC6OLzYGnF7ES2jMVOeaZdD3H6Z1dodDl8urx2+sWLeLL8PnJ23hgtaNwnk3GJi2LtIMd3C6KpZQrajA0BoTmyMEJ2sUZM4hq6i9JpcnbiZh+DQNRKQfoajUXN4CIZ7T1egGHMqpCLAdpqI63RKVwfu58TVTtU5+CMjMu61zmJYage0aXNrazMQVnIsImEZ6nd3B4ayTpvArDprd3Y2FJV6LD4iem3LqbasLwdGXk6KjOu9TvC3btoEUanTOoBzRoMGCuxijWVkSSleZ9on6/d94sOpqlIMDhZIK996/uEjMb34xw8vnX770KXOp158JKI/iLxB3O16rz8988yunkgWBKkZwQhA4GIUjOQidxLN0yEtRiQJH0sQIzMdNiYLWA5HhW/2zK5h1wL7oN2zTfX9O+Pl5orcMKo7JcjIldEkOEu7RNZcRGmO5bhveDO65glJ6MREKIZXE4OgdFHcGz1hco1U3TwDSMalITQNg5RBp0Jf2eDOnWbUDU5uWoX7SdNsSD5ssezsetp293z+cH1bK9y/56cSv6QvElLrYak3zPmL4K0y/Lppth62KI+L2FcbMkUzCilLrJWSaHfSnVof5Zd6i1VXm7O1QOJWKpJpdiRCiqblQ5ex2cOzsKgOnwLPrUOkRldt/d/tR5J5/dk7rjOcO647l/744m1PyzNPv/zwF6H9cW+V4oVHnFadUoRIrQBQZqS8AgYpg0OJTUan8xYmQnW6RioSg2e1NxIbUwTm/jXs8LB1bnwSeGtn+Ub/fP1mKTUlE3wPQi5GGuhdenVRF6+oCx1TFMBrRjPSM9Lb0xnpsTwFB8RD12hUBTPSAo5ohiJVUwBjqhmVO0QI9VKnFL29rUd8vm005XRczi6JS5ysuOb2PPkcrDSvp7TaXNcyNxlRi41bXs5eu2v62GQbsoFH7XdLeiY7QrBTZjt/gquyDPVO1UbH3yiBzQ5np6IcceYN48SMs6pAawIphEuzOTk3k7AdfebaSB+dnDYg4Yv5xz/b9brXv3W5XGcoV9x/n33D0/jz66/ffqSrp4+/MrbL6b1B0cz2GEUqClBsNxdNoJNxyV0kXhfHcqJR11XcSW+nsbNaWruz2mbHJ+dvrsFzCeB7N6rD/3l9pXyO3R4mz8yC0KkThuYiHTIWlBzKKUgODSDhNPhc0JKkGV8Uy9GHNktxyYgZDkDEmQHgZhrUaEYDQ7qKVqchKGMNCumqCt3gXFhcLIlPiIxMXGzdOGuwDAiS/GBNJphAvNUyN5o/CTNVwxfv20fO2h0mZu8ovH+zNCk+0UbQGnn6ym3lNGxtOTsqatF6ay4RBR6ySfRc90QTxRg62FSxLz5iLtw8ad7swfrId/qBkOIWYMyjNPLhU/9yeTiBrniKj/760J0XPP29R06eg73Bxwe/3+X00iqC4v5ZhYAJkTt1FnXyFCBOISgDRwolSYrStWyqQ3DPPB8+1VNfAluehZPlbPl4/9rO3an5bgKzuJgZ1o2XUSW4jE630+o5XRRcDQngzinZEC2TalGDkhE4EgARhHPqcU4jjjGmMI5JFZUNuKqx7cHVKsRY5aDIKVV/7uwtjTgW/UnSZf8e8tmyCRXLN8/PXL0xIh4ZwrC/k1OH7C2sLev82dGKOnCfdXJtOKJkX+qoTSYUaZ1pSwR+aybsch+xjjVuKqMrjbQJlRCtXi9uQaFWpmrHmxbh94BlmSsbPr1TN/vm+3dakS88Src/OecBdD7Dy+nkH2/ffvHaG79geqbyvaqqr95zQ/NyevorxRhOobKgky+dOHHodGhNDYdS0Iyu4eFOvPnmkdNHQjOILMhmT+NPkNx7xblfFpPx8mnM31Jy/3kk9P0vaewUQsaX78aciMF1XQr9+6WvM74+ceLEu18XZSAl7S2y2DePHHn/mx9CmwcVyTFdX4ce/frE0a6/f1ATWiPkhAYd/eCjoNAPCo6e+KgBweBk3Ov+8qe74Vevswk2p4E0kpoUUQHM7CzKGBAqt8ponUux73bFHontzMDEpqxMQu4lhdT/LReT0QU6EVqUEUvn56akzktkW0y+aUlniQkNrQnNbbyX0g2v35mEr02yWnKZ62y6z2zO2nWB+W5fqzs8eZd/1OXldOKOp7gCf/HhH1b/ctsbt74bFFU1VB3f1dPeMXXaYAB6/0XXL3bn3AkpogYR8M75B976g4sHkBsYSOyj02c4egn49KPKpxq8BHTSfXDxbVCXZ6Zd+89MF1Vy8Mxu08VLDQXnXY/ZubH9j9UuNGyH/la7c/4kz6lfgtXGR0SMu6u8j4dsWwNg+sVfexwcKnKdI+S9/9s136KZF1ygDT6SaJLTRiyPfZc7nxZvtuWVR2P7gGe1uT735oDd402C3Efbkp//evTg/tf2738t4+DB991l98tP7fUG8dsvvv60QtQQ/NaHu/FprEElHeOccf1mF48OBnzweMOVGjz7xG7l74oA3undEx8VBTR7OJ0P1hX9jpOoJvTk42C+Vp35HaeGg4/VDow5Y1yP28WANB4YFpWUcNB1xvVsor+jt2565cqdZ7/55ptLly49e/TzZNcB6RcHXSc9dffn2Y/U1HOut00bKAhzg6DlFj246Gl3f7494zqTm52QFI+Fh4ltWT7dd1eaxq8TM3bcevLGoKP7D722//3Xst5/7f39+09nBR1/8vZtD6dnnnqZVbX3zy+/7AXqjeNjM4BvXY/bsw0zB37XcKFKf2T3+JAiwHh6t3KJ0kn/1MPpLVXM7zgBeG/+boRP3/Jy+k1BJ383fGWB6/fdVxcIVtiw78WLRx9cwPeUtk71tNy5OMZ1CrkLKjzzrMF1YWz+f11fOyvTqpyVUstqHfCM6yV+xdYKZsmhG5pxnXtaZBgYYg6dpX3qOmSGYqNm5/vu1837VPf1AwUpmHTMrt/F/PLD/PMXv9u51f9/Pz7KPl/ea2z4w26a7s4LGEZV0BWvS73zzkmvuE8G/+D1uXMn3zl5wTvOR86/e1zwigfJ2xTAEU/F0+UADtK536snUY13xacPfeu2Qx8pLF4QV9wjnPMevPTOhQOfnveO+umBC4cq3/H4hLuzp/c3DQAvpzOfHjhwwNvd9ZITD16M+Ml1yHnBFYr1g67N269cbLCB+Sg5E14/RXZdWL32vutrroG7pKwrJNgHWGdcH4qtJpvAMSA2oB+ca9gCTlUsd7S1tT84z+kpberfnDTDsD4r83P3WgnvYpJ343jCL3E8xcvpQlOX9z7oVdp7COVLnr3NLieZztjlVf9gw2rDB57+54Lf9OJqaFgNrvJK7ZLQ0+WK9/hfAZIjnsoBD6yPYrzCOX/c0PzAo6Ong78aG1NUiSZIZzwg3t77XtWrF7ykB8cGGy55Lvlw72rD4OpBz1V7Px8bXP18795VaZd35CqACCfd7xVk2ojc6vea6wP/f7hOm9vy4cvQKxcH64hyk60lJ2e50XUhmPWm6+s0/gJ3QVZYaLMtXnAdr0OBt5jE9e9YoAfngrccTdCKJjN28YAraBTmtxyVPVm95lO8DCxeIUNiX33+50f73Ge9nNq9SrkHvLy7/33GSVnRdj3/46+cqrR2W4an0zeVNRwE78Kdi3cuvHXI03AUkKuTMb3nvuV6igc/eOT2ThXZy+lfHqSn1TGHvJxIHE/1mzFFM0WP7lSvx3i6fvpeARpXcOjBxSt3PkJoEJbTXk7BRgBO6uF0ZpC7LZV+7lSIBr/2zPKDeNZkZ3qRnRbV2Wdrr5yvShx2naGZKxbjd65cDB4ZoRIXr6/BsGGuC5qc913/OStnqwonxNeGCOwLrg9XZUzm0IZ1yBPmXwH7x9VWjALvjx50HfWv74jrCMzuIfrMCazzBLauK+bJXQLPeZR9vsvD6WBnl1dm3h3LK9a7QMVjekLwaVMpXk5CbQzPUHP8reCv3vMGoLe5mEYWK+WBh5P+S2+L11tetR3xFMcPeJYajPYq4y1Nsxfb2zU1J2ICYtKNHM/EJ/fiijSI5g+Dv/rqvRmQyunV41eDng2wN/p/VFOQ3FWgKVBXxnj1dO2+acCU4Z2wwWHC/uQ6vX4q4n9dXYtTLOy+O+eDTR87iH7Y4dQ4gutCYYKb06ifO4NyWraG5C0XXK9eG2E30obA09+lu86piKX5k9BRe6Z4v+uHso56bHZ8znd1PuwwyHQ7Jr393fpf9y1/PvTAdT79iuvOEUvwkw8f2Rvv8TfsrcHPPfyV0yuZpsn3vZz4Jn6YQ5vONiL5v3CyOIArpS1ePQ28640aJ7w+UfamRxdfXfKKbvW0lxPDu7xHcesiqJp20eu53GbeGKAAAZhh6En6Va/fHRcpEELhyUe9vQO+UnXUy6nSRBtIA3n1VElGJR5wfVTqe3nc9W2ddbG0486VH2K7Qk8UQ+6VRwhcF0SfHHS9483wThw5nX6Wf8b1qsWgg5CvoZgDSvcN1W7294NDN5jyg64ftkKS4iMio9ryfUCYXEg7JpZPOLrrUj+/+FTfpydDDxwKDQoKev6vv9gf3goCCoKC3vrsN04i6vSil9N/Wu6ab15d2flprmPuNW9IIUyad3q7vZzqUrwtfM/qL6iOeNfLuOPxQuclD6cP24sfcfK6O+XmnJfTWJWiALc6UzC4rdMwOIXe6z4c3Map0jzK3LW/V+l/4SQaWddeQ3sn/Hw9k/jg3NgnSfEJZ+7ov+sxY6/82v8INNP9JfweS8E+cNadcx1fwGiXiFtuM7ivrIOaR1FyFJP4juuDHthl96O++HiYTxBDr+NrCQS+LM8rKO+j3r888cSfnnD/Z8r9+uy5zz57zv360xNPYv70/HMv/+Z3YzIQ6//XbS5QSWf7Hvfcdda593ZP9641c6p77zS38VQzTo9R08lyZhqlxtJuaTUHX1k+JsjEJJvEKDUfoJMPICmfiCKUqWDmA8S3hA+UBJQjEQ8hfIGKgHKQx+X++XeaadaasxfrL//9xy378//9vvu79/7rDnISws10KJOAjRJxtoDxdIvF5tDJrv5/KUsDv07LITCsAlz93WV3Jd5FP5DTrrS0l67K4vji+PjiU2t0eLGL0/0h3ciiSdI6l6rrffTIePxtPKlMEyawoWKwOH28dD4gpwfGgixje7GLUwFiabczhpZw2fvyR06foCYN+2Lx6T17QkNDT4due4Z2RrcmfeT8o9+5XXv3frh9r5+l8YDzm6x+NU3dp86zrhafva9t6WkLGRiVrx8COJVco391LSHxsFvvY2B7lS9PK2vK/icwoEBSfwEKePgbkHLgqt1fXv1zN7BbBWJ6Ow/cya++eQzMu3kYJIqwAwLbsvvZIZCTOlLTnZgCchL6gkKrAAfCj2LAsUx4BMT7Np5IJFCftl8vqrlX9EN/Ignk1AGsx6nuhfqcCD2ztpZq2g9yemTRLU98Aqq/n5/fN37bzs/ORoDNexlnC4z3QH1yzDaede5tS05I8I5yHtSe3IiMv6ijIeaMiMn83AqsM/pRHaBPQev6LERrawF/VHnAuZemXpqn8fryaE+AIdserKy3M6qFtQCnYPrda/S4u4HJbkNry703u85cIdUXpgCg/mH56d9VwIj4Xgna+5yvjwHd5ZsyFKTkrCtG2o+D0kMbjuq5CwL6btMTvOFc8imXbwDj4kMxaDoOgpy2UT1fulhXM0VhUCrTnyqOd13rsHTN54Fsj6b2tqrexpNuXI2zutzpqY65xxLdTOqsxXEPbN7L9NqhCgBvxQNZF+A/WVhCOj3ulPNeUr64+OL5Wrtp3lqn6TmJBPTJttt5Qpmk7bPMLVpMvMGzzu15tNXxRm2D3UMP6FNDS4h9sJE2bQM4eaTjb1z+OmffZTfdin5ZXzTyumZ0sDPlN/cR3sUP/61DeOemPls7t8KPAD1wTUkP1tfVvVNroGDtn1OyzHVgaMW0QMAbXo/f4erqQTDvWPBTLqigjvvlgCDD81GfE1DwuI+hFNe1+F15Ar3hW1DaCkyZqre6RrtZud7yLeifZvkSic5RkGX5OyfJ0LIJ/Hi4l+w4kJbvRoYY27q1+OLjSets1pu+YXPThjN6FnfcGW4rDDa2O0wrE8YpIPpkDIfagJvvkwlenpWsC9eDbfK8tsGDzj3TLVJMxY3E27luraYuddaPpcI3T8vVlZrf/e2nfxBOH+DA9U6wgGtSO1uBHQ7AI7rw7Ni9JR4kNrIbrDjw5fEt0eC7Pc1YcJaWb4a4zotd3/4oFwPK2EWg5vszUlDAPjmyY8fuQ9E7fOGkaPDa/o/2vzXY2x93rKz9EdRxmvapJuQTF8bwYzHh4TFHjvENNaAdPnTIZd9BrKnaU879X4Llu/3OaAtbGH/xfgbPaOp6aOvJ4TijjcFHnAFa6aRjtVdlvC7TAv6J0cfI01sEBt7Sy7OPGcrhAa3Nzhgujvcr26wDtkRu4G+4LXYY2vnCNG4duXSqTV79pw9e/fTbey5+oMy/w/Rvn/ktPl6xLEc73y8xy76/mo0Bro0AAyWMyIV9//MYY6bCit8NcJkkXxDou0ngNOrQr2eIfz7/wPHoOzCeslrY+PT353fxOxFXnL/+gzvtN50H/mW2l0/TKoNbop1H12/FX1xUCowq04vpySYqoE/aI4A+ZdgEpnmTl0UfdNDp56W1pyJkuCDccyDvEB5KGy1kYH2387vPKivXy5nl+QqzW/sKf+KmkIVUsEjkcqL53OXf/d+r3wqqJMA5vYftiz8/Hmp93Dsf8XMnQVFewoP5964Uf7oK9QQ5UZn0Le9qj6LDoqJ//hWU5/vz4O94paNgYPwMtUD3SDILcvJjDORykre8z+m+V82vOR112PY7wyUqQ/9YRXIs4CiPp/a/vLhop5m65lYW6pLqndEz9uPOT9zdY2J8jsUce2iQHXDGRFxxPxbhfiQi74nzex/3Y8eOuLsfPwBogrFheqCFLWa3md1WDDSEvJ5NQZazSMgxrvncuT/86X8/AAY2oIBHsLz67/P/8+qXs1cfILbf1/31/sobfugvvTr4TTVelOP+7bt+v/z20+WSr8F+hZs9S1LeIS2i+sdh33HaZt7x8n1O+mFD0Scvfya/p0ClUs1JwLz7hvEs/VLggfeXUfwcr38VfEcfTDbEF++8r0s1lAFGOuF28cXWF4A+9Qnm2odaB8ZOygFOte9F7HEvwdlfmrsvf++eHfCTrFrlNptSSClvc2s3rMoGzEQiCt8W6R9ZT9KMRWSarm39/Rdf/Bfw+g/X0fUzo+xfXe/ASqD8/rP2v65cX3tU1McfifAJjwHWd3w+XZTnQKk5TEVmaHj4iRMBez59rMaikqH7TwfE7GLBsNyPYgICToQHhG9X+EOZu0+EhwOvgDMc+HGgOsDnRLgPcPrpj/2C9okP9wS4rp4+utPLwZspmHi8PeB0aOi29dyS5oSUcB+f06dDgfPTp/fsnJgICPBxWSOg6uiuBwV66abPUQmjzVggK8ytirvWGe43EXD6gfrFhOTRirVJtHEsVHn1afjpUKCNAOC4S6L18QFOQkF/1RHs42oMbG37A4eWt6QVDNuVmsgWt4emruopFqscj9IUppnLU9LqiSnTSxGZKzXXz/1wJvPHcw+LzkQ8fBIpyr75/Er1vcyRzO0fbvvzN0NzRYtr119nji7YpuVZemC7sl/IhNIJcO5tplgwb5xdBnYLs8VhEHwsRjOmYeYQ/NE5Yo2NSx1TpERR/VFcZlr9UyaFBUNLzeJnGmRPIb6nW6OQP1WoZ7oMqTP3Ux8AC0SAxvD5qrkhlUqnSrUW5t4tuXG7MCNp0ujl0BXMPipwGLJSVXMFBeclXpK5gtm12ZlsRSptQSmvD8E1rLcUlmTkZWV5CPrUlvaZx6+nKnrYSfmxuUHaRo/GJa2Mj0udaGQIGoNxm7keIc1BHlpcQeOMl8M4K6HRENYGgb2hzyrvnLJFNrg9NAj0VpuGWEgibRCZrDFzNjGSSeynsiLTWOUUoobcwzVz8VIMAY8twXBEZhb56fQbi+Fc7+vrK+d+0I9m99djWbd808qxsBy0P5eK7UHC6qevrM5HVgqZJBEaSo/zxOdASVwMTMyFhnEhWDoKSkV7YlE7YEiIPwHlTzbDsVUfw0Vx/rEcGLlBsKpaHOer1tpXx/vzQ5RaGn+x4/ziTO+b9Vx6SXpO4iXvr65dq0pCrK4y1EsMh8WImFg0mYY6OlbnZy2LKmHaNE1osxMLlbIGWWPd1QylTTa5YHVYVkxd07W1Y93psbfzC1mT+fWb2s3BPLtevc6byo9NvLAv8FrGyUkEjW/Jk8kZecpJLY9nZzwX2hdGebwFt3tdWePCgVtRhVJqVBkSOVZPVbDTNMB20piYWy4mjpG45cwNrhmPlaLMVWiNOVLMXNDfXB251/uwaKSmZtwdRkT6KsSkQi7UrPHEciEwCja7urOy72apcJrEpaCgJXhYIh7KlGJJHDzUTIWERcGgGIg/BusJo0JQXBicQvbHV8GZVWh0D94XmIuuGF8USTradUulGyH563m0CdPs0PJM32DuDcK+S3F3L30eu+/wBk0wjpMIBAjjmkl3Zq5gcUKi0y8vD83xhYpGZb81X7qgnbplz9U0heQPtI0OZzlWDcuDGyFNlLHukvRujqa5qWGzbViNWKpUWpea98V6n9x3+EZS/pSkUe+g8QTBOLtWPTgVtNpvyFpYzVp167opt8pvTSmy6+upYk2KuJxJqhfDxIoUFvtOOZtSTyGzKWYFRsQMk2KkXABaJJe8Olo9UrTSW/Sw6Ej2ApZZnn1n+g5JgYRSmBAs2T97ITtlvKbGUk2aZmGlOTCMFA3BM6FUDQxPh6HiMFAk2p+J9IRTIZ5MtCeGAyFRYJ5mETysBI7uSUszrulb135YKTCtGQcV3Rm5SgZ/SKWbMBpt0qsi731ANCV8nQ488ZQnn25kzKsda10OE5Bva/yZ1RcdkiE+Y3AYZ5/ObV6oXpfGXigxV7SwB61yax7/hWVAUVsr0nRv0G+na8RtttJhwaDVDqzPZRUevubtvTXBuzmpbsCDpg4OsjYG4XDB2j6BQChk5PGWstz488+zlhbUU6X9mxQykRjFKieR2swAK3OhmFxOoZQTOUSuwmzmYkVi8waTSyWVk6eHO/Xt9xZrrpw75tvZia0fJaUt+DLFJKgC6DATVnYLWzl+5UlXZSkrDSMyQzl0TzSdiSUQYAQNFCuCAaAgzDBPOBPiTyZ5UrlQtAgLqSJAOQQoiZLSb1h5sdb+otXBtzAKpc0Zw6vGOVXBcm9wLSE9IfnypWTvCzmE4KSxDPsoj6abNwGeOnWtV2IaQjgMiwUT17OUg7i8J2MZq89z2clVFTc2WjYpmzahmrH0RmmT1lZw6RVVhPR0vCafzbK3Aak13Sd7lnjpslvgtUDvky116x5aJQ2h1SKC1mVatZohl+etdk65rZhedKkNPNwUksUGjIGZ06SgsmzZVDE3SkMBWGkKkQqRpieKy8GIMGYxk4Unssjz452914uKfrxTlEJScEnTkb71FKhGA6UigYDyTVkoLV1681TPS7vVQ0IpmP4EDtyswcKlGCgXD2EC0xMg8/AoT3SYPykKDjVjIFQ8KoyOxpTg/SPL3izOjazwAbExdlnbysgZtaXGjtYHHSP2kGb64cNf3034in6ZndHIptdZhbLUuTXT8qIOWNic4fMlpvZHkgm9Ns8gEJQpBILB/A18z1V2ftJY55S1TybT97fUNU3e4HRfrSrpLsGnN2vKGOs83PCT+SRgK2vr124XDt+9erUpA5e/7oGzKT3sA8G4Nq1seKBxYNDtyQz/NZ/GswoGyeVkKpFolo6ZqbYyLJKIpIwhNWNUQKIoFI4ITzFzNFFEDncMyWJ1dtW8WLnuN3IsIgJGKs9OK88mLYh9yRRfYppnVCRMPFz6ZuK5S59YPVhUD4l5W4qih8ExOWgsPQxKQPqb8f6AiAOE/NFUCIYAQ3ESUYRYFF6Egd3itc/dz6yWTXfNCsbH5WUbLdUvcAzLbKO1BXgefp934KXDn98O0TJOVnFr2+wzjjlT6tyKyjHhWOYZgPmaQ8XrAmb/iKVOLa6enS/l5Few26yjNgYPyJ/R4fwxYsVGVXd6DvBkedylJiSr0S6XNUxPscOSL7h9fXirW+DJqxW5IW2AlbcHMabWg6faWtbZky0DbpmAH+cjGOpGwVPiJpnSJMY+I1KlGjKykEWlaJBjLGQh16zAirloEZPL4W5gFGauLXL0ecT13syhh+6VpRByOTZ7IeWO0BeqSCMXkiAUse9T/aje0H/HFknq56AoIhhhA4PNMcPNBCwyEYXOQaPisDA8AQoBRjsK05OpgWPTqfCSHLiZjkqzm4bOL4/bpvSrpjfA80c57Cy1Xdm8yWAMVKR/fvlCcuyF5I+v4qZyc6k9wVqZQ6frcMwtps7oVPzx147lIZXxtWDGkGV8Uo3Lf1YxSdjMsImVbXKrTK7WyhZs3ZyqituJt0viSi4lxjZvKBppwnHrdP9k3Vexl70/37rVe99/JnSHTNYigpQtQYyGdcRmbYtI1DzptrI4o7LMIfgWnFzM3uBKC6lStpTJIiIBailjGgqRoilkSvFhIjyXgtYguRQmK0pc1tn3sKj39b2RGvf+SJKYTCorIynKfO8s+JLMMFjZnbThhcrqvjSWMCVlQZNSyEHh6cB4BqRdFJxAgKIJcDQd7R9F9cQCRioR7k9PhFHpH2OkYVg6B1NPm2hVLVXapxeyjNU8+zOOwTjVNqkZQ1gp6QmBwP9ZBCbE1XnQxrpviCY9GBOzM8uOmcUsYEVPtfR8rqDVaLK8ntFZaI0LVoa9uY4I9HF0UGm9ZW9U2pSbkbUbYVXdcaILVcnptxPv5g9UqxvECwNy+6Q0LjDQLXDrHxKuJRy+nFSb30izTeJqa4NzN3Ir6PT0/wf7nw4i8kwCGwAAAABJRU5ErkJggg==";
        AdURL=@"http://www.connectedafield.com/marketing/contact";
    } else {
        //parse out the json data
        NSError* error1;
        NSDictionary* jsonObjectFromServer = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error1];
        
        adImageURL = [jsonObjectFromServer objectForKey:@"image"];
        AdURL = [jsonObjectFromServer objectForKey:@"url"];
    }
    return adImageURL;
}

-(void)bannerAdTapped:(UIGestureRecognizer *)gestureRecognizer {
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"bannerAdClicked('%@')",AdURL]];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
	if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];

		mapView = nil;
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

-(void)centerMapOnLocation:(CDVInvokedUrlCommand *)command {
    
    NSDictionary* options2 = command.arguments[0];
    
    CLLocationCoordinate2D centerCoord = { [[options2 objectForKey:@"lat"] floatValue] , [[options2 objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[options2 objectForKey:@"diameter"] floatValue];
    
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
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(self.imageButton)
	{
		[ self.imageButton removeFromSuperview];
        self.imageButton = nil;
	}
	if(childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
}

@end
