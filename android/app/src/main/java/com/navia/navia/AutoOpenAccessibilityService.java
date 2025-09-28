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
import java.util.ArrayList;

public class AutoOpenAccessibilityService extends AccessibilityService {

    private static AutoOpenAccessibilityService instance;
    private static MethodChannel connectivityChannel;
    private Handler handler = new Handler(Looper.getMainLooper());
    
    // Session management
    private enum Phase { IDLE, LIST, DETAILS, SHARE, QR }
    private volatile boolean sessionActive = false;
    private volatile Phase phase = Phase.IDLE;
    private long sessionDeadlineMs = 0;
    
    // QR screen detection hints (AR/EN)
    private static final String[] QR_SCREEN_HINTS = new String[]{
        "قم بقراءة رمز QR",           // AR: "Scan the QR code..."
        "رمز QR",                     // generic Arabic substring
        "رمز الاستجابة السريعة",       // Arabic
        "Scan QR code",               // EN
        "QR code",                    // EN generic
        "Share Wi-Fi QR",            // some OEMs
        "Share Wi-Fi",               // some OEMs
        "QR",                        // generic
        "رمز"                        // Arabic generic
    };

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
        phase = Phase.LIST;
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
        Log.d("A11y", "event pkg=" + pkg + " type=" + event.getEventType() + " phase=" + phase);
        
        // Only proceed for Settings app - strict boundary
        if (!pkg.contains("com.android.settings")) {
            return; // Ignore everything outside Settings
        }
        
