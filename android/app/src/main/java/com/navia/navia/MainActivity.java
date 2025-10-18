package com.navia.navia;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;

import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Handler;

import androidx.annotation.NonNull;


import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import java.util.List;
import android.app.Activity;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "nabd/foreground";
    private static final String VOICE_ID_CHANNEL = "nabd/voiceid";
    private static final String CONNECTIVITY_CHANNEL = "nabd/connectivity";
    private VoiceIdService voiceIdService;

    // إضافة هذا السطر: تعريف ToneGenerator كمتغير عام للكلاس
    private ToneGenerator toneGen;

    private Handler mainHandler;


    // Connectivity channel field
    private MethodChannel connectivityChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        Intent stopIntent = new Intent(this, PorcupainService.class);
        stopService(stopIntent);

        voiceIdService = new VoiceIdService(this);

        // إضافة هذا السطر: تهيئة ToneGenerator مرة واحدة
        toneGen = new ToneGenerator(AudioManager.STREAM_SYSTEM, 100);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "startService":
                    String apiKey = call.argument("apiKey");
                    if (apiKey == null || apiKey.isEmpty()) {
                        result.error("API_KEY_MISSING", "API key not provided.", null);
                        return;
                    }
                    Intent startServiceIntent = new Intent(this, PorcupainService.class);
                    startServiceIntent.putExtra("apiKey", apiKey);
                    startService(startServiceIntent);
                    result.success("Service Started");
                    break;
                case "stopService":
                    Intent stopServiceIntent = new Intent(this, PorcupainService.class);
                    stopService(stopServiceIntent);
                    result.success("Service Stopped");
                    break;
                case "isIgnoringBatteryOptimizations":
                    result.success(isIgnoringBatteryOptimizations());
                    break;
                case "isOverlayEnabled":
                    result.success(isOverlayEnabled());
                    break;
                case "isAccessibilityEnabled":
                    boolean enabled = isAccessibilityServiceEnabled(this, AutoOpenAccessibilityService.class);
                    result.success(enabled);
                    break;
                case "requestBatteryOptimization":
                    requestBatteryOptimization();
                    result.success(null);
                    break;
                case "requestOverlayPermission":
                    requestOverlayPermission();
                    result.success(null);
                    break;
                case "requestAccessibilityPermission":
                    requestAccessibilityPermission();
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), VOICE_ID_CHANNEL).setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "enrollVoice":
                    String accessKey = call.argument("accessKey");
                    if (accessKey == null || accessKey.isEmpty()) {
                        result.error("NO_ACCESS_KEY", "No AccessKey was provided to Eagle", null);
                        return;
                    }
                    voiceIdService.enrollVoice(this, accessKey, result);
                    break;
                case "resetEnrollment":
                    voiceIdService.resetEnrollment(this, result);
                    break;
                case "isProfileEnrolled":
                    boolean enrolled = voiceIdService.isProfileEnrolled(this);
                    result.success(enrolled);
                    break;
                case "saveVoiceProfile":
                    List<Integer> voiceProfileBytes = call.argument("voiceProfileBytes");
                    if (voiceProfileBytes != null) {
                        voiceIdService.saveVoiceProfile(this, voiceProfileBytes, result);
                    } else {
                        result.error("NO_VOICE_PROFILE", "No voice profile data provided", null);
                    }
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "navia/feedback").setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "playSuccessTone":
                    toneGen.startTone(ToneGenerator.TONE_PROP_ACK);
                    result.success(null);
                    break;
                case "playFailureTone":
                    toneGen.startTone(ToneGenerator.TONE_PROP_NACK);
                    result.success(null);
                    break;
                case "playLoadingTone":
                    toneGen.startTone(ToneGenerator.TONE_SUP_DIAL);
                    result.success(null);
                    break;
                case "playWaitingTone":
                    toneGen.startTone(ToneGenerator.TONE_SUP_CALL_WAITING);
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        // Connectivity Channel
        connectivityChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CONNECTIVITY_CHANNEL);
        connectivityChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "open_wifi_settings":
                    if (settingsLaunchedThisSession) { result.success(null); break; }
                    settingsLaunchedThisSession = true;
                    openWifiSettings();
                    result.success(null);
                    break;
                case "a11y_start":
                    if (a11yStartedThisSession) { result.success(null); break; }
                    a11yStartedThisSession = true;
                    AutoOpenAccessibilityService.startConnectivitySession();
                    result.success(null);
                    break;
                case "a11y_stop":
                    AutoOpenAccessibilityService.stopConnectivitySession();
                    result.success(null);
                    break;
                case "reset_connectivity_session_flags":
                    settingsLaunchedThisSession = false;
                    a11yStartedThisSession = false;
                    result.success(null);
                    break;
                case "connectivity_flow_start":
                    connectivityFlowActive = true;
                    settingsLaunchedThisSession = false;
                    a11yStartedThisSession = false;
                    // (optional) tell PorcupainService to suppress
                    sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", true));
                    result.success(null);
                    break;
                case "connectivity_flow_end":
                    connectivityFlowActive = false;
                    // (optional) remove suppression
                    sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
                    // reset flags
                    settingsLaunchedThisSession = false;
                    a11yStartedThisSession = false;
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });

        // Set up connectivity channel for accessibility service
        AutoOpenAccessibilityService.setConnectivityChannel(connectivityChannel);
    }

    private void openWifiSettings() {
        try {
            Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);

            // Keep Settings on top, push our task to background.
            mainHandler.postDelayed(() -> {
                try {
                    Activity activity = this;
                    if (activity != null) activity.moveTaskToBack(true);
                } catch (Throwable t) {
                    Log.w("Connectivity", "moveTaskToBack failed: " + t);
                }
            }, 150);
        } catch (Exception e) {
            Log.e("Connectivity", "openWifiSettings failed", e);
        }
    }



    // Session management flags to prevent duplicate actions
    private volatile boolean settingsLaunchedThisSession = false;
    private volatile boolean a11yStartedThisSession = false;

    // Global connectivity flow management
    private volatile boolean connectivityFlowActive = false;



    private void bringAppToFront() {
        try {
            Intent i = getPackageManager().getLaunchIntentForPackage(getPackageName());
            if (i != null) {
                i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT |
                           Intent.FLAG_ACTIVITY_SINGLE_TOP |
                           Intent.FLAG_ACTIVITY_CLEAR_TOP |
                           Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
            }
        } catch (Throwable t) {
            Log.w("Connectivity", "bringAppToFront failed: " + t);
        }
    }

    // إضافة هذه الدالة لتحرير الموارد عند إغلاق التطبيق
    @Override
    protected void onDestroy() {
        if (toneGen != null) {
            toneGen.release();
        }
        super.onDestroy();
    }

    // إضافة دوال التحقق من الأذونات المفقودة
    private boolean isIgnoringBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return getSystemService(PowerManager.class).isIgnoringBatteryOptimizations(getPackageName());
        }
        return true;
    }

    private boolean isOverlayEnabled() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.canDrawOverlays(this);
        }
        return true;
    }

    private void requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            startActivity(intent);
        } else {
            Toast.makeText(this, "هذا الإذن متاح فقط على Android 6.0 وأحدث.", Toast.LENGTH_SHORT).show();
        }
    }

    private void requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + getPackageName()));
                startActivity(intent);
            }
        }
    }

    private void requestAccessibilityPermission() {
        Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
        startActivity(intent);
        Toast.makeText(this, "يرجى البحث عن 'Noor' وتفعيل خدمة إمكانية الوصول.", Toast.LENGTH_LONG).show();
    }

    private boolean isAccessibilityServiceEnabled(Context context, Class<?> accessibilityService) {
        String expectedComponentName = context.getPackageName() + "/" + accessibilityService.getName();
        String enabledServices = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        if (enabledServices == null) return false;
        TextUtils.SimpleStringSplitter colonSplitter = new TextUtils.SimpleStringSplitter(':');
        colonSplitter.setString(enabledServices);
        while (colonSplitter.hasNext()) {
            String componentName = colonSplitter.next();
            if (componentName.equalsIgnoreCase(expectedComponentName)) {
                return true;
            }
        }
        return false;
    }
}