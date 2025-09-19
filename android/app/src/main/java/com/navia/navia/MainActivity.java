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
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "nabd/foreground";
    private static final String VOICE_ID_CHANNEL = "nabd/voiceid";
    private static final String CONNECTIVITY_CHANNEL = "nabd/connectivity";
    private VoiceIdService voiceIdService;

    // إضافة هذا السطر: تعريف ToneGenerator كمتغير عام للكلاس
    private ToneGenerator toneGen;

    // MediaProjection fields
    private MediaProjectionManager mediaProjectionManager;
    private MediaProjection mediaProjection;
    private ImageReader imageReader;
    private Handler mainHandler;
    private ExecutorService executorService;
    private static final int SCREEN_CAPTURE_REQUEST_CODE = 1001;
    
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

        // Initialize MediaProjection components
        mediaProjectionManager = (MediaProjectionManager) getSystemService(Context.MEDIA_PROJECTION_SERVICE);
        mainHandler = new Handler(Looper.getMainLooper());
        executorService = Executors.newSingleThreadExecutor();

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
                case "request_screen_capture":
                    boolean granted = requestScreenCapturePermission();
                    result.success(granted);
                    break;
                case "open_wifi_settings":
                    openWifiSettings();
                    result.success(null);
                    break;
                case "capture_once":
                    captureScreenOnce();
                    result.success(null);
                    break;
                case "set_flag_secure":
                    boolean enable = call.argument("enable");
                    setFlagSecure(enable);
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

    // Connectivity methods
    private boolean requestScreenCapturePermission() {
        if (mediaProjectionManager != null) {
            Intent captureIntent = mediaProjectionManager.createScreenCaptureIntent();
            startActivityForResult(captureIntent, SCREEN_CAPTURE_REQUEST_CODE);
            return true;
        }
        return false;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data);
                Log.d("Connectivity", "MediaProjection permission granted");
            } else {
                Log.d("Connectivity", "MediaProjection permission denied");
                // Notify Flutter about permission denial
                if (connectivityChannel != null) {
                    java.util.HashMap<String, Object> err = new java.util.HashMap<>();
                    err.put("reason", "PERMISSION_DENIED");
                    connectivityChannel.invokeMethod("failure", err);
                }
            }
        }
    }

    private void openWifiSettings() {
        Intent intent = new Intent(Settings.ACTION_WIFI_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void captureScreenOnce() {
        if (mediaProjection == null) {
            Log.d("Connectivity", "MediaProjection not available");
            return;
        }

        Log.d("Connectivity", "Starting screen capture...");
        
        // Use real screen size
        android.util.DisplayMetrics dm = getResources().getDisplayMetrics();
        int width = dm.widthPixels;
        int height = dm.heightPixels;
        int density = dm.densityDpi;
        
        // Create ImageReader for screen capture
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2);
        
        imageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader reader) {
                executorService.execute(() -> {
                    try {
                        Image image = reader.acquireLatestImage();
                        if (image != null) {
                            processCapturedImage(image);
                            image.close();
                        }
                    } catch (Exception e) {
                        Log.e("Connectivity", "Error processing captured image", e);
                    }
                });
            }
        }, mainHandler);

        // Start screen capture
        mediaProjection.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.getSurface(),
            null, null
        );

        // Stop capture after a short delay
        mainHandler.postDelayed(() -> {
            if (mediaProjection != null) {
                mediaProjection.stop();
                mediaProjection = null;
            }
            if (imageReader != null) {
                imageReader.close();
                imageReader = null;
            }
        }, 2000); // Capture for 2 seconds
    }

    private void processCapturedImage(Image image) {
        try {
            // Convert Image to Bitmap
            Bitmap bitmap = imageToBitmap(image);
            if (bitmap != null) {
                // Process with ML Kit
                processImageWithMLKit(bitmap);
            }
        } catch (Exception e) {
            Log.e("Connectivity", "Error processing image", e);
        }
    }

    private Bitmap imageToBitmap(Image image) {
        Image.Plane plane = image.getPlanes()[0];
        java.nio.ByteBuffer buf = plane.getBuffer();
        int pixelStride = plane.getPixelStride();
        int rowStride = plane.getRowStride();
        int rowPadding = rowStride - pixelStride * image.getWidth();
        Bitmap bmp = Bitmap.createBitmap(
            image.getWidth() + rowPadding / pixelStride,
            image.getHeight(),
            Bitmap.Config.ARGB_8888
        );
        bmp.copyPixelsFromBuffer(buf);
        // crop to the real content width
        return Bitmap.createBitmap(bmp, 0, 0, image.getWidth(), image.getHeight());
    }

    private void processImageWithMLKit(Bitmap bitmap) {
        InputImage inputImage = InputImage.fromBitmap(bitmap, 0);
        
        com.google.mlkit.vision.barcode.BarcodeScanner scanner = BarcodeScanning.getClient();
        
        scanner.process(inputImage)
            .addOnSuccessListener(barcodes -> {
                for (Barcode barcode : barcodes) {
                    if (barcode.getValueType() == Barcode.TYPE_WIFI) {
                        Barcode.WiFi wifi = barcode.getWifi();
                        if (wifi != null) {
                            String ssid = wifi.getSsid();
                            String password = wifi.getPassword();
                            
                            Log.d("Connectivity", "Found Wi-Fi QR: SSID=" + ssid + ", Password=" + password);
                            
                            // Notify Flutter with the parsed data
                            if (connectivityChannel != null) {
                                java.util.HashMap<String, Object> payload = new java.util.HashMap<>();
                                payload.put("ssid", ssid);
                                payload.put("password", password);
                                connectivityChannel.invokeMethod("qr_parsed", payload);
                            }
                            return;
                        }
                    }
                }
                
                // If no Wi-Fi QR found, try to parse raw text
                for (Barcode barcode : barcodes) {
                    String rawValue = barcode.getRawValue();
                    if (rawValue != null && rawValue.startsWith("WIFI:")) {
                        parseWifiString(rawValue);
                        return;
                    }
                }
                
                // No QR found, try retry
                Log.d("Connectivity", "No Wi-Fi QR found, attempting retry...");
                retryCapture();
            })
            .addOnFailureListener(e -> {
                Log.e("Connectivity", "ML Kit processing failed", e);
                retryCapture();
            });
    }

    private void parseWifiString(String wifiString) {
        // Parse "WIFI:S:SSID;T:WPA;P:PASSWORD;;" format
        try {
            String[] parts = wifiString.split(";");
            String ssid = "";
            String password = "";
            
            for (String part : parts) {
                if (part.startsWith("S:")) {
                    ssid = part.substring(2);
                } else if (part.startsWith("P:")) {
                    password = part.substring(2);
                }
            }
            
            Log.d("Connectivity", "Parsed Wi-Fi: SSID=" + ssid + ", Password=" + password);
            
            if (connectivityChannel != null) {
                java.util.HashMap<String, Object> payload = new java.util.HashMap<>();
                payload.put("ssid", ssid);
                payload.put("password", password);
                connectivityChannel.invokeMethod("qr_parsed", payload);
            }
        } catch (Exception e) {
            Log.e("Connectivity", "Error parsing Wi-Fi string", e);
            retryCapture();
        }
    }

    private void retryCapture() {
        // Quick retry within 300ms as specified in requirements
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (mediaProjection != null) {
                captureScreenOnce();
            }
        }, 300);
    }

    private void setFlagSecure(boolean enable) {
        if (enable) {
            getWindow().setFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE,
                    android.view.WindowManager.LayoutParams.FLAG_SECURE);
        } else {
            getWindow().clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE);
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
        Toast.makeText(this, "يرجى البحث عن 'Navia' وتفعيل خدمة إمكانية الوصول.", Toast.LENGTH_LONG).show();
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