        // Route by phase
        if (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.getEventType() == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            
            handler.postDelayed(() -> {
                AccessibilityNodeInfo root = getRootInActiveWindow();
                if (root == null) return;
                try {
                    // Check QR visibility first in any phase
                    if (isQrScreenVisible(root)) {
                        Log.d("A11y", "QR screen detected (direct or post-share)");
                        onQrVisible();
                        return;
                    }
                    
                    switch (phase) {
                        case LIST:
                            Log.d("A11y", "No QR yet — searching for connected row...");
                            clickConnectedRowIfFound(root);
                            break;
                        case DETAILS:
                            Log.d("A11y", "No QR yet — searching for Share button...");
                            clickShareIfFound(root);
                            break;
                        case SHARE:
                            Log.d("A11y", "Waiting for QR screen to appear...");
                            // QR detection already checked above
                            break;
                        default:
                            break;
                    }
                } finally {
                    root.recycle();
                }
            }, 300); // Small debounce after content changes
        }
    }

    // Phase-based navigation methods
    private void clickConnectedRowIfFound(AccessibilityNodeInfo root) {
        Log.d("A11y", "Phase LIST: Looking for connected WiFi row");
        
        // Signal that WiFi settings list is visible (for prewarm start)
        if (connectivityChannel != null) {
            connectivityChannel.invokeMethod("settings_list_visible", null);
        }
        
        // Look for connected WiFi network
        AccessibilityNodeInfo connectedNode = findConnectedWifiNode(root);
        if (connectedNode != null) {
            Log.d("A11y", "Found connected WiFi node");
            
            // Try to find clickable parent or sibling
            AccessibilityNodeInfo clickable = findClickableParent(connectedNode);
            if (clickable == null) {
                clickable = findNearbyClickable(connectedNode);
            }
            
            if (clickable != null && clickable.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                Log.d("A11y", "Connected row clicked successfully");
                phase = Phase.DETAILS;
                return;
            }
        }
        
        Log.d("A11y", "No connected WiFi row found");
    }

    private void clickShareIfFound(AccessibilityNodeInfo root) {
        Log.d("A11y", "Phase DETAILS: Looking for share button");
        
        AccessibilityNodeInfo shareNode = findShareButton(root);
        if (shareNode != null) {
            if (shareNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                Log.d("A11y", "Share button clicked successfully");
                phase = Phase.SHARE;
                return;
            }
        }
        
        Log.d("A11y", "No share button found - waiting for QR or next content change");
        // Don't click anything else - wait for QR screen or next content change
    }

    private boolean isQrScreenVisible(AccessibilityNodeInfo root) {
        // 1) Check for explicit QR screen hints
        for (String hint : QR_SCREEN_HINTS) {
            List<AccessibilityNodeInfo> hits = root.findAccessibilityNodeInfosByText(hint);
            if (hits != null && !hits.isEmpty()) {
                Log.d("A11y", "QR screen detected with text: " + hint);
                return true;
            }
        }
        
        // 2) Check contentDescription for QR indicators
        List<AccessibilityNodeInfo> all = root.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo n : all) {
            CharSequence cd = n.getContentDescription();
            if (cd != null) {
                String d = cd.toString();
                for (String hint : QR_SCREEN_HINTS) {
                    if (d.contains(hint) || d.toLowerCase().contains("qr")) {
                        Log.d("A11y", "QR screen detected in contentDescription: " + d);
                        return true;
                    }
                }
            }
        }
        
        return false;
    }

    private void onQrVisible() {
        Log.d("A11y", "QR screen visible - notifying Flutter to capture from prewarm");
        
        // Simply notify Flutter that QR is visible - don't try to extract here
        // Flutter will handle the prewarm capture
        if (connectivityChannel != null) {
            connectivityChannel.invokeMethod("qr_visible", null);
        }
        
        phase = Phase.QR;
        stopSession(); // Stop listening to everything immediately
    }

    private void handleWifiSettingsNavigation() {
        AccessibilityNodeInfo rootNode = getRootInActiveWindow();
        if (rootNode == null) {
            Log.d("AccessibilityService", "Root node is null");
            return;
        }

        try {
            Log.d("AccessibilityService", "Starting Wi-Fi navigation");
            Log.d("AccessibilityService", "Root node class: " + rootNode.getClassName());
            Log.d("AccessibilityService", "Root node text: " + rootNode.getText());
            Log.d("AccessibilityService", "Root node content description: " + rootNode.getContentDescription());
            
            // Log all text content in the UI to help debug
            logAllTextContent(rootNode, 0);
            
            // First, look for share button (we might already be in Wi-Fi details)
            AccessibilityNodeInfo shareNode = findShareButton(rootNode);
            if (shareNode != null) {
                Log.d("AccessibilityService", "Found share button - already in Wi-Fi details");
                AccessibilityNodeInfo clickable = findClickableParent(shareNode);
                if (clickable != null && clickable.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                    // Notify Flutter that QR is visible
                    if (connectivityChannel != null) {
                        connectivityChannel.invokeMethod("qr_visible", null);
                    }
                    return;
                }
            }

            // Look for connected Wi-Fi network
            AccessibilityNodeInfo connectedNode = findConnectedWifiNode(rootNode);
            if (connectedNode != null) {
                Log.d("AccessibilityService", "Found connected Wi-Fi node");
                Log.d("AccessibilityService", "Connected node class: " + connectedNode.getClassName());
                Log.d("AccessibilityService", "Connected node text: " + connectedNode.getText());
                Log.d("AccessibilityService", "Connected node clickable: " + connectedNode.isClickable());
                
                // Try multiple clicking strategies
                boolean clickSuccess = false;
                
                // Strategy 1: Direct click
                if (connectedNode.isClickable()) {
                    clickSuccess = connectedNode.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    Log.d("AccessibilityService", "Strategy 1 - Direct click, success: " + clickSuccess);
                }
                
                // Strategy 2: Find clickable parent
                if (!clickSuccess) {
                    AccessibilityNodeInfo clickableParent = findClickableParent(connectedNode);
                    if (clickableParent != null) {
                        clickSuccess = clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                        Log.d("AccessibilityService", "Strategy 2 - Clickable parent, success: " + clickSuccess);
                    }
                }
                
                // Strategy 3: Find nearby clickable element
                if (!clickSuccess) {
                    AccessibilityNodeInfo nearbyClickable = findNearbyClickable(connectedNode);
                    if (nearbyClickable != null) {
                        clickSuccess = nearbyClickable.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                        Log.d("AccessibilityService", "Strategy 3 - Nearby clickable, success: " + clickSuccess);
                    }
                }
                
                // Strategy 4: Try to find and click any element containing "Coding School"
                if (!clickSuccess) {
                    List<AccessibilityNodeInfo> codingSchoolNodes = rootNode.findAccessibilityNodeInfosByText("Coding School");
                    for (AccessibilityNodeInfo node : codingSchoolNodes) {
                        if (node.isClickable()) {
                            clickSuccess = node.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                            Log.d("AccessibilityService", "Strategy 4 - Direct Coding School click, success: " + clickSuccess);
                            break;
                        } else {
                            AccessibilityNodeInfo clickableParent = findClickableParent(node);
                            if (clickableParent != null) {
                                clickSuccess = clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                                Log.d("AccessibilityService", "Strategy 4 - Coding School parent click, success: " + clickSuccess);
                                break;
                            }
                        }
                    }
                }
                
                if (clickSuccess) {
                    Log.d("AccessibilityService", "Successfully clicked on connected network");
                } else {
                    Log.d("AccessibilityService", "Failed to click on connected network with all strategies");
                }
                return;
            }

            // If no connected network found, try to find any Wi-Fi network
            AccessibilityNodeInfo wifiNode = findAnyWifiNode(rootNode);
            if (wifiNode != null) {
                Log.d("AccessibilityService", "Found Wi-Fi node (not necessarily connected)");
                if (wifiNode.isClickable()) {
                    wifiNode.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                    Log.d("AccessibilityService", "Clicked Wi-Fi node");
                } else {
                    AccessibilityNodeInfo clickableParent = findClickableParent(wifiNode);
                    if (clickableParent != null) {
                        clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                        Log.d("AccessibilityService", "Clicked clickable parent of Wi-Fi node");
                    }
                }
                return;
            }

            Log.d("AccessibilityService", "No Wi-Fi nodes found - trying alternative approach");
            
            // Alternative approach: try to find any clickable element that might be a network
            AccessibilityNodeInfo anyClickable = findAnyClickableNetwork(rootNode);
            if (anyClickable != null) {
                Log.d("AccessibilityService", "Found clickable network element");
                boolean success = anyClickable.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                Log.d("AccessibilityService", "Clicked any clickable network, success: " + success);
            } else {
                // Last resort: try to click on any clickable element in the connected network area
                Log.d("AccessibilityService", "Trying last resort - click any clickable element");
                tryClickAnyClickableElement(rootNode);
            }

        } finally {
            rootNode.recycle();
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
        
        // Try to find by traversing the node tree and looking for connected networks
        return findConnectedWifiByTraversal(rootNode);
    }

    private AccessibilityNodeInfo findClickableParentWithText(AccessibilityNodeInfo node, String text) {
        AccessibilityNodeInfo parent = node.getParent();
        int depth = 0;
        while (parent != null && depth < 5) {
            if (parent.isClickable()) {
                // Check if this parent contains the connected text
                if (parent.getText() != null && parent.getText().toString().contains(text)) {
                    Log.d("AccessibilityService", "Found clickable parent with connected text at depth: " + depth);
                    return parent;
                }
                // Also check content description
                if (parent.getContentDescription() != null && parent.getContentDescription().toString().contains(text)) {
                    Log.d("AccessibilityService", "Found clickable parent with connected description at depth: " + depth);
                    return parent;
                }
            }
            parent = parent.getParent();
            depth++;
        }
        return null;
    }

    private AccessibilityNodeInfo findConnectedWifiByTraversal(AccessibilityNodeInfo rootNode) {
        Log.d("AccessibilityService", "Traversing node tree to find connected Wi-Fi...");
        return traverseNodeTree(rootNode, 0);
    }

    private AccessibilityNodeInfo traverseNodeTree(AccessibilityNodeInfo node, int depth) {
        if (depth > 10) return null; // Prevent infinite recursion
        
        // Check current node
        if (node.getText() != null) {
            String text = node.getText().toString();
            if (text.contains("متصل") || text.contains("Connected")) {
                Log.d("AccessibilityService", "Found connected text in traversal: " + text + " at depth: " + depth);
                if (node.isClickable()) {
                    return node;
                } else {
                    // Find clickable parent
                    AccessibilityNodeInfo clickableParent = findClickableParent(node);
                    if (clickableParent != null) {
                        return clickableParent;
                    }
                }
            }
        }
        
        // Check content description
        if (node.getContentDescription() != null) {
            String desc = node.getContentDescription().toString();
            if (desc.contains("متصل") || desc.contains("Connected")) {
                Log.d("AccessibilityService", "Found connected description in traversal: " + desc + " at depth: " + depth);
                if (node.isClickable()) {
                    return node;
                } else {
                    AccessibilityNodeInfo clickableParent = findClickableParent(node);
                    if (clickableParent != null) {
                        return clickableParent;
                    }
                }
            }
        }
        
        // Traverse children
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                AccessibilityNodeInfo result = traverseNodeTree(child, depth + 1);
                if (result != null) {
                    return result;
                }
            }
        }
        
        return null;
    }

    private AccessibilityNodeInfo findAnyWifiNode(AccessibilityNodeInfo rootNode) {
        // Look for any Wi-Fi network (not necessarily connected)
        String[] wifiTexts = {"Wi-Fi", "واي فاي", "WLAN"};
        
        for (String text : wifiTexts) {
            List<AccessibilityNodeInfo> nodes = rootNode.findAccessibilityNodeInfosByText(text);
            for (AccessibilityNodeInfo node : nodes) {
                if (node.getText() != null && 
                    (node.getText().toString().contains("Wi-Fi") || 
                     node.getText().toString().contains("واي فاي"))) {
                    Log.d("AccessibilityService", "Found Wi-Fi node with text: " + node.getText());
                    return node;
                }
            }
        }
        
        return null;
    }

    // Share button labels only (avoid instruction text)
    private static final String[] SHARE_LABELS = new String[]{
        "مشاركة", "Share", "Share Wi-Fi", "مشاركة Wi-Fi"
    };

    private AccessibilityNodeInfo findShareButton(AccessibilityNodeInfo rootNode) {
        // 1) Search for share button text
        for (String lbl : SHARE_LABELS) {
            List<AccessibilityNodeInfo> hits = rootNode.findAccessibilityNodeInfosByText(lbl);
            if (hits != null) {
                for (AccessibilityNodeInfo n : hits) {
                    AccessibilityNodeInfo clickable = findClickableParent(n);
                    if (clickable != null) {
                        Log.d("A11y", "Found share button with text: " + lbl);
                        return clickable;
                    }
                }
            }
        }
        
        // 2) Search in contentDescription for icons
        List<AccessibilityNodeInfo> all = rootNode.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo n : all) {
            CharSequence cd = n.getContentDescription();
            if (cd != null) {
                String d = cd.toString();
                for (String lbl : SHARE_LABELS) {
                    if (d.contains(lbl)) {
                        AccessibilityNodeInfo clickable = findClickableParent(n);
                        if (clickable != null) {
                            Log.d("A11y", "Found share button with description: " + d);
                            return clickable;
                        }
                    }
                }
            }
        }
        
        return null;
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

    private AccessibilityNodeInfo findAnyClickableNetwork(AccessibilityNodeInfo rootNode) {
        Log.d("AccessibilityService", "Searching for any clickable network element...");
        return traverseForClickableNetwork(rootNode, 0);
    }

    private AccessibilityNodeInfo traverseForClickableNetwork(AccessibilityNodeInfo node, int depth) {
        if (depth > 8) return null; // Prevent deep recursion
        
        // Check if this node is clickable and might be a network
        if (node.isClickable()) {
            String text = node.getText() != null ? node.getText().toString() : "";
            String desc = node.getContentDescription() != null ? node.getContentDescription().toString() : "";
            
            // Look for network-related keywords
            if (text.contains("Wi-Fi") || text.contains("واي فاي") || text.contains("WLAN") ||
                desc.contains("Wi-Fi") || desc.contains("واي فاي") || desc.contains("WLAN") ||
                text.contains("School") || text.contains("Academy") || text.contains("Orange") ||
                text.contains("OJO") || text.contains("DIRECT")) {
                Log.d("AccessibilityService", "Found clickable network element: " + text + " / " + desc);
                return node;
            }
        }
        
        // Traverse children
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                AccessibilityNodeInfo result = traverseForClickableNetwork(child, depth + 1);
                if (result != null) {
                    return result;
                }
            }
        }
        
        return null;
    }

    private AccessibilityNodeInfo findCodingSchoolParent(AccessibilityNodeInfo node) {
        // Look for a parent that contains "Coding School" text
        AccessibilityNodeInfo parent = node.getParent();
        int depth = 0;
        while (parent != null && depth < 8) {
            if (parent.getText() != null && parent.getText().toString().contains("Coding School")) {
                Log.d("AccessibilityService", "Found Coding School in parent at depth: " + depth);
                if (parent.isClickable()) {
                    return parent;
                } else {
                    // Find clickable parent
                    AccessibilityNodeInfo clickableParent = findClickableParent(parent);
                    if (clickableParent != null) {
                        return clickableParent;
                    }
                }
            }
            
            // Also check siblings for "Coding School"
            if (parent.getParent() != null) {
                for (int i = 0; i < parent.getParent().getChildCount(); i++) {
                    AccessibilityNodeInfo sibling = parent.getParent().getChild(i);
                    if (sibling != null && sibling.getText() != null && 
                        sibling.getText().toString().contains("Coding School")) {
                        Log.d("AccessibilityService", "Found Coding School in sibling");
                        if (sibling.isClickable()) {
                            return sibling;
                        } else {
                            AccessibilityNodeInfo clickableParent = findClickableParent(sibling);
                            if (clickableParent != null) {
                                return clickableParent;
                            }
                        }
                    }
                }
            }
            
            parent = parent.getParent();
            depth++;
        }
        return null;
    }

    private void tryClickAnyClickableElement(AccessibilityNodeInfo rootNode) {
        Log.d("AccessibilityService", "Searching for any clickable element to click...");
        
        // Try to find any clickable element that might be a network
        List<AccessibilityNodeInfo> clickableNodes = new ArrayList<>();
        collectClickableNodes(rootNode, clickableNodes, 0);
        
        Log.d("AccessibilityService", "Found " + clickableNodes.size() + " clickable nodes");
        
        // Try to click on clickable elements that might be networks
        for (AccessibilityNodeInfo node : clickableNodes) {
            String text = node.getText() != null ? node.getText().toString() : "";
            String desc = node.getContentDescription() != null ? node.getContentDescription().toString() : "";
            
            // Look for network-related keywords
            if (text.contains("School") || text.contains("Academy") || text.contains("Orange") ||
                text.contains("OJO") || text.contains("DIRECT") || text.contains("متصل") ||
                desc.contains("School") || desc.contains("Academy") || desc.contains("Orange") ||
                desc.contains("OJO") || desc.contains("DIRECT") || desc.contains("متصل")) {
                
                Log.d("AccessibilityService", "Attempting to click network-related element: " + text + " / " + desc);
                boolean success = node.performAction(AccessibilityNodeInfo.ACTION_CLICK);
                Log.d("AccessibilityService", "Click result: " + success);
                
                if (success) {
                    return; // Stop after first successful click
                }
            }
        }
        
        // If no network-related element found, try clicking the first few clickable elements
        Log.d("AccessibilityService", "No network-related elements found, trying first few clickable elements");
        for (int i = 0; i < Math.min(3, clickableNodes.size()); i++) {
            AccessibilityNodeInfo node = clickableNodes.get(i);
            String text = node.getText() != null ? node.getText().toString() : "";
            Log.d("AccessibilityService", "Attempting to click element: " + text);
            boolean success = node.performAction(AccessibilityNodeInfo.ACTION_CLICK);
            Log.d("AccessibilityService", "Click result: " + success);
            
            if (success) {
                return; // Stop after first successful click
            }
        }
    }

    private void collectClickableNodes(AccessibilityNodeInfo node, List<AccessibilityNodeInfo> clickableNodes, int depth) {
        if (depth > 8) return; // Prevent deep recursion
        
        if (node.isClickable()) {
            clickableNodes.add(node);
        }
        
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                collectClickableNodes(child, clickableNodes, depth + 1);
            }
        }
    }

    private void logAllTextContent(AccessibilityNodeInfo node, int depth) {
        if (depth > 5) return; // Prevent deep recursion
        
        if (node.getText() != null && !node.getText().toString().trim().isEmpty()) {
            Log.d("AccessibilityService", "Text at depth " + depth + ": " + node.getText() + 
                  " (clickable: " + node.isClickable() + ", class: " + node.getClassName() + ")");
        }
        
        if (node.getContentDescription() != null && !node.getContentDescription().toString().trim().isEmpty()) {
            Log.d("AccessibilityService", "ContentDesc at depth " + depth + ": " + node.getContentDescription() + 
                  " (clickable: " + node.isClickable() + ", class: " + node.getClassName() + ")");
        }
        
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) {
                logAllTextContent(child, depth + 1);
            }
        }
    }

    private String[] extractNetworkInfo(AccessibilityNodeInfo root) {
        Log.d("A11y", "Extracting network information from accessibility tree");
        
        // Look for network name (SSID) and password in the current screen
        String ssid = null;
        String password = null;
        
        // Common patterns for network information in WiFi settings
        String[] ssidPatterns = {
            "Network name", "اسم الشبكة", "SSID", "Network", "الشبكة"
        };
        
        String[] passwordPatterns = {
            "Password", "كلمة المرور", "Network password", "كلمة مرور الشبكة", "Wi-Fi password"
        };
        
        // Search for SSID
        for (String pattern : ssidPatterns) {
            List<AccessibilityNodeInfo> nodes = root.findAccessibilityNodeInfosByText(pattern);
            for (AccessibilityNodeInfo node : nodes) {
                // Look for nearby text that might contain the actual SSID
                String ssidValue = findNearbyTextValue(node, root);
                if (ssidValue != null && !ssidValue.isEmpty() && !ssidValue.equals(pattern)) {
                    ssid = ssidValue;
                    Log.d("A11y", "Found SSID: " + ssid);
                    break;
                }
            }
            if (ssid != null) break;
        }
        
        // Search for password
        for (String pattern : passwordPatterns) {
            List<AccessibilityNodeInfo> nodes = root.findAccessibilityNodeInfosByText(pattern);
            for (AccessibilityNodeInfo node : nodes) {
                // Look for nearby text that might contain the actual password
                String passwordValue = findNearbyTextValue(node, root);
                if (passwordValue != null && !passwordValue.isEmpty() && !passwordValue.equals(pattern)) {
                    password = passwordValue;
                    Log.d("A11y", "Found password: " + password);
                    break;
                }
            }
            if (password != null) break;
        }
        
        // Alternative approach: look for text that looks like network names
        if (ssid == null) {
            ssid = findNetworkNameFromText(root);
        }
        
        // Alternative approach: look for text that looks like passwords
        if (password == null) {
            password = findPasswordFromText(root);
        }
        
        if (ssid != null && password != null) {
            return new String[]{ssid, password};
        }
        
        Log.d("A11y", "Could not extract complete network info - SSID: " + (ssid != null) + ", Password: " + (password != null));
        return null;
    }
    
    private String findNearbyTextValue(AccessibilityNodeInfo node, AccessibilityNodeInfo root) {
        // Look for text in the same parent or nearby nodes
        AccessibilityNodeInfo parent = node.getParent();
        if (parent != null) {
            // Check siblings
            for (int i = 0; i < parent.getChildCount(); i++) {
                AccessibilityNodeInfo sibling = parent.getChild(i);
                if (sibling != null && sibling.getText() != null) {
                    String text = sibling.getText().toString();
                    if (!text.isEmpty() && !text.equals(node.getText().toString())) {
                        return text;
                    }
                }
            }
            
            // Check parent's text
            if (parent.getText() != null) {
                String parentText = parent.getText().toString();
                if (!parentText.isEmpty() && !parentText.equals(node.getText().toString())) {
                    return parentText;
                }
            }
        }
        
        return null;
    }
    
    private String findNetworkNameFromText(AccessibilityNodeInfo root) {
        // Look for text that might be a network name
        List<AccessibilityNodeInfo> allNodes = root.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getText() != null) {
                String text = node.getText().toString();
                // Look for text that might be a network name (not too long, not too short)
                if (text.length() > 3 && text.length() < 50 && 
                    !text.contains("Password") && !text.contains("كلمة المرور") &&
                    !text.contains("Network") && !text.contains("الشبكة") &&
                    !text.contains("Wi-Fi") && !text.contains("واي فاي")) {
                    Log.d("A11y", "Potential network name found: " + text);
                    return text;
                }
            }
        }
        return null;
    }
    
    private String findPasswordFromText(AccessibilityNodeInfo root) {
        Log.d("A11y", "Searching for password in accessibility tree...");
        
        // First, try to find password by looking for specific patterns
        String[] passwordLabels = {
            "Password", "كلمة المرور", "Network password", "كلمة مرور الشبكة", 
            "Wi-Fi password", "كلمة مرور الواي فاي", "Security key", "مفتاح الأمان"
        };
        
        for (String label : passwordLabels) {
            List<AccessibilityNodeInfo> nodes = root.findAccessibilityNodeInfosByText(label);
            for (AccessibilityNodeInfo node : nodes) {
                // Look for nearby text that might contain the actual password
                String password = findNearbyPassword(node, root);
                if (password != null && !password.isEmpty()) {
                    Log.d("A11y", "Found password near label '" + label + "': " + password);
                    return password;
                }
            }
        }
        
        // Second approach: Look for text that looks like passwords
        List<AccessibilityNodeInfo> allNodes = root.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getText() != null) {
                String text = node.getText().toString();
                if (isLikelyPassword(text)) {
                    Log.d("A11y", "Potential password found: " + text);
                    return text;
                }
            }
        }
        
        // Third approach: Check content descriptions
        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getContentDescription() != null) {
                String text = node.getContentDescription().toString();
                if (isLikelyPassword(text)) {
                    Log.d("A11y", "Potential password found in content description: " + text);
                    return text;
                }
            }
        }
        
        // Fourth approach: Look for EditText fields that might contain password
        return findPasswordInEditTexts(root);
    }
    
    private String findNearbyPassword(AccessibilityNodeInfo node, AccessibilityNodeInfo root) {
        // Look in siblings
        AccessibilityNodeInfo parent = node.getParent();
        if (parent != null) {
            for (int i = 0; i < parent.getChildCount(); i++) {
                AccessibilityNodeInfo sibling = parent.getChild(i);
                if (sibling != null && sibling.getText() != null) {
                    String text = sibling.getText().toString();
                    if (isLikelyPassword(text)) {
                        return text;
                    }
                }
            }
        }
        
        // Look in parent's text
        if (parent != null && parent.getText() != null) {
            String text = parent.getText().toString();
            if (isLikelyPassword(text)) {
                return text;
            }
        }
        
        return null;
    }
    
    private boolean isLikelyPassword(String text) {
        if (text == null || text.isEmpty()) return false;
        
        // Check length (reasonable password length)
        if (text.length() < 4 || text.length() > 64) return false;
        
        // Exclude common UI text
        String[] excludePatterns = {
            "Password", "كلمة المرور", "Network", "الشبكة", "Wi-Fi", "واي فاي",
            "QR", "رمز", "Scan", "قراءة", "Share", "مشاركة", "Connect", "اتصال",
            "Settings", "إعدادات", "Security", "أمان", "Key", "مفتاح"
        };
        
        for (String pattern : excludePatterns) {
            if (text.contains(pattern)) return false;
        }
        
        // Check if it looks like a password (contains letters/numbers/symbols)
        return text.matches(".*[a-zA-Z0-9].*");
    }
    
    private String findPasswordInEditTexts(AccessibilityNodeInfo root) {
        // Look for EditText fields that might contain password
        // We'll search through all nodes and check their class names
        List<AccessibilityNodeInfo> allNodes = root.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getClassName() != null && 
                node.getClassName().toString().contains("EditText") &&
                node.getText() != null) {
                String text = node.getText().toString();
                if (isLikelyPassword(text)) {
                    Log.d("A11y", "Found password in EditText: " + text);
                    return text;
                }
            }
        }
        return null;
    }

    @Override
    public void onInterrupt() {}

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
