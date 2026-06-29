package com.example.amap_flutter_plugin;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AmapViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    public AmapViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull Context context, int viewId, @Nullable Object args) {
        return new AmapMapPlatformView(context, viewId, messenger);
    }
}
