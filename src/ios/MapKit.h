//
//  UIControls.h
//  Cordova
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#import "SVProgressHUD.h"

#import <Cordova/CDVPlugin.h>

@interface MapKitView : CDVPlugin <MKMapViewDelegate, UITextFieldDelegate>
{
}

@property (nonatomic, copy) NSString *buttonCallback;
@property (nonatomic, retain) UIView* childView;
@property (nonatomic, retain) MKMapView* mapView;
@property (nonatomic, retain) UIButton*  imageButton;
@property (strong, nonatomic) NSString* AdURL;
@property (strong, nonatomic) UIImageView *adImageView;
@property (strong, nonatomic) IBOutlet UITextField *txtField;

- (void)createView;

- (void)createViewWithOptions:(NSDictionary *)options; //Designated Initializer

- (void)showMap:(CDVInvokedUrlCommand *)command;

- (void)hideMap:(CDVInvokedUrlCommand *)command;

- (void)changeMapType:(CDVInvokedUrlCommand *)command;

- (void)destroyMap:(CDVInvokedUrlCommand *)command;

- (void)clearMapPins:(CDVInvokedUrlCommand *)command;

- (void)addMapPins:(CDVInvokedUrlCommand *)command;

- (void)saveNewLocation:(CDVInvokedUrlCommand *)command;

- (void)focusOnTextField:(CDVInvokedUrlCommand *)command;

- (void)centerMapOnLocation:(CDVInvokedUrlCommand *)command;

- (void)showLoadingView:(CDVInvokedUrlCommand *)command;

- (void)hideLoadingView:(CDVInvokedUrlCommand *)command;

- (void)initPlugin:(CDVInvokedUrlCommand *)command;

@end
