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
    private boolean isNavigating = false;

    public static AutoOpenAccessibilityService getInstance() {
        return instance;
    }

    public static void setConnectivityChannel(MethodChannel channel) {
        connectivityChannel = channel;
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        String pkg = event.getPackageName() + "";
        Log.d("A11y", "event pkg=" + pkg + " type=" + event.getEventType());
        
        // Only proceed for Settings app
        if (!pkg.contains("com.android.settings")) {
            return;
        }
        
        if (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            handleWindowStateChanged(event);
        } else if (event.getEventType() == AccessibilityEvent.TYPE_VIEW_CLICKED) {
            handleViewClicked(event);
        } else if (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            handleWindowContentChanged(event);
        }
    }

    private void handleWindowStateChanged(AccessibilityEvent event) {
        Log.d("AccessibilityService", "Window state changed in Settings");
        
        if (!isNavigating) {
            isNavigating = true;
            handler.postDelayed(() -> {
                handleWifiSettingsNavigation();
                isNavigating = false;
            }, 500);
        }
    }

    private void handleViewClicked(AccessibilityEvent event) {
        // Handle any view clicks if needed
    }

    private void handleWindowContentChanged(AccessibilityEvent event) {
        Log.d("AccessibilityService", "Window content changed in Settings");
        
        if (!isNavigating) {
            isNavigating = true;
            handler.postDelayed(() -> {
                handleWifiSettingsNavigation();
                isNavigating = false;
            }, 250);
        }
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
        Log.d("AccessibilityService", "Searching for connected Wi-Fi node...");
        
        // First, try to find by the "متصل" text directly
        String[] connectedTexts = {"متصل", "Connected", "Connected, secured", "متصل، محمي"};
        
        for (String text : connectedTexts) {
            List<AccessibilityNodeInfo> nodes = rootNode.findAccessibilityNodeInfosByText(text);
            Log.d("AccessibilityService", "Found " + nodes.size() + " nodes with text: " + text);
            
            for (AccessibilityNodeInfo node : nodes) {
                if (node.getText() != null && 
                    (node.getText().toString().contains("متصل") || 
                     node.getText().toString().contains("Connected"))) {
                    
                    // Skip section headers
                    if (isSectionHeader(node.getText())) {
                        Log.d("AccessibilityService", "Skipping section header: " + node.getText());
                        continue;
                    }
                    
                    Log.d("AccessibilityService", "Found connected node with text: " + node.getText());
                    
                    // Check if this is near "Coding School" text
                    AccessibilityNodeInfo codingSchoolParent = findCodingSchoolParent(node);
                    if (codingSchoolParent != null) {
                        Log.d("AccessibilityService", "Found Coding School parent node");
                        return codingSchoolParent;
                    }
                    
                    // Try to find a clickable parent that contains this text
                    AccessibilityNodeInfo clickableParent = findClickableParentWithText(node, text);
                    if (clickableParent != null) {
                        return clickableParent;
                    }
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

    private AccessibilityNodeInfo findShareButton(AccessibilityNodeInfo rootNode) {
        String[] shareTexts = {"مشاركة", "Share", "Share Wi-Fi", "QR", "رمز QR", "رمز الاستجابة السريعة", "Share network"};
        
        for (String text : shareTexts) {
            List<AccessibilityNodeInfo> nodes = rootNode.findAccessibilityNodeInfosByText(text);
            for (AccessibilityNodeInfo node : nodes) {
                if (node.getText() != null && node.getText().toString().contains(text)) {
                    Log.d("AccessibilityService", "Found share button with text: " + node.getText());
                    return node;
                }
            }
        }
        
        // Also try by content description
        List<AccessibilityNodeInfo> allNodes = rootNode.findAccessibilityNodeInfosByText("");
        for (AccessibilityNodeInfo node : allNodes) {
            if (node.getContentDescription() != null) {
                String desc = node.getContentDescription().toString();
                if (desc.contains("مشاركة") || desc.contains("Share") || desc.contains("QR")) {
                    Log.d("AccessibilityService", "Found share button with description: " + desc);
                    return node;
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

    @Override
    public void onInterrupt() {}

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
        Log.d("AccessibilityService", "Service connected");
    }

    public static void launchApp(AutoOpenAccessibilityService service) {
        if (service != null) {
            Intent intent = new Intent(service, MainActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        }
    }
}
