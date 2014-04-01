package com.phonegap.plugins.mapkit;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Base64;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.app.Dialog;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.GooglePlayServicesNotAvailableException;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.GoogleMapOptions;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.MapsInitializer;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.BitmapDescriptor;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;

public class MapKit extends CordovaPlugin {

    protected ViewGroup root; // original Cordova layout
    protected RelativeLayout main; // new layout to support map
    protected MapView mapView;
    private CallbackContext cCtx;
    private String TAG = "MapKitPlugin";

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        main = new RelativeLayout(cordova.getActivity());
        System.out.println("Initialized");
    }

    public void showMap(final JSONObject options) {
    	System.out.println("Method Called");
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    double latitude = 0, longitude = 0;
                    int height = 460;
                    boolean atBottom = false;
                    try {
                        height = options.getInt("height");
                        latitude = options.getDouble("lat");
                        longitude = options.getDouble("lon");
                        atBottom = options.getBoolean("atBottom");
                        System.out.println("Options Recieved");
                    } catch (JSONException e) {
                        LOG.e(TAG, "Error reading options");
                    }
                    
                    final int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(cordova.getActivity());
                    if (resultCode == ConnectionResult.SUCCESS) {
                    	System.out.println("Googleplay services success");
                        mapView = new MapView(cordova.getActivity(),
                                new GoogleMapOptions());
                        root = (ViewGroup) webView.getParent();
                        root.removeView(webView);
                        main.addView(webView);

                        cordova.getActivity().setContentView(main);

//                        try {
                            MapsInitializer.initialize(cordova.getActivity());
                            System.out.println("Map Initialized");
//                        } catch (GooglePlayServicesNotAvailableException e) {
//                            e.printStackTrace();
//                        }

                        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                                LayoutParams.MATCH_PARENT, height);
                        if (atBottom) {
                            params.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM,
                                    RelativeLayout.TRUE);
                        } else {
                            params.addRule(RelativeLayout.ALIGN_PARENT_TOP,
                                    RelativeLayout.TRUE);
                        }
                        params.addRule(RelativeLayout.CENTER_HORIZONTAL,
                                RelativeLayout.TRUE);
                        
                        mapView.setLayoutParams(params);
                        System.out.println("Parameters Set");
                        mapView.onCreate(null);
                        
                        mapView.onResume(); // FIXME: I wish there was a better way
                                            // than this...
                        main.addView(mapView);
                        System.out.println("Map View Added");
                        
                        
                        //add the crosshair
                        byte[] decodedString = Base64.decode("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", Base64.DEFAULT);
                        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length); 
                        System.out.println("String Decoded");
                     
                        ImageView image = new ImageView(main.getContext());
                        System.out.println("Image View Created");
						image.setImageBitmap(decodedByte);
						 RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams(
	                                150, 150);
						 params2.addRule(RelativeLayout.CENTER_HORIZONTAL,
	                                RelativeLayout.TRUE);
//						 params2.addRule(RelativeLayout.CENTER_VERTICAL,
//	                                RelativeLayout.TRUE);
						 params2.topMargin = (height-150)/2+150;
						 image.setLayoutParams(params2);
						
