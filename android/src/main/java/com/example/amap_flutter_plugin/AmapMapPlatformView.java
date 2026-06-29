package com.example.amap_flutter_plugin;

import android.content.Context;
import android.graphics.Color;
import android.view.View;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapsInitializer;
import com.amap.api.maps.MapView;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.CircleOptions;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;
import com.amap.api.maps.model.MyLocationStyle;
import com.amap.api.maps.model.Polyline;
import com.amap.api.maps.model.PolylineOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class AmapMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler, AMap.OnCameraChangeListener {
    private final MapView mapView;
    private final AMap aMap;
    private final MethodChannel channel;
    private final List<Marker> markers = new ArrayList<>();
    private final List<Polyline> polylines = new ArrayList<>();
    private final List<Marker> trackDots = new ArrayList<>();
    private Marker myLocationMarker;

    public AmapMapPlatformView(Context context, int viewId, BinaryMessenger messenger) {
        MapsInitializer.updatePrivacyShow(context, true, true);
        MapsInitializer.updatePrivacyAgree(context, true);
        AMapLocationClient.updatePrivacyShow(context, true, true);
        AMapLocationClient.updatePrivacyAgree(context, true);

        mapView = new MapView(context);
        aMap = mapView.getMap();

        channel = new MethodChannel(messenger, "com.example.amap_flutter_plugin/map_" + viewId);
        channel.setMethodCallHandler(this);

        aMap.setOnCameraChangeListener(this);

        mapView.onCreate(null);
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        clearAll();
        mapView.onDestroy();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "init":
                initMap(call);
                result.success(null);
                break;
            case "moveCamera":
                moveCamera(call);
                result.success(null);
                break;
            case "setZoom":
                setZoom(call);
                result.success(null);
                break;
            case "addMarkers":
                addMarkers(call);
                result.success(null);
                break;
            case "addPolylines":
                addPolylines(call);
                result.success(null);
                break;
            case "addTrackDots":
                addTrackDots(call);
                result.success(null);
                break;
            case "setMyLocationEnabled":
                setMyLocationEnabled(call);
                result.success(null);
                break;
            case "clearOverlays":
                clearAll();
                result.success(null);
                break;
            case "getZoom":
                result.success((double) aMap.getCameraPosition().zoom);
                break;
            case "getCenter":
                LatLng center = aMap.getCameraPosition().target;
                Map<String, Object> centerMap = new HashMap<>();
                centerMap.put("lat", center.latitude);
                centerMap.put("lng", center.longitude);
                centerMap.put("zoom", (double) aMap.getCameraPosition().zoom);
                result.success(centerMap);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void initMap(MethodCall call) {
        Double lat = call.argument("lat");
        Double lng = call.argument("lng");
        Double zoom = call.argument("zoom");

        if (lat != null && lng != null) {
            LatLng position = new LatLng(lat, lng);
            float z = zoom != null ? zoom.floatValue() : 18f;
            aMap.moveCamera(CameraUpdateFactory.newLatLngZoom(position, z));
        }

        aMap.getUiSettings().setZoomControlsEnabled(false);
        aMap.getUiSettings().setMyLocationButtonEnabled(false);
    }

    private void moveCamera(MethodCall call) {
        Double lat = call.argument("lat");
        Double lng = call.argument("lng");
        Double zoom = call.argument("zoom");
        Boolean animate = call.argument("animate");

        if (lat == null || lng == null) return;

        LatLng target = new LatLng(lat, lng);

        if (animate != null && animate) {
            float z = zoom != null ? zoom.floatValue() : aMap.getCameraPosition().zoom;
            aMap.animateCamera(CameraUpdateFactory.newLatLngZoom(target, z), 500, null);
        } else {
            if (zoom != null) {
                aMap.moveCamera(CameraUpdateFactory.newLatLngZoom(target, zoom.floatValue()));
            } else {
                aMap.moveCamera(CameraUpdateFactory.newLatLng(target));
            }
        }
    }

    private void setZoom(MethodCall call) {
        Double zoom = call.argument("zoom");
        if (zoom != null) {
            aMap.animateCamera(CameraUpdateFactory.zoomTo(zoom.floatValue()), 300, null);
        }
    }

    @SuppressWarnings("unchecked")
    private void addMarkers(MethodCall call) {
        for (Marker m : markers) {
            m.remove();
        }
        markers.clear();

        List<Map<String, Object>> args = call.arguments();
        if (args == null) return;

        for (Map<String, Object> item : args) {
            Double lat = (Double) item.get("lat");
            Double lng = (Double) item.get("lng");
            if (lat == null || lng == null) continue;

            MarkerOptions options = new MarkerOptions()
                    .position(new LatLng(lat, lng))
                    .anchor(0.5f, 1.0f);

            String title = (String) item.get("title");
            if (title != null) {
                options.title(title);
            }

            markers.add(aMap.addMarker(options));
        }
    }

    @SuppressWarnings("unchecked")
    private void addPolylines(MethodCall call) {
        for (Polyline p : polylines) {
            p.remove();
        }
        polylines.clear();

        List<Map<String, Object>> args = call.arguments();
        if (args == null) return;

        for (Map<String, Object> item : args) {
            List<Map<String, Object>> points = (List<Map<String, Object>>) item.get("points");
            Number colorNum = (Number) item.get("color");
            Number widthNum = (Number) item.get("width");

            if (points == null || points.isEmpty()) continue;

            List<LatLng> latLngs = new ArrayList<>();
            for (Map<String, Object> p : points) {
                Double lat = (Double) p.get("lat");
                Double lng = (Double) p.get("lng");
                if (lat != null && lng != null) {
                    latLngs.add(new LatLng(lat, lng));
                }
            }

            if (latLngs.isEmpty()) continue;

            PolylineOptions polylineOptions = new PolylineOptions()
                    .addAll(latLngs)
                    .width(widthNum != null ? widthNum.floatValue() : 5f)
                    .color(colorNum != null ? colorNum.intValue() : Color.BLUE);

            polylines.add(aMap.addPolyline(polylineOptions));
        }
    }

    @SuppressWarnings("unchecked")
    private void addTrackDots(MethodCall call) {
        for (Marker m : trackDots) {
            m.remove();
        }
        trackDots.clear();

        List<Map<String, Object>> points = call.argument("points");
        Number colorNum = call.argument("color");
        Number sizeNum = call.argument("size");

        if (points == null) return;

        int color = colorNum != null ? colorNum.intValue() : Color.BLUE;
        float size = sizeNum != null ? sizeNum.floatValue() : 10f;

        for (Map<String, Object> p : points) {
            Double lat = (Double) p.get("lat");
            Double lng = (Double) p.get("lng");
            if (lat == null || lng == null) continue;

            MarkerOptions options = new MarkerOptions()
                    .position(new LatLng(lat, lng))
                    .anchor(0.5f, 0.5f)
                    .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_BLUE))
                    .snippet(String.valueOf(size));

            trackDots.add(aMap.addMarker(options));
        }
    }

    private void setMyLocationEnabled(MethodCall call) {
        Boolean enabled = call.argument("enabled");
        Double lat = call.argument("lat");
        Double lng = call.argument("lng");

        if (myLocationMarker != null) {
            myLocationMarker.remove();
            myLocationMarker = null;
        }

        if (enabled != null && enabled && lat != null && lng != null) {
            MarkerOptions options = new MarkerOptions()
                    .position(new LatLng(lat, lng))
                    .anchor(0.5f, 0.5f)
                    .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE));

            myLocationMarker = aMap.addMarker(options);
        }
    }

    private void clearAll() {
        for (Marker m : markers) m.remove();
        markers.clear();
        for (Polyline p : polylines) p.remove();
        polylines.clear();
        for (Marker m : trackDots) m.remove();
        trackDots.clear();
        if (myLocationMarker != null) {
            myLocationMarker.remove();
            myLocationMarker = null;
        }
    }

    @Override
    public void onCameraChange(com.amap.api.maps.model.CameraPosition position) {
    }

    @Override
    public void onCameraChangeFinish(com.amap.api.maps.model.CameraPosition position) {
        LatLng center = aMap.getCameraPosition().target;
        Map<String, Object> data = new HashMap<>();
        data.put("lat", center.latitude);
        data.put("lng", center.longitude);
        data.put("zoom", (double) aMap.getCameraPosition().zoom);
        channel.invokeMethod("onCameraIdle", data);
    }
}
