import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEN - Emergency Network',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const EmergencyHomePage(),
    );
  }
}

class EmergencyHomePage extends StatefulWidget {
  const EmergencyHomePage({super.key});

  @override
  State<EmergencyHomePage> createState() => _EmergencyHomePageState();
}

class _EmergencyHomePageState extends State<EmergencyHomePage>
    with TickerProviderStateMixin {
  bool _isInitializing = false;
  List<String> _progressMessages = [];
  bool _initializationComplete = false;
  String? _errorMessage;
  
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for connecting state
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for button press
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleSOSPress() async {
    // Button press animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    setState(() {
      _isInitializing = true;
      _progressMessages.clear();
      _initializationComplete = false;
      _errorMessage = null;
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    try {
      // Stop pulse animation
      _pulseController.stop();
      _pulseController.reset();
      
      setState(() {
        _initializationComplete = true;
        _isInitializing = false;
        _progressMessages.add('✅ Emergency network ready!');
      });

      // After successful initialization, you can call other functions here
      // _startDeviceDiscovery();
      // _createMeshNetwork();
      
    } catch (e) {
      // Stop pulse animation on error
      _pulseController.stop();
      _pulseController.reset();
      
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
        _progressMessages.add('❌ Initialization failed: $e');
      });
    }
  }

  void _addProgressMessage(String message) {
    setState(() {
      _progressMessages.add(message);
    });
  }

  void _resetInterface() {
    setState(() {
      _progressMessages.clear();
      _initializationComplete = false;
      _errorMessage = null;
      _isInitializing = false;
    });
    
    _pulseController.stop();
    _pulseController.reset();
  }

  Color _getButtonColor() {
    if (_isInitializing) return Colors.grey[600]!;
    if (_initializationComplete) return Colors.green[600]!;
    return Colors.red;
  }

  String _getButtonText() {
    if (_isInitializing) return 'CONNECTING';
    if (_initializationComplete) return 'READY';
    return 'SOS';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              const Text(
                'HEN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help! Emergency Network',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              
              const Spacer(),
              
              // SOS Button with animations
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getButtonColor(),
                            boxShadow: [
                              BoxShadow(
                                color: _getButtonColor().withOpacity(0.4),
                                blurRadius: _isInitializing ? 30 * _pulseAnimation.value : 20,
                                spreadRadius: _isInitializing ? 10 * _pulseAnimation.value : 5,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(110),
                              onTap: _isInitializing ? null : _handleSOSPress,
                              child: Center(
                                child: _isInitializing
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _getButtonText(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _getButtonText(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Status text
              Text(
                _isInitializing 
                    ? 'Initializing Emergency Network...'
                    : _initializationComplete
                        ? 'Emergency Network Ready'
                        : _errorMessage != null
                            ? 'Initialization Failed'
                            : 'Tap SOS to Initialize Emergency Network',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Progress Messages
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _progressMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'Progress will be shown here',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _progressMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _progressMessages[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