//						int viewHeight = webView.getHeight();
//						int viewWidth = webView.getWidth();
//						System.out.println(String.format("View Height = %d", viewHeight));
//						System.out.println(String.format("View Width = %d", viewWidth));
						
						
						 main.addView(image);
						 
						
						
                        //get a reference to the map
                        GoogleMap map = mapView.getMap();
                 
                        // Moving the map to lat, lon
                        map.moveCamera(
                                CameraUpdateFactory.newLatLngZoom(new LatLng(
                                        latitude, longitude), 14));
                        
                        //shows the users current location
                        //map.setMyLocationEnabled(true);
                        
                        //sets the map to Hybrid
                        map.setMapType(GoogleMap.MAP_TYPE_HYBRID);
                        
                        
                        
                        cCtx.success();

                    } else if (resultCode == ConnectionResult.SERVICE_MISSING ||
                               resultCode == ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED ||
                               resultCode == ConnectionResult.SERVICE_DISABLED) {
                        Dialog dialog = GooglePlayServicesUtil.getErrorDialog(resultCode, cordova.getActivity(), 1,
                                    new DialogInterface.OnCancelListener() {
                                        @Override
                                        public void onCancel(DialogInterface dialog) {
                                            cCtx.error("com.google.android.gms.common.ConnectionResult " + resultCode);
                                        }
                                    }
                                );
                        dialog.show();
                    }

                }
            });
        } catch (Exception e) {
        	System.out.println("Error: " + e.getMessage());
            e.printStackTrace();
            cCtx.error("MapKitPlugin::showMap(): An exception occured");
        }
    }

    private void hideMap() {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
//                        mapView.onDestroy();
                        main.removeView(webView);
                        main.removeView(mapView);
                        root.addView(webView);
                        cordova.getActivity().setContentView(root);
                        mapView = null;
                        cCtx.success();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::hideMap(): An exception occured");
        }
    }

    public void addMapPins(final JSONArray pins) {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        try {
                            for (int i = 0, j = pins.length(); i < j; i++) {
                                double latitude = 0, longitude = 0;
                                JSONObject options = pins.getJSONObject(i);
                                latitude = options.getDouble("lat");
                                longitude = options.getDouble("lon");

                                MarkerOptions mOptions = new MarkerOptions();

                                mOptions.position(new LatLng(latitude,
                                                             longitude));
                                if(options.has("title")) {
                                    mOptions.title(options.getString("title"));
                                }
                                if(options.has("snippet")) {
                                    mOptions.snippet(options.getString("snippet"));
                                }
                                if(options.has("icon")) {
                                    BitmapDescriptor bDesc = getBitmapDescriptor(options);
                                    if(bDesc != null) {
                                      mOptions.icon(bDesc);
                                    }
                                }

                                // adding Marker
                                // This is to prevent non existing asset resources to crash the app
                                try {
                                    mapView.getMap().addMarker(mOptions);
                                } catch(NullPointerException e) {
                                    LOG.e(TAG, "An error occurred when adding the marker. Check if icon exists");
                                }
                            }
                            cCtx.success();
                        } catch (JSONException e) {
                            e.printStackTrace();
                            LOG.e(TAG, "An error occurred while reading pins");
                            cCtx.error("An error occurred while reading pins");
                        }
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::addMapPins(): An exception occured");
        }
    }

    private BitmapDescriptor getBitmapDescriptor( final JSONObject iconOption ) {
        try {
            Object o = iconOption.get("icon");
            String type = null, resource = null;
            if( o.getClass().getName().equals("org.json.JSONObject" ) ) {
                JSONObject icon = (JSONObject)o;
                if(icon.has("type") && icon.has("resource")) {
                    type = icon.getString("type");
                    resource = icon.getString("resource");
                    if(type.equals("asset")) {
                        return BitmapDescriptorFactory.fromAsset(resource);
                    }
                }
            } else {
                //this is a simple change in the icon's color
                return BitmapDescriptorFactory.defaultMarker(Float.parseFloat(o.toString()));
            }
        } catch (JSONException e){
            e.printStackTrace();
        }
        return null;
    }

    public void clearMapPins() {
        try {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mapView != null) {
                        mapView.getMap().clear();
                        cCtx.success();
                    }
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::clearMapPins(): An exception occured");
        }
    }

    public void changeMapType(final JSONObject options) {
        try{
            cordova.getActivity().runOnUiThread(new Runnable() {

                @Override
                public void run() {
                    if( mapView != null ) {
                        int mapType = 0;
                        try {
                            mapType = options.getInt("mapType");
                        } catch (JSONException e) {
                            LOG.e(TAG, "Error reading options");
                        }

                        //Don't want to set the map type if it's the same
                        if(mapView.getMap().getMapType() != mapType) {
                            mapView.getMap().setMapType(mapType);
                        }
                    }

                    cCtx.success();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::changeMapType(): An exception occured ");
        }
    }
    
    public void centerMapOnLocation(final JSONObject options) {
        try{
            cordova.getActivity().runOnUiThread(new Runnable() {

                @Override
                public void run() {
                	double latitude = 0, longitude = 0;
                    try {
                        latitude = options.getDouble("lat");
                        longitude = options.getDouble("lon");
                    } catch (JSONException e) {
                        LOG.e(TAG, "Error reading options");
                    }
                	
                	 //get a reference to the map
                    GoogleMap map = mapView.getMap();
             
                    // Moving the map to lat, lon
                    map.animateCamera(
                            CameraUpdateFactory.newLatLngZoom(new LatLng(
                                    latitude, longitude), 14));

                    cCtx.success();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            cCtx.error("MapKitPlugin::centerMapOnLocation(): An exception occured ");
        }
    }

    public void saveNewLocation() {
        try{
            cordova.getActivity().runOnUiThread(new Runnable() {

                @Override
                public void run() {
                	System.out.println("Save Called");
                	 //get a reference to the map
                    GoogleMap map = mapView.getMap();
                    
                    //get the center location of the map
                	CameraPosition location = map.getCameraPosition();
                    double lat = location.target.latitude;
                    double lng = location.target.longitude;
                    System.out.println("Postion Obtained");
                    cCtx.success(String.format("%f, %f",lat,lng));
                }
            });
        } catch (Exception e) {
        	System.out.println("Save Error");
            e.printStackTrace();
            cCtx.error("MapKitPlugin::centerMapOnLocation(): An exception occured ");
        }
    }
    
    public boolean execute(String action, JSONArray args,
            CallbackContext callbackContext) throws JSONException {
        cCtx = callbackContext;
        if (action.compareTo("showMap") == 0) {
            showMap(args.getJSONObject(0));
        } else if (action.compareTo("hideMap") == 0) {
            hideMap();
        } else if (action.compareTo("addMapPins") == 0) {
            addMapPins(args.getJSONArray(0));
        } else if (action.compareTo("clearMapPins") == 0) {
            clearMapPins();
        } else if( action.compareTo("changeMapType") == 0 ) {
            changeMapType(args.getJSONObject(0));
        } else if( action.compareTo("centerMapOnLocation") == 0 ) {
        	centerMapOnLocation(args.getJSONObject(0));
        } else if( action.compareTo("saveNewLocation") == 0 ) {
        	saveNewLocation();
        }
        LOG.d(TAG, action);

        return true;
    }

    @Override
    public void onPause(boolean multitasking) {
        LOG.d(TAG, "MapKitPlugin::onPause()");
        if (mapView != null) {
            mapView.onPause();
        }
        super.onPause(multitasking);
    }

    @Override
    public void onResume(boolean multitasking) {
        LOG.d(TAG, "MapKitPlugin::onResume()");
        if (mapView != null) {
            mapView.onResume();
        }
        super.onResume(multitasking);
    }

    @Override
    public void onDestroy() {
        LOG.d(TAG, "MapKitPlugin::onDestroy()");
        if (mapView != null) {
            mapView.onDestroy();
        }
        super.onDestroy();
    }
}
