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
import java.util.HashMap;
import android.app.Activity;

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
    private volatile boolean screenCaptureReady = false;
    
    // --- Prewarm state ---
    private ImageReader prewarmReader;
    private VirtualDisplay prewarmVD;
    private volatile boolean prewarmActive = false;
    private final Object prewarmLock = new Object();
    
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
                            if (screenCaptureReady || waitingForPermission) { 
                                result.success(true); 
                                return; 
                            }
                            waitingForPermission = true;
                            boolean granted = requestScreenCapturePermission();
                            result.success(granted);
                            break;
                case "open_wifi_settings":
                    if (settingsLaunchedThisSession) { result.success(null); break; }
                    settingsLaunchedThisSession = true;
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
                        case "is_screen_capture_ready":
                            result.success(isScreenCaptureReady());
                            break;
                        case "reset_connectivity_session_flags":
                            settingsLaunchedThisSession = false;
                            a11yStartedThisSession = false;
                            isCapturing = false;
                            qrDelivered = false;
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
                        case "get_wifi_password":
                            String ssid = call.argument("ssid");
                            String password = getWifiPassword(ssid);
                            result.success(password);
                            break;
                        case "prewarm_start":
                            startPrewarmCapture();
                            result.success(null);
                            break;
                        case "prewarm_stop":
                            stopPrewarmCapture();
                            result.success(null);
                            break;
                        case "capture_from_prewarm": {
                            Image img = acquireLatestPrewarmImage();
                            if (img == null) {
                                sendFailure("NO_FRAME");
                                result.success(false);
                                break;
                            }
                            processImageFromImage(img, /*fromPrewarm*/true);
                            result.success(true);
                            break;
                        }
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
            return true; // يعني "تم إطلاق الطلب" فقط، مش "جاهز"
        }
        return false;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == SCREEN_CAPTURE_REQUEST_CODE) {
            waitingForPermission = false;  // مهم
            if (resultCode == RESULT_OK && data != null) {
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data);
                screenCaptureReady = (mediaProjection != null);
                Log.d("Connectivity", "MediaProjection permission granted, ready: " + screenCaptureReady);
                // ابعت الحدث مرة واحدة فقط
                if (screenCaptureReady) {
                    mainHandler.post(() -> {
                        if (connectivityChannel != null) {
                            connectivityChannel.invokeMethod("screen_capture_ready", null);
                        }
                    });
                }
            } else {
                screenCaptureReady = false;
                Log.d("Connectivity", "MediaProjection permission denied");
                mainHandler.post(() -> {
                    if (connectivityChannel != null) {
                        java.util.HashMap<String, Object> err = new java.util.HashMap<>();
                        err.put("reason", "PERMISSION_DENIED");
                        connectivityChannel.invokeMethod("failure", err);
                    }
                });
            }
        }
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

    private boolean isScreenCaptureReady() {
        return screenCaptureReady && mediaProjection != null;
    }

    private void captureScreenOnce() {
        if (!isScreenCaptureReady()) {
            Log.d("Connectivity", "MediaProjection not available, ready: " + screenCaptureReady);
            sendFailure("PERMISSION_DENIED");
            return;
        }
        
        if (isCapturing) { 
            Log.d("Connectivity", "Capture already in progress"); 
            return; 
        }
        isCapturing = true;
        qrDelivered = false;

        // Reset retry count for new capture attempt
        retryCount = 0;
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
                if (qrDelivered) return; // منع المعالجة المتكررة
                executorService.execute(() -> {
                    try {
                        Image image = reader.acquireLatestImage();
                        if (image != null) {
                            processCapturedImage(image);
                            image.close();
                        } else {
                            // FLAG_SECURE detected - image is null
                            Log.d("Connectivity", "FLAG_SECURE detected - image is null");
                            if (connectivityChannel != null) {
                                connectivityChannel.invokeMethod("capture_blocked", null);
                            }
                        }
                    } catch (SecurityException e) {
                        Log.d("Connectivity", "FLAG_SECURE SecurityException detected");
                        if (connectivityChannel != null) {
                            connectivityChannel.invokeMethod("capture_blocked", null);
                        }
                    } catch (Exception e) {
                        Log.e("Connectivity", "Error processing captured image", e);
                        if (connectivityChannel != null) {
                            java.util.HashMap<String, Object> err = new java.util.HashMap<>();
                            err.put("reason", "CAPTURE_ERROR");
                            connectivityChannel.invokeMethod("failure", err);
                        }
                    }
                });
            }
        }, mainHandler);

        // Create VirtualDisplay for this capture attempt
        android.hardware.display.VirtualDisplay vd = null;
        try {
            vd = mediaProjection.createVirtualDisplay(
                "ScreenCapture",
                width, height, density,
                android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader.getSurface(),
                null, null
            );
            
            Log.d("Connectivity", "VirtualDisplay created: " + width + "x" + height + ", density: " + density);
            
            // Stop capture after a short delay
            final android.hardware.display.VirtualDisplay finalVd = vd;
            mainHandler.postDelayed(() -> {
                if (finalVd != null) {
                    finalVd.release();
                    Log.d("Connectivity", "VirtualDisplay released");
                }
                if (imageReader != null) {
                    imageReader.close();
                    imageReader = null;
                    Log.d("Connectivity", "ImageReader closed");
                }
            }, 2000); // Capture for 2 seconds
            
        } catch (SecurityException se) {
            Log.d("Connectivity", "FLAG_SECURE SecurityException in createVirtualDisplay");
            if (connectivityChannel != null) {
                connectivityChannel.invokeMethod("capture_blocked", null);
            }
            if (vd != null) vd.release();
            if (imageReader != null) {
                imageReader.close();
                imageReader = null;
            }
        }
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
        if (qrDelivered) return; // منع المعالجة المتكررة
        
        InputImage inputImage = InputImage.fromBitmap(bitmap, 0);
        
        com.google.mlkit.vision.barcode.BarcodeScanner scanner = BarcodeScanning.getClient();
        
        scanner.process(inputImage)
            .addOnSuccessListener(barcodes -> {
                if (qrDelivered) return; // منع المعالجة المتكررة
                
                for (Barcode barcode : barcodes) {
                    // First try: ML Kit WiFi type
                    if (barcode.getValueType() == Barcode.TYPE_WIFI) {
                        Barcode.WiFi wifi = barcode.getWifi();
                        if (wifi != null) {
                            String ssid = wifi.getSsid();
                            String password = wifi.getPassword();
                            
                            Log.d("Connectivity", "Found Wi-Fi QR via ML Kit: SSID=" + ssid);
                            
                            deliverQrResult(ssid, password);
                            return;
                        }
                    }
                    
                    // Second try: Raw text parsing for WIFI: format
                    String rawValue = barcode.getRawValue();
                    if (rawValue != null && rawValue.startsWith("WIFI:")) {
                        parseWifiString(rawValue);
                        return;
                    }
                }
                
                // No QR found, try retry (max 1 retry)
                Log.d("Connectivity", "No Wi-Fi QR found, attempting retry...");
                retryCapture();
            })
            .addOnFailureListener(e -> {
                Log.e("Connectivity", "ML Kit processing failed", e);
                sendFailure("DECODE_FAILED");
            });
    }

    private void parseWifiString(String wifiString) {
        if (qrDelivered) return; // منع المعالجة المتكررة
        
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
            
            deliverQrResult(ssid, password);
        } catch (Exception e) {
            Log.e("Connectivity", "Error parsing Wi-Fi string", e);
            retryCapture();
        }
    }

    private int retryCount = 0;
    private static final int MAX_RETRIES = 1;
    
    // Session management flags to prevent duplicate actions
    private volatile boolean waitingForPermission = false;
    private volatile boolean settingsLaunchedThisSession = false;
    private volatile boolean a11yStartedThisSession = false;
    private volatile boolean isCapturing = false;
    private volatile boolean qrDelivered = false;
    
    // Global connectivity flow management
    private volatile boolean connectivityFlowActive = false;

    private void retryCapture() {
        if (retryCount < MAX_RETRIES) {
            retryCount++;
            // Quick retry within 300ms as specified in requirements
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                if (mediaProjection != null) {
                    captureScreenOnce();
                }
            }, 300);
        } else {
            // Max retries reached, send failure event
            if (connectivityChannel != null) {
                java.util.HashMap<String, Object> err = new java.util.HashMap<>();
                err.put("reason", "TIMEOUT");
                connectivityChannel.invokeMethod("failure", err);
            }
        }
    }

    private void setFlagSecure(boolean enable) {
        if (enable) {
            getWindow().setFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE,
                    android.view.WindowManager.LayoutParams.FLAG_SECURE);
        } else {
            getWindow().clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE);
        }
    }

    private void cleanupCapture() {
        try { 
            if (imageReader != null) { 
                imageReader.close(); 
                imageReader = null; 
            } 
        } catch (Exception ignore) {}
        isCapturing = false; // مهم
    }

    private void deliverQrResult(String ssid, String password) {
        if (qrDelivered) return;
        qrDelivered = true;
        // 1) stop prewarm
        stopPrewarmCapture();
        // 2) bring app to front
        bringAppToFront();
        // 3) invoke result back to Flutter
        final HashMap<String, Object> payload = new HashMap<>();
        payload.put("ssid", ssid);
        payload.put("password", password);
        mainHandler.post(() -> {
            if (connectivityChannel != null) {
                connectivityChannel.invokeMethod("qr_parsed", payload);
            }
            sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
        });
        cleanupCapture();
    }

    private void sendFailure(String reason) {
        if (qrDelivered) return;
        qrDelivered = true;
        // 1) stop prewarm
        stopPrewarmCapture();
        // 2) bring app to front
        bringAppToFront();
        // 3) invoke result back to Flutter
        final HashMap<String, Object> err = new HashMap<>();
        err.put("reason", reason);
        mainHandler.post(() -> {
            if (connectivityChannel != null) {
                connectivityChannel.invokeMethod("failure", err);
            }
            sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
        });
        cleanupCapture();
    }

    private void takeScreenshotAndReturn() {
        try {
            // Take a screenshot using MediaProjection
            if (mediaProjection != null) {
                // Create a new ImageReader for screenshot
                android.util.DisplayMetrics dm = getResources().getDisplayMetrics();
                int width = dm.widthPixels;
                int height = dm.heightPixels;
                int density = dm.densityDpi;
                
                ImageReader screenshotReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 1);
                
                screenshotReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
                    @Override
                    public void onImageAvailable(ImageReader reader) {
                        executorService.execute(() -> {
                            try {
                                Image image = reader.acquireLatestImage();
                                if (image != null) {
                                    // Convert to bitmap and decode QR code from screenshot
                                    Bitmap screenshot = imageToBitmap(image);
                                    if (screenshot != null) {
                                        Log.d("Connectivity", "Screenshot taken successfully, decoding QR code...");
                                        // Decode QR code from screenshot
                                        decodeQrFromScreenshot(screenshot);
                                    }
                                    image.close();
                                }
                            } catch (Exception e) {
                                Log.e("Connectivity", "Error processing screenshot", e);
                                // Fallback: return to app without QR data
                                mainHandler.post(() -> {
                                    bringAppToFront();
                                    sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
                                });
                            }
                        });
                    }
                }, mainHandler);
                
                // Create VirtualDisplay for screenshot
                android.hardware.display.VirtualDisplay screenshotVd = mediaProjection.createVirtualDisplay(
                    "Screenshot",
                    width, height, density,
                    android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    screenshotReader.getSurface(),
                    null, null
                );
                
                // Take screenshot and then return to app
                mainHandler.postDelayed(() -> {
                    if (screenshotVd != null) {
                        screenshotVd.release();
                    }
                    if (screenshotReader != null) {
                        screenshotReader.close();
                    }
                }, 1000); // Give more time for QR decoding
            } else {
                // If no MediaProjection, just return to app
                bringAppToFront();
                sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
            }
        } catch (Exception e) {
            Log.e("Connectivity", "Error taking screenshot", e);
            // Fallback: just return to app
            bringAppToFront();
            sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
        }
    }

    private void decodeQrFromScreenshot(Bitmap screenshot) {
        try {
            InputImage inputImage = InputImage.fromBitmap(screenshot, 0);
            com.google.mlkit.vision.barcode.BarcodeScanner scanner = BarcodeScanning.getClient();
            
            scanner.process(inputImage)
                .addOnSuccessListener(barcodes -> {
                    for (Barcode barcode : barcodes) {
                        // Try to find WiFi QR code
                        if (barcode.getValueType() == Barcode.TYPE_WIFI) {
                            Barcode.WiFi wifi = barcode.getWifi();
                            if (wifi != null) {
                                final String ssid = wifi.getSsid();
                                final String password = wifi.getPassword();
                                
                                Log.d("Connectivity", "Found Wi-Fi QR in screenshot: SSID=" + ssid);
                                
                                // Send the decoded data back to Flutter
                                mainHandler.post(() -> {
                                    HashMap<String, Object> payload = new HashMap<>();
                                    payload.put("ssid", ssid);
                                    payload.put("password", password);
                                    if (connectivityChannel != null) {
                                        connectivityChannel.invokeMethod("qr_parsed", payload);
                                    }
                                    bringAppToFront();
                                    sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
                                });
                                return;
                            }
                        }
                        
                        // Also try raw text parsing for WIFI: format
                        String rawValue = barcode.getRawValue();
                        if (rawValue != null && rawValue.startsWith("WIFI:")) {
                            parseWifiStringFromScreenshot(rawValue);
                            return;
                        }
                    }
                    
                    // No WiFi QR found in screenshot
                    Log.d("Connectivity", "No WiFi QR code found in screenshot");
                    mainHandler.post(() -> {
                        HashMap<String, Object> err = new HashMap<>();
                        err.put("reason", "NO_WIFI_QR_FOUND");
                        if (connectivityChannel != null) {
                            connectivityChannel.invokeMethod("failure", err);
                        }
                        bringAppToFront();
                        sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
                    });
                })
                .addOnFailureListener(e -> {
                    Log.e("Connectivity", "Failed to decode QR from screenshot", e);
                    mainHandler.post(() -> {
                        HashMap<String, Object> err = new HashMap<>();
                        err.put("reason", "QR_DECODE_FAILED");
                        if (connectivityChannel != null) {
                            connectivityChannel.invokeMethod("failure", err);
                        }
                        bringAppToFront();
                        sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
                    });
                });
        } catch (Exception e) {
            Log.e("Connectivity", "Error decoding QR from screenshot", e);
            mainHandler.post(() -> {
                HashMap<String, Object> err = new HashMap<>();
                err.put("reason", "QR_DECODE_ERROR");
                if (connectivityChannel != null) {
                    connectivityChannel.invokeMethod("failure", err);
                }
                bringAppToFront();
                sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
            });
        }
    }

    private void parseWifiStringFromScreenshot(String wifiString) {
        try {
            // Parse "WIFI:S:SSID;T:WPA;P:PASSWORD;;" format
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
            
            // Make variables final for lambda
            final String finalSsid = ssid;
            final String finalPassword = password;
            
            Log.d("Connectivity", "Parsed Wi-Fi from screenshot: SSID=" + finalSsid + ", Password=" + finalPassword);
            
            // Send the decoded data back to Flutter
            mainHandler.post(() -> {
                HashMap<String, Object> payload = new HashMap<>();
                payload.put("ssid", finalSsid);
                payload.put("password", finalPassword);
                if (connectivityChannel != null) {
                    connectivityChannel.invokeMethod("qr_parsed", payload);
                }
                bringAppToFront();
                sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
            });
        } catch (Exception e) {
            Log.e("Connectivity", "Error parsing Wi-Fi string from screenshot", e);
            mainHandler.post(() -> {
                HashMap<String, Object> err = new HashMap<>();
                err.put("reason", "WIFI_PARSE_ERROR");
                if (connectivityChannel != null) {
                    connectivityChannel.invokeMethod("failure", err);
                }
                bringAppToFront();
                sendBroadcast(new Intent("com.navia.navia.PORCUPINE_SUPPRESS").putExtra("suppress", false));
            });
        }
    }

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

    private String getWifiPassword(String ssid) {
        try {
            // Try to get WiFi password from system using reflection
            // This is a more direct approach to get the saved password
            android.net.wifi.WifiManager wifiManager = (android.net.wifi.WifiManager) getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null) {
                // Get the current WiFi configuration
                List<android.net.wifi.WifiConfiguration> configurations = wifiManager.getConfiguredNetworks();
                if (configurations != null) {
                    for (android.net.wifi.WifiConfiguration config : configurations) {
                        if (config.SSID != null && config.SSID.equals("\"" + ssid + "\"")) {
                            // Found the network configuration
                            if (config.preSharedKey != null && !config.preSharedKey.isEmpty()) {
                                // Remove quotes from the password
                                String password = config.preSharedKey.replace("\"", "");
                                Log.d("Connectivity", "Found WiFi password for " + ssid + ": " + password);
                                return password;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            Log.e("Connectivity", "Error getting WiFi password: " + e.getMessage());
        }
        
        // Fallback: return a default password or empty string
        Log.d("Connectivity", "Could not retrieve WiFi password for " + ssid);
        return "";
    }

    private void startPrewarmCapture() {
        synchronized (prewarmLock) {
            if (prewarmActive) return;
            if (mediaProjection == null) {
                Log.d("Connectivity", "startPrewarmCapture: mediaProjection null");
                return;
            }
            final android.util.DisplayMetrics dm = getResources().getDisplayMetrics();
            final int width = dm.widthPixels;
            final int height = dm.heightPixels;
            final int density = dm.densityDpi;

            prewarmReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, /*maxImages*/2);
            android.view.Surface surface = prewarmReader.getSurface();
            try {
                prewarmVD = mediaProjection.createVirtualDisplay(
                    "PrewarmVD",
                    width, height, density,
                    android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_OWN_CONTENT_ONLY
                            | android.hardware.display.DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC,
                    surface, null, null
                );
                prewarmActive = true;
                Log.d("Connectivity", "Prewarm VD created: " + width + "x" + height + ", density: " + density);
            } catch (SecurityException se) {
                Log.d("Connectivity", "FLAG_SECURE SecurityException during prewarm");
                // We'll fallback later.
                stopPrewarmCapture();
                sendFailure("CAPTURE_BLOCKED");
            }
        }
    }

    private void stopPrewarmCapture() {
        synchronized (prewarmLock) {
            if (!prewarmActive) return;
            try { if (prewarmVD != null) prewarmVD.release(); } catch (Throwable ignored) {}
            try { if (prewarmReader != null) prewarmReader.close(); } catch (Throwable ignored) {}
            prewarmVD = null;
            prewarmReader = null;
            prewarmActive = false;
            Log.d("Connectivity", "Prewarm stopped");
        }
    }

    private Image acquireLatestPrewarmImage() {
        synchronized (prewarmLock) {
            if (!prewarmActive || prewarmReader == null) return null;
            try { return prewarmReader.acquireLatestImage(); } catch (Throwable t) { return null; }
        }
    }

    private void bringAppToFront() {
        Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(intent);
        }
    }
}