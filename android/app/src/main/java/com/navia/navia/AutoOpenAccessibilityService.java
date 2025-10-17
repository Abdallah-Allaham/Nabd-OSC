package com.navia.navia;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import io.flutter.plugin.common.MethodChannel;

import java.util.List;

public class AutoOpenAccessibilityService extends AccessibilityService {

    private static AutoOpenAccessibilityService instance;
    private static MethodChannel connectivityChannel;
    private Handler handler = new Handler(Looper.getMainLooper());

    // Session management
    private enum Phase {IDLE, NAVIGATING}

    private volatile boolean sessionActive = false;
    private volatile Phase phase = Phase.IDLE;
    private long sessionDeadlineMs = 0;


    public static AutoOpenAccessibilityService getInstance() {
        return instance;
    }

    public static void setConnectivityChannel(MethodChannel channel) {
        connectivityChannel = channel;
    }

    // Session management methods
    public static void startConnectivitySession() {
        AutoOpenAccessibilityService svc = getInstance();
        if (svc != null) svc.startSession();
    }

    public static void stopConnectivitySession() {
        AutoOpenAccessibilityService svc = getInstance();
        if (svc != null) svc.stopSession();
    }

    private void startSession() {
        sessionActive = true;
        phase = Phase.NAVIGATING;
        sessionDeadlineMs = System.currentTimeMillis() + 20_000; // 20 second timeout
        Log.d("A11y", "Connectivity session started");
    }

    private void stopSession() {
        sessionActive = false;
        phase = Phase.IDLE;
        handler.removeCallbacksAndMessages(null);
        Log.d("A11y", "Connectivity session stopped");
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Session management - do nothing if no active session
        if (!sessionActive) return;
        if (System.currentTimeMillis() > sessionDeadlineMs) {
            Log.d("A11y", "session timeout -> stop");
            stopSession();
            return;
        }

        String pkg = event.getPackageName() == null ? "" : event.getPackageName().toString();

        // Only proceed for Settings app - strict boundary
        if (!pkg.contains("com.android.settings")) {
            return; // Ignore everything outside Settings
        }

        // Route by phase
        if (phase == Phase.NAVIGATING && (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
                event.getEventType() == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)) {

            handler.postDelayed(() -> {
                AccessibilityNodeInfo root = getRootInActiveWindow();
                if (root == null) return;
                try {
                    Log.d("A11y", "Phase NAVIGATING: Attempting to click connected Wi-Fi row...");
                    clickConnectedRowIfFound(root);
                } finally {
                    if (root != null) root.recycle();
                }
            }, 300); // Small debounce after content changes
        }
    }


    private boolean isSectionHeader(CharSequence text) {
        if (text == null) return false;
        String s = text.toString();
        return s.contains("بالشبكة اللاسلكية"); // Arabic header: "connected to the wireless network"
    }

    private AccessibilityNodeInfo findConnectedWifiNode(AccessibilityNodeInfo rootNode) {
        Log.d("A11y", "Searching for connected Wi-Fi node...");

        // First, try to find by the "متصل" text directly
        String[] connectedTexts = {"متصل", "Connected", "Connected, secured", "متصل، محمي"};

        for (String text : connectedTexts) {
            List<AccessibilityNodeInfo> nodes = rootNode.findAccessibilityNodeInfosByText(text);
            Log.d("A11y", "Found " + nodes.size() + " nodes with text: " + text);

            for (AccessibilityNodeInfo node : nodes) {
                if (node.getText() != null &&
                        (node.getText().toString().contains("متصل") ||
                                node.getText().toString().contains("Connected"))) {

                    // Skip section headers
                    if (isSectionHeader(node.getText())) {
                        Log.d("A11y", "Skipping section header: " + node.getText());
                        continue;
                    }

                    Log.d("A11y", "Found connected node with text: " + node.getText());
                    return node;
                }
            }
        }

        // Try to find by content description
        List<AccessibilityNodeInfo> allNodes = rootNode.findAccessibilityNodeInfosByText("");
        Log.d("AccessibilityService", "Searching " + allNodes.size() + " nodes by content description");

        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getContentDescription() != null) {
                String desc = node.getContentDescription().toString();
                if (desc.contains("متصل") || desc.contains("Connected")) {
                    Log.d("AccessibilityService", "Found connected node with description: " + desc);
                    return node;
                }
            }
        }

        return null;
    }

    // الدالة المسؤولة عن البحث عن شبكة الواي فاي المتصلة والنقر عليها
    private void clickConnectedRowIfFound(AccessibilityNodeInfo root) {
        if (phase != Phase.NAVIGATING) return;

        // البحث عن شبكة الواي فاي المتصلة
        AccessibilityNodeInfo connectedNode = findConnectedWifiNode(root);

        if (connectedNode != null) {
            Log.d("A11y", "Connected WiFi node found.");

            // محاولة إيجاد العنصر القابل للنقر (قد يكون الأب أو الجار)
            AccessibilityNodeInfo clickable = findClickableParent(connectedNode);
            if (clickable == null) {
                clickable = findNearbyClickable(connectedNode);
            }

            if (clickable != null && clickable.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                Log.d("A11y", "Successfully clicked on connected WiFi row. Stopping session.");
                // **نجاح النقر:** توقف الجلسة فوراً
                stopSession();
            }
        }

        Log.d("A11y", "No clickable connected WiFi row found, waiting for next event.");
    }


    private AccessibilityNodeInfo findClickableParent(AccessibilityNodeInfo node) {
        AccessibilityNodeInfo parent = node.getParent();
        int depth = 0;
        while (parent != null && depth < 10) { // Prevent infinite loops
            if (parent.isClickable()) {
                Log.d("AccessibilityService", "Found clickable parent at depth: " + depth);
                return parent;
            }
            parent = parent.getParent();
            depth++;
        }
        return null;
    }

    private AccessibilityNodeInfo findNearbyClickable(AccessibilityNodeInfo node) {
        // Try to find siblings or nearby elements that are clickable
        AccessibilityNodeInfo parent = node.getParent();
        if (parent != null) {
            for (int i = 0; i < parent.getChildCount(); i++) {
                AccessibilityNodeInfo sibling = parent.getChild(i);
                if (sibling != null && sibling.isClickable()) {
                    Log.d("AccessibilityService", "Found clickable sibling");
                    return sibling;
                }
            }
        }
        return null;
    }

    @Override
    public void onInterrupt() {
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        Log.d("A11y", "Service connected");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopSession(); // Clean up session on destroy
        Log.d("A11y", "Service destroyed");
    }

    public static void launchApp(AutoOpenAccessibilityService service) {
        if (service != null) {
            Intent intent = new Intent(service, MainActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        }
    }
}
