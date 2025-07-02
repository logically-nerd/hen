import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WiFiManager {
  static const int MAX_CONNECTIONS = 5;
  static final List<WiFiAccessPoint> _availableNetworks = [];
  static WiFiAccessPoint? _connectedNetwork;
  static StreamSubscription<List<WiFiAccessPoint>>? _scanSubscription;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Check if WiFi is supported on the device
  static Future<bool> checkWiFiSupport() async {
    debugPrint("🔍 Checking for WiFi support...");
    
    try {
      // First check connectivity to see if WiFi exists
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint("Connectivity check result: $connectivityResult");
      
      // Check if device can scan WiFi (this is the main test)
      try {
        CanStartScan canStartScan = await WiFiScan.instance.canStartScan();
        debugPrint("Can start WiFi scan: $canStartScan");
        
        if (canStartScan == CanStartScan.yes) {
          debugPrint("✅ WiFi is supported on this device");
          return true;
        }
      } catch (scanError) {
        debugPrint("WiFi scan check error: $scanError");
      }
      
      // Alternative check - try to get network info
      try {
        final info = NetworkInfo();
        String? wifiName = await info.getWifiName();
        debugPrint("WiFi name check: $wifiName");
        
        // If we can get WiFi info or connectivity shows WiFi, assume supported
        if (wifiName != null || connectivityResult.contains(ConnectivityResult.wifi)) {
          debugPrint("✅ WiFi support confirmed via network info");
          return true;
        }
      } catch (infoError) {
        debugPrint("Network info error: $infoError");
      }
      
      // Final fallback - assume WiFi is supported on mobile devices
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint("✅ WiFi assumed supported on mobile platform");
        return true;
      }
      
      debugPrint("❌ WiFi support could not be confirmed");
      return false;
    } catch (e) {
      debugPrint("❌ Error checking WiFi support: $e");
      // Fallback - assume supported on mobile
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint("✅ WiFi assumed supported (fallback)");
        return true;
      }
      return false;
    }
  }

  /// Confirm WiFi adapter exists and get current state
  static Future<bool> confirmWiFiExists() async {
    debugPrint("🔍 Confirming WiFi adapter exists...");
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      debugPrint("✅ WiFi adapter confirmed. Current connectivity: $connectivityResult");
      return true;
    } catch (e) {
      debugPrint("❌ WiFi adapter not found: $e");
      return false;
    }
  }

  /// Request WiFi permissions
  static Future<bool> requestWiFiPermissions() async {
    debugPrint("🔐 Requesting WiFi permissions...");
    
    try {
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> results = {};
        
        // Location permission (required for WiFi scanning on Android)
        debugPrint("Requesting location permission for WiFi scanning...");
        results[Permission.locationWhenInUse] = await Permission.locationWhenInUse.request();
        results[Permission.location] = await Permission.location.request();
        
        // Check results
        for (var entry in results.entries) {
          debugPrint("${entry.key}: ${entry.value}");
          if (entry.value == PermissionStatus.permanentlyDenied) {
            debugPrint("❌ ${entry.key} permanently denied. Opening app settings...");
            await openAppSettings();
            return false;
          }
        }
        
        bool allGranted = results.values.every(
          (status) => status == PermissionStatus.granted
        );
        
        if (allGranted) {
          debugPrint("✅ All WiFi permissions granted");
          return true;
        } else {
          debugPrint("❌ Some WiFi permissions denied");
          return false;
        }
      } else if (Platform.isIOS) {
        debugPrint("✅ iOS WiFi permissions are handled automatically");
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint("❌ Error requesting WiFi permissions: $e");
      return false;
    }
  }

  /// Check if WiFi permissions are granted
  static Future<bool> checkWiFiPermissions() async {
    debugPrint("🔍 Checking WiFi permissions...");
    
    try {
      if (Platform.isAndroid) {
        bool locationGranted = await Permission.locationWhenInUse.isGranted;
        bool fineLocationGranted = await Permission.location.isGranted;
        
        debugPrint("Location granted: $locationGranted");
        debugPrint("Fine location granted: $fineLocationGranted");
        
        bool allGranted = locationGranted && fineLocationGranted;
        
        if (allGranted) {
          debugPrint("✅ All required WiFi permissions are granted");
        } else {
          debugPrint("❌ Missing WiFi permissions");
        }
        
        return allGranted;
      } else if (Platform.isIOS) {
        debugPrint("✅ iOS WiFi permissions are automatically handled");
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint("❌ Error checking WiFi permissions: $e");
      return false;
    }
  }

  /// Turn on WiFi
  static Future<bool> turnOnWiFi() async {
    debugPrint("🔄 Attempting to turn on WiFi...");
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        debugPrint("✅ WiFi is already turned on");
        return true;
      }

      debugPrint("❌ Cannot programmatically turn on WiFi. Please enable WiFi manually.");
      return false;
    } catch (e) {
      debugPrint("❌ Error checking WiFi state: $e");
      return false;
    }
  }

  /// Check if WiFi is turned on
  static Future<bool> isWiFiOn() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOn = connectivityResult.contains(ConnectivityResult.wifi);
      debugPrint(isOn ? "✅ WiFi is ON" : "❌ WiFi is OFF");
      return isOn;
    } catch (e) {
      debugPrint("❌ Error checking WiFi state: $e");
      return false;
    }
  }

  /// Start scanning for WiFi networks
  static Future<bool> startScanning() async {
    debugPrint("🔍 Starting WiFi network scan...");
    
    try {
      // Check if we can start scan
      CanStartScan canStartScan = await WiFiScan.instance.canStartScan();
      debugPrint("Can start scan result: $canStartScan");
      
      if (canStartScan != CanStartScan.yes) {
        debugPrint("❌ Cannot start WiFi scan - reason: $canStartScan");
        return false;
      }

      // Start scanning
      await WiFiScan.instance.startScan();
      debugPrint("✅ WiFi scan started");
      return true;
    } catch (e) {
      debugPrint("❌ Error starting WiFi scan: $e");
      return false;
    }
  }

  /// Get WiFi scan results
  static Future<List<WiFiAccessPoint>> getScanResults() async {
    debugPrint("📡 Getting WiFi scan results...");
    
    try {
      // Check if we can get scan results
      CanGetScannedResults canGetResults = await WiFiScan.instance.canGetScannedResults();
      debugPrint("Can get results: $canGetResults");
      
      if (canGetResults != CanGetScannedResults.yes) {
        debugPrint("❌ Cannot get WiFi scan results - reason: $canGetResults");
        return [];
      }

      // Get scan results
      List<WiFiAccessPoint> results = await WiFiScan.instance.getScannedResults();
      _availableNetworks.clear();
      _availableNetworks.addAll(results);
      
      debugPrint("📱 Found ${results.length} WiFi networks");
      for (var network in results) {
        debugPrint("  📶 ${network.ssid} (${network.level}dBm)");
      }
      
      return results;
    } catch (e) {
      debugPrint("❌ Error getting WiFi scan results: $e");
      return [];
    }
  }

  /// Get current WiFi info
  static Future<Map<String, String?>> getCurrentWiFiInfo() async {
    debugPrint("🔍 Getting current WiFi info...");
    
    try {
      final info = NetworkInfo();
      
      String? wifiName = await info.getWifiName();
      String? wifiBSSID = await info.getWifiBSSID();
      String? wifiIP = await info.getWifiIP();
      String? wifiGatewayIP = await info.getWifiGatewayIP();
      String? wifiSubmask = await info.getWifiSubmask();
      
      Map<String, String?> wifiInfo = {
        'name': wifiName,
        'bssid': wifiBSSID,
        'ip': wifiIP,
        'gateway': wifiGatewayIP,
        'submask': wifiSubmask,
      };
      
      debugPrint("📱 Current WiFi: ${wifiInfo['name']}");
      debugPrint("📶 IP Address: ${wifiInfo['ip']}");
      
      return wifiInfo;
    } catch (e) {
      debugPrint("❌ Error getting WiFi info: $e");
      return {};
    }
  }

  /// Scan for available networks
  static Future<List<WiFiAccessPoint>> scanForNetworks({
    Duration waitDuration = const Duration(seconds: 5),
  }) async {
    debugPrint("🔍 Starting WiFi network scan process...");
    
    try {
      // Start scanning
      if (!await startScanning()) {
        debugPrint("⚠️ Cannot scan, but will try to get existing results");
        // Try to get cached results even if scan fails
        return await getScanResults();
      }

      // Wait for scan to complete
      await Future.delayed(waitDuration);

      // Get scan results
      List<WiFiAccessPoint> results = await getScanResults();
      debugPrint("📱 Scan completed. Found ${results.length} networks");

      return results;
    } catch (e) {
      debugPrint("❌ Error in WiFi scan process: $e");
      return [];
    }
  }

  /// Initialize WiFi (complete setup flow)
  static Future<bool> initializeWiFi() async {
    debugPrint("🚀 Initializing WiFi...");
    
    // Step 1: Check WiFi support
    if (!await checkWiFiSupport()) {
      return false;
    }

    // Step 2: Confirm WiFi exists
    if (!await confirmWiFiExists()) {
      return false;
    }

    // Step 3: Check permissions
    bool hasPermissions = await checkWiFiPermissions();
    if (!hasPermissions) {
      // Step 4: Request permissions if not granted
      if (!await requestWiFiPermissions()) {
        return false;
      }
    }

    // Step 5: Check if WiFi is on
    if (!await isWiFiOn()) {
      debugPrint("❌ Please turn on WiFi manually in device settings");
      return false;
    }

    debugPrint("✅ WiFi initialization completed successfully");
    return true;
  }

  /// Dispose resources
  static Future<void> dispose() async {
    debugPrint("🧹 Disposing WiFi resources...");
    
    await _connectivitySubscription?.cancel();
    await _scanSubscription?.cancel();
    _availableNetworks.clear();
    _connectedNetwork = null;
    
    debugPrint("✅ WiFi resources disposed");
  }

  /// Get available networks
  static List<WiFiAccessPoint> getAvailableNetworks() {
    return List.unmodifiable(_availableNetworks);
  }

  /// Get networks by signal strength
  static List<WiFiAccessPoint> getNetworksBySignalStrength() {
    List<WiFiAccessPoint> networks = List.from(_availableNetworks);
    networks.sort((a, b) => b.level.compareTo(a.level)); // Sort by signal strength (descending)
    return networks;
  }

  /// Filter open networks (no password required)
  static List<WiFiAccessPoint> getOpenNetworks() {
    return _availableNetworks
        .where((network) => network.capabilities.isEmpty || 
               !network.capabilities.contains('WPA') && 
               !network.capabilities.contains('WEP'))
        .toList();
  }
}