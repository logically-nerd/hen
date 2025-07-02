import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager {
  static const int MAX_CONNECTIONS = 3;
  static final List<BluetoothDevice> _connectedDevices = [];
  static StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  static StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Check if Bluetooth adapter exists on the device
  static Future<bool> checkBluetoothSupport() async {
    debugPrint("🔍 Checking for Bluetooth support...");
    
    try {
      // Check if Bluetooth is supported
      bool isSupported = await FlutterBluePlus.isSupported;
      if (isSupported) {
        debugPrint("✅ Bluetooth is supported on this device");
        return true;
      } else {
        debugPrint("❌ Bluetooth is not supported on this device");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error checking Bluetooth support: $e");
      return false;
    }
  }

  /// Confirm Bluetooth adapter exists and get current state
  static Future<bool> confirmBluetoothExists() async {
    debugPrint("🔍 Confirming Bluetooth adapter exists...");
    
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      debugPrint("✅ Bluetooth adapter confirmed. Current state: ${state.name}");
      return true;
    } catch (e) {
      debugPrint("❌ Bluetooth adapter not found: $e");
      return false;
    }
  }

  /// Request Bluetooth permissions
  static Future<bool> requestBluetoothPermissions() async {
    debugPrint("🔐 Requesting Bluetooth permissions...");
    
    try {
      if (Platform.isAndroid) {
        // Request permissions one by one for better debugging
        Map<Permission, PermissionStatus> results = {};
        
        // Check Android version and request appropriate permissions
        int androidVersion = Platform.version.contains('API') 
            ? int.parse(Platform.version.split('API ')[1].split(')')[0])
            : 31; // Default to newer version
        
        debugPrint("Android API level: $androidVersion");
        
        if (androidVersion >= 31) {
          // Android 12+ permissions
          debugPrint("Requesting Android 12+ Bluetooth permissions...");
          results[Permission.bluetoothScan] = await Permission.bluetoothScan.request();
          results[Permission.bluetoothConnect] = await Permission.bluetoothConnect.request();
          results[Permission.bluetoothAdvertise] = await Permission.bluetoothAdvertise.request();
        } else {
          // Legacy permissions
          debugPrint("Requesting legacy Bluetooth permissions...");
          results[Permission.bluetooth] = await Permission.bluetooth.request();
        }
        
        // Location permission (required for Bluetooth scanning)
        debugPrint("Requesting location permission...");
        results[Permission.locationWhenInUse] = await Permission.locationWhenInUse.request();
        
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
          debugPrint("✅ All Bluetooth permissions granted");
          return true;
        } else {
          debugPrint("❌ Some Bluetooth permissions denied");
          return false;
        }
      } else if (Platform.isIOS) {
        // iOS permissions
        debugPrint("Requesting iOS Bluetooth permissions...");
        PermissionStatus bluetoothStatus = await Permission.bluetooth.request();
        
        if (bluetoothStatus == PermissionStatus.granted) {
          debugPrint("✅ iOS Bluetooth permission granted");
          return true;
        } else {
          debugPrint("❌ iOS Bluetooth permission denied: $bluetoothStatus");
          return false;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint("❌ Error requesting Bluetooth permissions: $e");
      return false;
    }
  }

  /// Check if Bluetooth permissions are granted
  static Future<bool> checkBluetoothPermissions() async {
    debugPrint("🔍 Checking Bluetooth permissions...");
    
    try {
      if (Platform.isAndroid) {
        // Check Android version
        int androidVersion = Platform.version.contains('API') 
            ? int.parse(Platform.version.split('API ')[1].split(')')[0])
            : 31;
        
        bool bluetoothGranted = true;
        bool locationGranted = await Permission.locationWhenInUse.isGranted;
        
        if (androidVersion >= 31) {
          // Android 12+ permissions
          bool scanGranted = await Permission.bluetoothScan.isGranted;
          bool connectGranted = await Permission.bluetoothConnect.isGranted;
          bluetoothGranted = scanGranted && connectGranted;
          
          debugPrint("Bluetooth scan granted: $scanGranted");
          debugPrint("Bluetooth connect granted: $connectGranted");
        } else {
          // Legacy permissions
          bluetoothGranted = await Permission.bluetooth.isGranted;
          debugPrint("Legacy Bluetooth granted: $bluetoothGranted");
        }
        
        debugPrint("Location granted: $locationGranted");
        
        bool allGranted = bluetoothGranted && locationGranted;
        
        if (allGranted) {
          debugPrint("✅ All required Bluetooth permissions are granted");
        } else {
          debugPrint("❌ Missing Bluetooth permissions");
        }
        
        return allGranted;
      } else if (Platform.isIOS) {
        bool bluetoothGranted = await Permission.bluetooth.isGranted;
        debugPrint("iOS Bluetooth granted: $bluetoothGranted");
        return bluetoothGranted;
      }
      
      return false;
    } catch (e) {
      debugPrint("❌ Error checking Bluetooth permissions: $e");
      return false;
    }
  }

  /// Turn on Bluetooth
  static Future<bool> turnOnBluetooth() async {
    debugPrint("🔄 Attempting to turn on Bluetooth...");
    
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      
      if (state == BluetoothAdapterState.on) {
        debugPrint("✅ Bluetooth is already turned on");
        return true;
      }

      // Request to turn on Bluetooth
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
        debugPrint("🔄 Bluetooth turn on requested...");
        
        // Wait for Bluetooth to turn on (with timeout)
        await for (BluetoothAdapterState state in FlutterBluePlus.adapterState) {
          if (state == BluetoothAdapterState.on) {
            debugPrint("✅ Bluetooth turned on successfully");
            return true;
          }
        }
      } else {
        debugPrint("❌ Cannot programmatically turn on Bluetooth on iOS");
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint("❌ Error turning on Bluetooth: $e");
      return false;
    }
  }

  /// Check if Bluetooth is turned on
  static Future<bool> isBluetoothOn() async {
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      bool isOn = state == BluetoothAdapterState.on;
      debugPrint(isOn ? "✅ Bluetooth is ON" : "❌ Bluetooth is OFF");
      return isOn;
    } catch (e) {
      debugPrint("❌ Error checking Bluetooth state: $e");
      return false;
    }
  }

  /// Start scanning for Bluetooth devices
  static Future<bool> startScanning({Duration timeout = const Duration(seconds: 10)}) async {
    debugPrint("🔍 Starting Bluetooth device scan...");
    
    try {
      // Check if already scanning
      if (FlutterBluePlus.isScanningNow) {
        debugPrint("⚠️ Already scanning for devices");
        return true;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);
      debugPrint("✅ Bluetooth scan started (timeout: ${timeout.inSeconds}s)");
      return true;
    } catch (e) {
      debugPrint("❌ Error starting Bluetooth scan: $e");
      return false;
    }
  }

  /// Stop scanning for Bluetooth devices
  static Future<void> stopScanning() async {
    debugPrint("🛑 Stopping Bluetooth device scan...");
    
    try {
      await FlutterBluePlus.stopScan();
      debugPrint("✅ Bluetooth scan stopped");
    } catch (e) {
      debugPrint("❌ Error stopping Bluetooth scan: $e");
    }
  }

  /// Get scan results stream
  static Stream<List<ScanResult>> getScanResults() {
    debugPrint("📡 Getting scan results stream...");
    return FlutterBluePlus.scanResults;
  }

  /// Connect to a specific device
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    debugPrint("🔗 Attempting to connect to device: ${device.platformName}");
    
    try {
      // Check if we've reached max connections
      if (_connectedDevices.length >= MAX_CONNECTIONS) {
        debugPrint("❌ Maximum connections ($MAX_CONNECTIONS) reached");
        return false;
      }

      // Check if already connected
      if (_connectedDevices.contains(device)) {
        debugPrint("⚠️ Device already connected: ${device.platformName}");
        return true;
      }

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevices.add(device);
      debugPrint("✅ Connected to device: ${device.platformName}");
      debugPrint("📊 Total connected devices: ${_connectedDevices.length}/$MAX_CONNECTIONS");
      return true;
    } catch (e) {
      debugPrint("❌ Error connecting to device ${device.platformName}: $e");
      return false;
    }
  }

  /// Connect to multiple devices (up to MAX_CONNECTIONS)
  static Future<List<BluetoothDevice>> connectToMultipleDevices(
    List<BluetoothDevice> devices
  ) async {
    debugPrint("🔗 Attempting to connect to ${devices.length} devices...");
    
    List<BluetoothDevice> successfulConnections = [];
    
    for (BluetoothDevice device in devices) {
      if (_connectedDevices.length >= MAX_CONNECTIONS) {
        debugPrint("⚠️ Maximum connections reached, stopping...");
        break;
      }
      
      bool connected = await connectToDevice(device);
      if (connected) {
        successfulConnections.add(device);
      }
    }
    
    debugPrint("✅ Successfully connected to ${successfulConnections.length} devices");
    return successfulConnections;
  }

  /// Disconnect from a specific device
  static Future<bool> disconnectFromDevice(BluetoothDevice device) async {
    debugPrint("🔌 Disconnecting from device: ${device.platformName}");
    
    try {
      await device.disconnect();
      _connectedDevices.remove(device);
      debugPrint("✅ Disconnected from device: ${device.platformName}");
      debugPrint("📊 Total connected devices: ${_connectedDevices.length}/$MAX_CONNECTIONS");
      return true;
    } catch (e) {
      debugPrint("❌ Error disconnecting from device ${device.platformName}: $e");
      return false;
    }
  }

  /// Disconnect from all devices
  static Future<void> disconnectFromAllDevices() async {
    debugPrint("🔌 Disconnecting from all devices...");
    
    List<BluetoothDevice> devicesToDisconnect = List.from(_connectedDevices);
    
    for (BluetoothDevice device in devicesToDisconnect) {
      await disconnectFromDevice(device);
    }
    
    debugPrint("✅ Disconnected from all devices");
  }

  /// Get list of connected devices
  static List<BluetoothDevice> getConnectedDevices() {
    return List.unmodifiable(_connectedDevices);
  }

  /// Initialize Bluetooth (complete setup flow)
  static Future<bool> initializeBluetooth() async {
    debugPrint("🚀 Initializing Bluetooth...");
    
    // Step 1: Check Bluetooth support
    if (!await checkBluetoothSupport()) {
      return false;
    }

    // Step 2: Confirm Bluetooth exists
    if (!await confirmBluetoothExists()) {
      return false;
    }

    // Step 3: Check permissions
    bool hasPermissions = await checkBluetoothPermissions();
    if (!hasPermissions) {
      // Step 4: Request permissions if not granted
      if (!await requestBluetoothPermissions()) {
        return false;
      }
    }

    // Step 5: Check if Bluetooth is on
    if (!await isBluetoothOn()) {
      // Step 6: Turn on Bluetooth if off
      if (!await turnOnBluetooth()) {
        debugPrint("❌ Please turn on Bluetooth manually");
        return false;
      }
    }

    debugPrint("✅ Bluetooth initialization completed successfully");
    return true;
  }

  /// Scan and connect to devices automatically
  static Future<List<BluetoothDevice>> scanAndConnect({
    Duration scanTimeout = const Duration(seconds: 10),
    bool connectToAll = false,
  }) async {
    debugPrint("🔍 Starting scan and connect process...");
    
    try {
      // Start scanning
      if (!await startScanning(timeout: scanTimeout)) {
        return [];
      }

      // Wait for scan to complete
      await Future.delayed(scanTimeout);

      // Get scan results
      List<ScanResult> results = await FlutterBluePlus.scanResults.first;
      debugPrint("📱 Found ${results.length} devices");

      // Filter connectable devices
      List<BluetoothDevice> devices = results
          .where((result) => result.device.platformName.isNotEmpty)
          .map((result) => result.device)
          .toList();

      if (devices.isEmpty) {
        debugPrint("❌ No connectable devices found");
        return [];
      }

      // Connect to devices
      List<BluetoothDevice> devicesToConnect = connectToAll 
          ? devices 
          : devices.take(MAX_CONNECTIONS).toList();

      return await connectToMultipleDevices(devicesToConnect);
    } catch (e) {
      debugPrint("❌ Error in scan and connect process: $e");
      return [];
    } finally {
      await stopScanning();
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    debugPrint("🧹 Disposing Bluetooth resources...");
    
    await stopScanning();
    await disconnectFromAllDevices();
    await _adapterStateSubscription?.cancel();
    await _scanSubscription?.cancel();
    
    debugPrint("✅ Bluetooth resources disposed");
  }
}