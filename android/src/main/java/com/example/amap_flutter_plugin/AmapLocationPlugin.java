package com.example.amap_flutter_plugin;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.HashMap;
import java.util.Map;

public class AmapLocationPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private static final int PERMISSION_REQUEST_CODE = 1001;
    private static final String[] LOCATION_PERMISSIONS = {
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION
    };

    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private Runnable onPermissionGranted;

    // Amap SDK
    private AMapLocationClient amapLocationClient;
    private AMapLocationClientOption amapLocationOption;
    private boolean useAmapSdk = false;

    // Android native fallback
    private LocationManager locationManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "com.example.amap_flutter_plugin/location");
        channel.setMethodCallHandler(this);
        context = binding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "init":
                String apiKey = call.argument("apiKey");
                initLocation(apiKey);
                result.success(null);
                break;
            case "getLocation":
                getLocation(result);
                break;
            case "startLocationStream":
                startLocationStream();
                result.success(null);
                break;
            case "stopLocationStream":
                stopLocationStream();
                result.success(null);
                break;
            case "dispose":
                dispose();
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private boolean isAmapSdkAvailable() {
        try {
            Class.forName("com.amap.api.location.AMapLocationClient");
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }

    private boolean hasLocationPermission() {
        if (activity == null) return false;
        for (String perm : LOCATION_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(activity, perm) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    private void requestLocationPermission(Runnable onGranted) {
        if (activity == null) {
            this.onPermissionGranted = onGranted;
            return;
        }
        if (hasLocationPermission()) {
            onGranted.run();
            return;
        }
        this.onPermissionGranted = onGranted;
        ActivityCompat.requestPermissions(activity, LOCATION_PERMISSIONS, PERMISSION_REQUEST_CODE);
    }

    private void initLocation(String apiKey) {
        useAmapSdk = isAmapSdkAvailable();
        if (useAmapSdk) {
            initAmapLocation(apiKey);
        } else {
            initNativeLocation();
        }
    }

    // ========== Amap SDK ==========

    private void initAmapLocation(String apiKey) {
        if (amapLocationClient != null) {
            amapLocationClient.onDestroy();
        }

        AMapLocationClient.updatePrivacyShow(context, true, true);
        AMapLocationClient.updatePrivacyAgree(context, true);

        try {
            amapLocationClient = new AMapLocationClient(context);
        } catch (Exception e) {
            useAmapSdk = false;
            initNativeLocation();
            return;
        }
        amapLocationOption = new AMapLocationClientOption();
        amapLocationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
        amapLocationOption.setOnceLocation(true);
        amapLocationOption.setNeedAddress(true);
        amapLocationOption.setHttpTimeOut(20000);
        amapLocationClient.setLocationOption(amapLocationOption);
    }

    // ========== Android Native Fallback ==========

    private void initNativeLocation() {
        locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
    }

    private void doNativeGetLocation(Result result) {
        if (locationManager == null) {
            result.error("NOT_INIT", "Location manager not initialized", null);
            return;
        }

        String provider = getBestProvider();
        if (provider == null) {
            result.error("NO_PROVIDER", "No location provider available", null);
            return;
        }

        try {
            Location lastKnown = locationManager.getLastKnownLocation(provider);
            if (lastKnown != null) {
                result.success(locationToMap(lastKnown));
                return;
            }

            locationManager.requestSingleUpdate(provider, new LocationListener() {
                @Override
                public void onLocationChanged(@NonNull Location location) {
                    result.success(locationToMap(location));
                }
                @Override public void onStatusChanged(String provider, int status, Bundle extras) {}
                @Override public void onProviderEnabled(@NonNull String provider) {}
                @Override public void onProviderDisabled(@NonNull String provider) {
                    result.error("PROVIDER_DISABLED", "Location provider disabled", null);
                }
            }, Looper.getMainLooper());
        } catch (SecurityException e) {
            result.error("NO_PERMISSION", "Location permission not granted", null);
        }
    }

    private void doNativeStartLocationStream() {
        if (locationManager == null) return;

        String provider = getBestProvider();
        if (provider == null) return;

        try {
            locationManager.requestLocationUpdates(provider, 3000, 0, new LocationListener() {
                @Override
                public void onLocationChanged(@NonNull Location location) {
                    Map<String, Object> map = locationToMap(location);
                    map.put("provider", "android_native");
                    channel.invokeMethod("onLocationUpdate", map);
                }
                @Override public void onStatusChanged(String provider, int status, Bundle extras) {}
                @Override public void onProviderEnabled(@NonNull String provider) {}
                @Override public void onProviderDisabled(@NonNull String provider) {}
            }, Looper.getMainLooper());
        } catch (SecurityException e) {
            // Permission not granted
        }
    }

    private String getBestProvider() {
        if (locationManager == null) return null;
        if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            return LocationManager.GPS_PROVIDER;
        }
        if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            return LocationManager.NETWORK_PROVIDER;
        }
        return LocationManager.PASSIVE_PROVIDER;
    }

    private Map<String, Object> locationToMap(Location location) {
        Map<String, Object> map = new HashMap<>();
        map.put("latitude", location.getLatitude());
        map.put("longitude", location.getLongitude());
        map.put("accuracy", (double) location.getAccuracy());
        map.put("address", "");
        map.put("province", "");
        map.put("city", "");
        map.put("district", "");
        map.put("country", "");
        map.put("provider", useAmapSdk ? "amap" : "android_native");
        map.put("errorCode", 0);
        return map;
    }

    // ========== Unified API ==========

    private void getLocation(Result result) {
        requestLocationPermission(() -> {
            if (useAmapSdk) {
                getAmapLocation(result);
            } else {
                doNativeGetLocation(result);
            }
        });
    }

    private void startLocationStream() {
        requestLocationPermission(() -> {
            if (useAmapSdk) {
                doStartAmapLocationStream();
            } else {
                doNativeStartLocationStream();
            }
        });
    }

    private void getAmapLocation(Result result) {
        if (amapLocationClient == null) {
            result.error("NOT_INIT", "Amap location client not initialized", null);
            return;
        }

        AMapLocationClientOption option = new AMapLocationClientOption();
        option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
        option.setOnceLocation(true);
        option.setNeedAddress(true);
        option.setHttpTimeOut(20000);
        amapLocationClient.setLocationOption(option);

        amapLocationClient.setLocationListener(new AMapLocationListener() {
            @Override
            public void onLocationChanged(AMapLocation amapLocation) {
                if (amapLocation != null) {
                    if (amapLocation.getErrorCode() == 0) {
                        Map<String, Object> map = new HashMap<>();
                        map.put("latitude", amapLocation.getLatitude());
                        map.put("longitude", amapLocation.getLongitude());
                        map.put("accuracy", (double) amapLocation.getAccuracy());
                        map.put("address", amapLocation.getAddress());
                        map.put("province", amapLocation.getProvince());
                        map.put("city", amapLocation.getCity());
                        map.put("district", amapLocation.getDistrict());
                        map.put("country", amapLocation.getCountry());
                        map.put("provider", "amap");
                        map.put("errorCode", 0);
                        result.success(map);
                    } else {
                        Map<String, Object> map = new HashMap<>();
                        map.put("errorCode", amapLocation.getErrorCode());
                        map.put("errorInfo", amapLocation.getLocationDetail());
                        result.success(map);
                    }
                } else {
                    result.error("LOCATION_FAILED", "Location returned null", null);
                }
            }
        });

        amapLocationClient.startLocation();
    }

    private void doStartAmapLocationStream() {
        if (amapLocationClient == null) return;

        amapLocationOption.setOnceLocation(false);
        amapLocationOption.setInterval(3000);
        amapLocationClient.setLocationOption(amapLocationOption);

        amapLocationClient.setLocationListener(new AMapLocationListener() {
            @Override
            public void onLocationChanged(AMapLocation amapLocation) {
                if (amapLocation != null && amapLocation.getErrorCode() == 0) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("latitude", amapLocation.getLatitude());
                    map.put("longitude", amapLocation.getLongitude());
                    map.put("accuracy", (double) amapLocation.getAccuracy());
                    map.put("address", amapLocation.getAddress());
                    map.put("province", amapLocation.getProvince());
                    map.put("city", amapLocation.getCity());
                    map.put("district", amapLocation.getDistrict());
                    map.put("country", amapLocation.getCountry());
                    map.put("provider", "amap");
                    channel.invokeMethod("onLocationUpdate", map);
                }
            }
        });

        amapLocationClient.startLocation();
    }

    private void stopLocationStream() {
        if (useAmapSdk) {
            if (amapLocationClient != null) {
                amapLocationClient.stopLocation();
            }
        } else {
            if (locationManager != null) {
                locationManager.removeUpdates((LocationListener) null);
            }
        }
    }

    private void dispose() {
        if (amapLocationClient != null) {
            amapLocationClient.stopLocation();
            amapLocationClient.onDestroy();
            amapLocationClient = null;
        }
        if (locationManager != null) {
            locationManager.removeUpdates((LocationListener) null);
            locationManager = null;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        dispose();
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addRequestPermissionsResultListener((requestCode, permissions, grantResults) -> {
            if (requestCode == PERMISSION_REQUEST_CODE) {
                boolean allGranted = true;
                for (int result : grantResults) {
                    if (result != PackageManager.PERMISSION_GRANTED) {
                        allGranted = false;
                        break;
                    }
                }
                if (allGranted && onPermissionGranted != null) {
                    onPermissionGranted.run();
                }
                onPermissionGranted = null;
                return true;
            }
            return false;
        });
        if (onPermissionGranted != null && hasLocationPermission()) {
            onPermissionGranted.run();
            onPermissionGranted = null;
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
}
