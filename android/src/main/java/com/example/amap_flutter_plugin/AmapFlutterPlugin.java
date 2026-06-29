package com.example.amap_flutter_plugin;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AmapFlutterPlugin implements FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private AmapLocationPlugin locationPlugin;
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "com.example.amap_flutter_plugin");
        channel.setMethodCallHandler(this);

        locationPlugin = new AmapLocationPlugin();
        locationPlugin.onAttachedToEngine(binding);

        binding.getPlatformViewRegistry().registerViewFactory(
            "com.example.amap_flutter_plugin/map",
            new AmapViewFactory(binding.getBinaryMessenger())
        );
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("isAmapSdkAvailable")) {
            result.success(isAmapSdkAvailable());
        } else {
            result.notImplemented();
        }
    }

    private boolean isAmapSdkAvailable() {
        try {
            Class.forName("com.amap.api.maps.AMap");
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        if (locationPlugin != null) {
            locationPlugin.onDetachedFromEngine(binding);
            locationPlugin = null;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        if (locationPlugin != null) {
            locationPlugin.onAttachedToActivity(binding);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        if (locationPlugin != null) {
            locationPlugin.onDetachedFromActivityForConfigChanges();
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        if (locationPlugin != null) {
            locationPlugin.onReattachedToActivityForConfigChanges(binding);
        }
    }

    @Override
    public void onDetachedFromActivity() {
        if (locationPlugin != null) {
            locationPlugin.onDetachedFromActivity();
        }
    }
}
