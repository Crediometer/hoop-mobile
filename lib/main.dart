import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/login_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step5_primary_account_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';
import 'package:hoop/screens/groups/chat_detail_screen.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/screens/groups/group_detail_public_screen.dart';
import 'package:hoop/screens/groups/group_detail_screen.dart';
import 'package:hoop/screens/groups/group_invite.dart';
import 'package:hoop/screens/notifications/notification_screen.dart';
import 'package:hoop/screens/notifications/notification_setting.dart';
import 'package:hoop/screens/onboarding/onboarding_screen.dart';
import 'package:hoop/screens/onboarding/splash_screen.dart';
import 'package:hoop/screens/settings/primary_account_info.dart';
import 'package:hoop/screens/settings/profile_setting.dart';
import 'package:hoop/screens/settings/security_setting.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/states/group_state.dart';
import 'package:hoop/states/onesignal_state.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider<GroupCommunityProvider>(
          create: (_) => GroupCommunityProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider<OneSignalService>(
          create: (_) => OneSignalService.instance,
        ),
        ChangeNotifierProvider<NotificationWebSocketHandler>(
          create: (_) => NotificationWebSocketHandler(
            socketService: BaseWebSocketService(namespace: '/notifications'),
          ),
          lazy: true,
        ),
        ChangeNotifierProvider<ChatWebSocketHandler>(
          create: (_) => ChatWebSocketHandler().instance,
          lazy: true,
        ),
        ChangeNotifierProvider<WebRTCManager>(
          create: (_) => WebRTCManager(),
          lazy: true,
        ),
      ],
      child: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // init async once
    Future.microtask(() => context.read<AuthProvider>().init());

    final isDark = context.watch<AuthProvider>().isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hoop App',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFF97316),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: isDark == 'system'
          ? ThemeMode.system
          : isDark == 'light'
          ? ThemeMode.light
          : ThemeMode.dark, //
      // Use onGenerateRoute instead of home/routes
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        return _generateRoute(settings);
      },
    );
  }
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  Map<String, dynamic> getArguments() {
    return (settings.arguments as Map<String, dynamic>?) ?? {};
  }

  print("settings.name??? ${settings.name}");
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (_) => const AuthWrapper(),
        settings: settings,
      );

    case '/login':
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );

    case '/settings/primary-account':
      return MaterialPageRoute(builder: (_) => const PrimaryAccountScreen());
    case '/settings/profile':
      return MaterialPageRoute(builder: (_) => const ProfileDetailsScreen());
    case '/settings/security':
      return MaterialPageRoute(builder: (_) => const SecuritySettingsScreen());
    case '/home':
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );

    case '/notifications':
      return MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
        settings: settings,
      );
    case '/settings/notifications':
      return MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen(),
        settings: settings,
      );

    case '/group/detail':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: args as Map<String, dynamic>),
        settings: settings,
      );

    case '/group/detail/public':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) =>
            GroupDetailPublicScreen(group: args as Map<String, dynamic>),
        settings: settings,
      );

    case '/group/invite':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => GroupInviteScreen(groupId: args as String),
        settings: settings,
      );

    case '/group/create':
      return MaterialPageRoute(
        builder: (_) => const GroupCreationFlowScreen(),
        settings: settings,
      );

    case '/chat/detail':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(group: args as Map<String, dynamic>? ?? {}),
        settings: settings,
      );

    // ========== ACCOUNT ==========
    case '/account/verify-primary':
      return MaterialPageRoute<bool>(
        builder: (_) => const VerifyPrimaryAccountScreen(),
        settings: settings,
      );

    case '/account/setup-primary':
      final args = getArguments();
      return MaterialPageRoute(
        builder: (_) => SetupPrimaryAccountScreen(
          popOnAdd: args['popOnAdd'] as bool? ?? false,
        ),
        settings: settings,
      );

    // ========== FALLBACK ==========
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Page not found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      navigatorKey.currentContext!,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
        settings: settings,
      );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading state
        if (authProvider.isLoading) {
          return SplashScreen();
        }
        if (authProvider.needsUserOnboarding) {
          return OnboardingScreen();
        }
        // If not authenticated, show login screen
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // If authenticated but needs onboarding
        if (authProvider.needsAccountOnboarding) {
          // Return onboarding screen when you create it
          // return const OnboardingScreen();
          return const HomeScreen(); // Temporary fallback
        }

        // Fully authenticated user
        return const HomeScreen();
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:flutter_callkit_incoming/entities/notification_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:uuid/uuid.dart';
// import 'package:video_player/video_player.dart';
// import 'dart:async';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CallKit Simulator Pro',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         useMaterial3: true,
//         fontFamily: 'Inter',
//       ),
//       home: const CallKitDemo(),
//     );
//   }
// }

// class CallKitDemo extends StatefulWidget {
//   const CallKitDemo({super.key});

//   @override
//   State<CallKitDemo> createState() => _CallKitDemoState();
// }

// class _CallKitDemoState extends State<CallKitDemo> {
//   final CallKitSimulator _callKitSimulator = CallKitSimulator();
//   bool _isSimulationMode = true;
//   bool _simulateLockedScreen = false;
//   bool _simulateBackgroundApp = false;
//   String _callStatus = 'No active calls';
//   String? _activeCallId;
//   final Uuid _uuid = Uuid();
//   Timer? _callTimer;
//   int _callDuration = 0;
//   bool _isCallActive = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCallKit();
//   }

//   @override
//   void dispose() {
//     _callTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initializeCallKit() async {
//     try {
//       FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
//         switch (event!.event) {
//           case Event.actionCallIncoming:
//             _updateCallStatus('Incoming call...');
//             _activeCallId = event?.body?['id'];
//             break;
//           case Event.actionCallAccept:
//             _updateCallStatus('Call accepted');
//             _activeCallId = event?.body?['id'];
//             _startCallTimer();
//             break;
//           case Event.actionCallDecline:
//             _updateCallStatus('Call declined');
//             _activeCallId = null;
//             _stopCallTimer();
//             break;
//           case Event.actionCallEnded:
//             _updateCallStatus('Call ended');
//             _activeCallId = null;
//             _stopCallTimer();
//             break;
//           case Event.actionCallTimeout:
//             _updateCallStatus('Call timeout');
//             _activeCallId = null;
//             _stopCallTimer();
//             break;
//           default:
//             break;
//         }
//       });
//     } catch (e) {
//       print('Error initializing CallKit: $e');
//     }
//   }

//   void _updateCallStatus(String status) {
//     setState(() {
//       _callStatus = status;
//     });
//   }

//   void _startCallTimer() {
//     _callDuration = 0;
//     _isCallActive = true;
//     _callTimer?.cancel();
//     _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           _callDuration++;
//         });
//       }
//     });
//   }

//   void _stopCallTimer() {
//     _callTimer?.cancel();
//     _callDuration = 0;
//     _isCallActive = false;
//   }

//   Future<void> _simulateIncomingCall() async {
//     final uuid = _uuid.v4();
//     _activeCallId = uuid;

//     if (_simulateLockedScreen) {
//       // Simulate call on locked screen
//       _showLockedScreenSimulation(uuid);
//     } else if (_simulateBackgroundApp) {
//       // Simulate call while app is in background
//       _showBackgroundAppSimulation(uuid);
//     } else if (_isSimulationMode) {
//       // Normal simulation mode
//       await _callKitSimulator.showMockIncomingCall(
//         callerName: 'John Doe',
//         callerNumber: '+1 (555) 123-4567',
//         context: context,
//         onAccept: () {
//           _updateCallStatus('Call accepted (Simulated)');
//           _startCallTimer();
//           _showCallInProgressScreen();
//         },
//         onDecline: () {
//           _updateCallStatus('Call declined (Simulated)');
//           _activeCallId = null;
//         },
//         onTimeout: () {
//           _updateCallStatus('Missed call (Simulated)');
//           _activeCallId = null;
//         },
//       );
//     } else {
//       // Real CallKit mode
//       await _callKitSimulator.showRealIncomingCall(
//         callerName: 'John Doe',
//         callerNumber: '+1 (555) 123-4567',
//         uuid: uuid,
//       );
//     }
//   }

//   void _showLockedScreenSimulation(String callId) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (context) => LockedScreenSimulation(
//           callerName: 'John Doe',
//           callerNumber: '+1 (555) 123-4567',
//           callId: callId,
//           onAccept: () {
//             _updateCallStatus('Call accepted (Locked Screen)');
//             _startCallTimer();
//             Navigator.pop(context);
//             _showCallInProgressScreen();
//           },
//           onDecline: () {
//             _updateCallStatus('Call declined (Locked Screen)');
//             _activeCallId = null;
//             Navigator.pop(context);
//           },
//         ),
//       ),
//     );
//   }

//   void _showBackgroundAppSimulation(String callId) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (context) => BackgroundAppSimulation(
//           callerName: 'John Doe',
//           callerNumber: '+1 (555) 123-4567',
//           callId: callId,
//           onAccept: () {
//             _updateCallStatus('Call accepted (Background)');
//             _startCallTimer();
//             Navigator.pop(context);
//             _showCallInProgressScreen();
//           },
//           onDecline: () {
//             _updateCallStatus('Call declined (Background)');
//             _activeCallId = null;
//             Navigator.pop(context);
//           },
//         ),
//       ),
//     );
//   }

//   void _showCallInProgressScreen() {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder: (context) => CallInProgressScreen(
//           callerName: 'John Doe',
//           callerNumber: '+1 (555) 123-4567',
//           callDuration: _callDuration,
//           onEndCall: () {
//             _endCall();
//             Navigator.pop(context);
//           },
//           onToggleMute: () {
//             // Mute functionality
//           },
//           onToggleSpeaker: () {
//             // Speaker functionality
//           },
//         ),
//       ),
//     );
//   }

//   Future<void> _endCall() async {
//     if (_isSimulationMode || _simulateLockedScreen || _simulateBackgroundApp) {
//       _updateCallStatus('Call ended');
//     } else if (_activeCallId != null) {
//       try {
//         await FlutterCallkitIncoming.endCall(_activeCallId!);
//       } catch (e) {
//         print('Error ending call: $e');
//       }
//     }
//     _activeCallId = null;
//     _stopCallTimer();
//   }

//   String _formatDuration(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remainingSeconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('CallKit Simulator Pro'),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.deepPurple,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info),
//             onPressed: () {
//               showDialog(context: context, builder: (context) => InfoDialog());
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Status Card
//               _buildStatusCard(),

//               const SizedBox(height: 24),

//               // Mode Selection
//               _buildModeSelection(),

//               const SizedBox(height: 24),

//               // Simulation Options
//               if (_isSimulationMode) _buildSimulationOptions(),

//               const SizedBox(height: 24),

//               // Call Controls
//               _buildCallControls(),

//               const SizedBox(height: 32),

//               // Statistics
//               _buildStatistics(),

//               const SizedBox(height: 40),

//               // Quick Test Section
//               if (!_isSimulationMode) _buildQuickTestSection(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.deepPurple, Colors.purple],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.deepPurple.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   _isCallActive ? Icons.call : Icons.call_end,
//                   color: Colors.white,
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _callStatus,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     if (_isCallActive)
//                       Text(
//                         'Duration: ${_formatDuration(_callDuration)}',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.8),
//                           fontSize: 14,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   _isSimulationMode ? Icons.smart_toy : Icons.phone,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _isSimulationMode ? 'Simulation Mode' : 'Real CallKit Mode',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildModeSelection() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Operation Mode',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildModeOption(
//                     title: 'Simulation',
//                     description: 'Custom UI for testing',
//                     icon: Icons.smart_toy,
//                     isSelected: _isSimulationMode,
//                     color: Colors.amber,
//                     onTap: () => setState(() => _isSimulationMode = true),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildModeOption(
//                     title: 'Real CallKit',
//                     description: 'Native system calls',
//                     icon: Icons.phone,
//                     isSelected: !_isSimulationMode,
//                     color: Colors.green,
//                     onTap: () => setState(() => _isSimulationMode = false),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildModeOption({
//     required String title,
//     required String description,
//     required IconData icon,
//     required bool isSelected,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? color : Colors.transparent,
//             width: 2,
//           ),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(isSelected ? 0.2 : 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? color : Colors.grey[700],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               description,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSimulationOptions() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Simulation Scenarios',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildScenarioOption(
//               title: 'Locked Screen',
//               description: 'Simulate incoming call on locked device',
//               icon: Icons.lock,
//               isSelected: _simulateLockedScreen,
//               onChanged: (value) {
//                 setState(() {
//                   _simulateLockedScreen = value!;
//                   if (value) _simulateBackgroundApp = false;
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
//             _buildScenarioOption(
//               title: 'Background App',
//               description: 'Simulate incoming call while using other apps',
//               icon: Icons.picture_in_picture,
//               isSelected: _simulateBackgroundApp,
//               onChanged: (value) {
//                 setState(() {
//                   _simulateBackgroundApp = value!;
//                   if (value) _simulateLockedScreen = false;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildScenarioOption({
//     required String title,
//     required String description,
//     required IconData icon,
//     required bool isSelected,
//     required ValueChanged<bool?> onChanged,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected ? Colors.blue : Colors.grey.shade300,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(isSelected ? 0.2 : 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.blue, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: isSelected ? Colors.blue : Colors.grey[800],
//                   ),
//                 ),
//                 Text(
//                   description,
//                   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//           Transform.scale(
//             scale: 1.2,
//             child: Switch(
//               value: isSelected,
//               onChanged: onChanged,
//               activeColor: Colors.blue,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCallControls() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               'Call Controls',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _simulateIncomingCall,
//                     icon: const Icon(Icons.add_call, size: 24),
//                     label: const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       child: Text(
//                         'Incoming Call',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 3,
//                     ),
//                   ),
//                 ),
//                 if (_isCallActive) ...[
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: _endCall,
//                       icon: const Icon(Icons.call_end, size: 24),
//                       label: const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         child: Text(
//                           'End Call',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 3,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//             if (!_isSimulationMode) ...[
//               const SizedBox(height: 16),
//               OutlinedButton.icon(
//                 onPressed: () async {
//                   try {
//                     await FlutterCallkitIncoming.endAllCalls();
//                     _updateCallStatus('All calls ended');
//                     _stopCallTimer();
//                   } catch (e) {
//                     print('Error ending all calls: $e');
//                   }
//                 },
//                 icon: const Icon(Icons.clear_all),
//                 label: const Text('End All Calls'),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.red,
//                   side: const BorderSide(color: Colors.red),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatistics() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem(
//             value: _callDuration.toString(),
//             label: 'Call Duration',
//             icon: Icons.timer,
//             color: Colors.purple,
//           ),
//           _buildStatItem(
//             value: _activeCallId != null ? '1' : '0',
//             label: 'Active Calls',
//             icon: Icons.call,
//             color: Colors.blue,
//           ),
//           _buildStatItem(
//             value: '2',
//             label: 'Test Types',
//             icon: Icons.videocam,
//             color: Colors.green,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem({
//     required String value,
//     required String label,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 24),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildQuickTestSection() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Quick Test Calls',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 12,
//               runSpacing: 12,
//               children: [
//                 _buildTestCallButton(
//                   name: 'Alice Smith',
//                   number: '+1 (555) 111-2222',
//                   type: 'Voice',
//                   color: Colors.blue,
//                 ),
//                 _buildTestCallButton(
//                   name: 'Bob Johnson',
//                   number: '+1 (555) 333-4444',
//                   type: 'Video',
//                   color: Colors.green,
//                 ),
//                 _buildTestCallButton(
//                   name: 'Emma Wilson',
//                   number: '+1 (555) 555-6666',
//                   type: 'Voice',
//                   color: Colors.orange,
//                 ),
//                 _buildTestCallButton(
//                   name: 'Mike Davis',
//                   number: '+1 (555) 777-8888',
//                   type: 'Video',
//                   color: Colors.purple,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTestCallButton({
//     required String name,
//     required String number,
//     required String type,
//     required Color color,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: () async {
//         final uuid = _uuid.v4();
//         _activeCallId = uuid;
//         await _callKitSimulator.showRealIncomingCall(
//           callerName: name,
//           callerNumber: number,
//           uuid: uuid,
//           isVideoCall: type == 'Video',
//         );
//       },
//       icon: Icon(type == 'Video' ? Icons.videocam : Icons.phone, size: 18),
//       label: Text(name),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color.withOpacity(0.1),
//         foregroundColor: color,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       ),
//     );
//   }
// }

// class CallKitSimulator {
//   Future<void> showRealIncomingCall({
//     required String callerName,
//     required String callerNumber,
//     required String uuid,
//     bool isVideoCall = false,
//   }) async {
//     final params = CallKitParams(
//       id: uuid,
//       nameCaller: callerName,
//       appName: 'CallKit Simulator Pro',
//       avatar:
//           'https://png.pngtree.com/png-clipart/20230927/original/pngtree-man-avatar-image-for-profile-png-image_13001877.png',
//       handle: callerNumber,
//       type: isVideoCall ? 1 : 0,
//       duration: 45000,
//       textAccept: 'Accept',
//       textDecline: 'Decline',
//       // textMissedCall: 'Missed call',
//       // textCallback: 'Call back',
//       callingNotification: NotificationParams(
//         callbackText: 'Call Hoop Back',
//         count: 1,

//         isShowCallback: true,
//         subtitle: 'Test Calling...',
//         showNotification: true,
//       ),
//       extra: <String, dynamic>{
//         'userId': 'test_user_123',
//         'callType': isVideoCall ? 'video' : 'voice',
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       },
//       ios: IOSParams(
//         iconName: 'CallKitLogo',
//         handleType: 'generic',
//         supportsVideo: isVideoCall,
//         maximumCallGroups: 2,
//         maximumCallsPerCallGroup: 1,
//         audioSessionMode: 'default',
//         audioSessionActive: true,
//         audioSessionPreferredSampleRate: 44100.0,
//         audioSessionPreferredIOBufferDuration: 0.005,
//         supportsDTMF: true,
//         supportsHolding: true,
//         supportsGrouping: false,
//         supportsUngrouping: false,
//         ringtonePath: 'system_ringtone_default',
//       ),
//       android: AndroidParams(
//         isCustomNotification: true,
//         isShowLogo: true,
//         ringtonePath: 'system_ringtone_default',
//         backgroundColor: '#7C3AED',
//         backgroundUrl:
//             'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
//         actionColor: '#10B981',
//         incomingCallNotificationChannelName: 'Incoming Calls',
//         missedCallNotificationChannelName: 'Missed Calls',
//       ),
//       missedCallNotification: NotificationParams(
//         showNotification: true,
//         isShowCallback: true,
//         subtitle: 'Missed call from $callerName',
//         callbackText: 'Call back',
//       ),
//     );

//     await FlutterCallkitIncoming.showCallkitIncoming(params);
//   }

//   Future<void> showMockIncomingCall({
//     required String callerName,
//     required String callerNumber,
//     required BuildContext context,
//     required VoidCallback onAccept,
//     required VoidCallback onDecline,
//     VoidCallback? onTimeout,
//   }) async {
//     if (onTimeout != null) {
//       Future.delayed(const Duration(seconds: 30), () {
//         if (ModalRoute.of(context)?.isCurrent ?? false) {
//           Navigator.of(context).pop();
//           onTimeout();
//         }
//       });
//     }

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.8),
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         child: MockIncomingCallUI(
//           callerName: callerName,
//           callerNumber: callerNumber,
//           onAccept: () {
//             Navigator.pop(context);
//             onAccept();
//           },
//           onDecline: () {
//             Navigator.pop(context);
//             onDecline();
//           },
//         ),
//       ),
//     );
//   }
// }

// class MockIncomingCallUI extends StatelessWidget {
//   final String callerName;
//   final String callerNumber;
//   final VoidCallback onAccept;
//   final VoidCallback onDecline;

//   const MockIncomingCallUI({
//     super.key,
//     required this.callerName,
//     required this.callerNumber,
//     required this.onAccept,
//     required this.onDecline,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.black.withOpacity(0.9),
//             Colors.black.withOpacity(0.95),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 30),
//             child: const Column(
//               children: [
//                 Icon(
//                   Icons.call_received_outlined,
//                   size: 40,
//                   color: Colors.white,
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Incoming Call',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w300,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Caller Info
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Colors.deepPurple, Colors.purple],
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       callerName[0],
//                       style: const TextStyle(
//                         fontSize: 40,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   callerName,
//                   style: const TextStyle(
//                     fontSize: 32,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   callerNumber,
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white.withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Action Buttons
//           Container(
//             padding: const EdgeInsets.all(30),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Decline Button
//                 _buildActionButton(
//                   icon: Icons.call_end,
//                   label: 'Decline',
//                   color: Colors.red,
//                   onTap: onDecline,
//                 ),

//                 // Accept Button
//                 _buildActionButton(
//                   icon: Icons.phone,
//                   label: 'Accept',
//                   color: Colors.green,
//                   onTap: onAccept,
//                 ),
//               ],
//             ),
//           ),

//           // Simulation Indicator
//           Container(
//             padding: const EdgeInsets.only(bottom: 20),
//             child: Text(
//               'SIMULATION MODE',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.5),
//                 fontSize: 12,
//                 letterSpacing: 2,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.4),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Icon(icon, color: Colors.white, size: 30),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class LockedScreenSimulation extends StatefulWidget {
//   final String callerName;
//   final String callerNumber;
//   final String callId;
//   final VoidCallback onAccept;
//   final VoidCallback onDecline;

//   const LockedScreenSimulation({
//     super.key,
//     required this.callerName,
//     required this.callerNumber,
//     required this.callId,
//     required this.onAccept,
//     required this.onDecline,
//   });

//   @override
//   State<LockedScreenSimulation> createState() => _LockedScreenSimulationState();
// }

// class _LockedScreenSimulationState extends State<LockedScreenSimulation> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Simulated Lock Screen Background
//           Positioned.fill(
//             child: Image.network(
//               'https://images.unsplash.com/photo-1519681393784-d120267933ba',
//               fit: BoxFit.cover,
//               color: Colors.black.withOpacity(0.7),
//               colorBlendMode: BlendMode.darken,
//             ),
//           ),

//           // Lock Screen Elements
//           Positioned(
//             top: 60,
//             left: 0,
//             right: 0,
//             child: Column(
//               children: [
//                 Text(
//                   '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
//                   style: const TextStyle(
//                     fontSize: 80,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w300,
//                   ),
//                 ),
//                 Text(
//                   '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w300,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Call UI (similar to iOS lock screen call UI)
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.white.withOpacity(0.1)),
//                     ),
//                     child: Column(
//                       children: [
//                         // Caller Info
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.2),
//                               width: 2,
//                             ),
//                           ),
//                           child: Icon(
//                             Icons.person,
//                             size: 60,
//                             color: Colors.white.withOpacity(0.8),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Text(
//                           widget.callerName,
//                           style: const TextStyle(
//                             fontSize: 28,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           widget.callerNumber,
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white.withOpacity(0.7),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'mobile',
//                           style: TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 40),

//                   // Action Buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       // Decline
//                       Column(
//                         children: [
//                           Container(
//                             width: 70,
//                             height: 70,
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.call_end, size: 30),
//                               color: Colors.white,
//                               onPressed: widget.onDecline,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           const Text(
//                             'Decline',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       ),

//                       // Accept
//                       Column(
//                         children: [
//                           Container(
//                             width: 70,
//                             height: 70,
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               shape: BoxShape.circle,
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.phone, size: 30),
//                               color: Colors.white,
//                               onPressed: widget.onAccept,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           const Text(
//                             'Accept',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // Simulation Note
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.lock, size: 14, color: Colors.grey),
//                         SizedBox(width: 8),
//                         Text(
//                           'Locked Screen Simulation',
//                           style: TextStyle(color: Colors.grey, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getMonthName(int month) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//     return months[month - 1];
//   }
// }

// class BackgroundAppSimulation extends StatefulWidget {
//   final String callerName;
//   final String callerNumber;
//   final String callId;
//   final VoidCallback onAccept;
//   final VoidCallback onDecline;

//   const BackgroundAppSimulation({
//     super.key,
//     required this.callerName,
//     required this.callerNumber,
//     required this.callId,
//     required this.onAccept,
//     required this.onDecline,
//   });

//   @override
//   State<BackgroundAppSimulation> createState() =>
//       _BackgroundAppSimulationState();
// }

// class _BackgroundAppSimulationState extends State<BackgroundAppSimulation> {
//   late VideoPlayerController _videoController;

//   @override
//   void initState() {
//     super.initState();
//     _videoController =
//         VideoPlayerController.networkUrl(
//             Uri.parse(
//               'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
//             ),
//           )
//           ..initialize().then((_) {
//             _videoController.setLooping(true);
//             _videoController.play();
//             setState(() {});
//           });
//   }

//   @override
//   void dispose() {
//     _videoController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Simulated other app (YouTube-like)
//           Positioned.fill(
//             child: _videoController.value.isInitialized
//                 ? VideoPlayer(_videoController)
//                 : Container(
//                     color: Colors.black,
//                     child: const Center(child: CircularProgressIndicator()),
//                   ),
//           ),

//           // YouTube UI overlay
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.black.withOpacity(0.8), Colors.transparent],
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const Expanded(
//                     child: Text(
//                       'Big Buck Bunny',
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.search, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.more_vert, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Call Overlay (Notification style)
//           Positioned(
//             top: 80,
//             left: 16,
//             right: 16,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.85),
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(color: Colors.white.withOpacity(0.1)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 20,
//                     spreadRadius: 5,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [Colors.deepPurple, Colors.purple],
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             widget.callerName[0],
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.callerName,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               widget.callerNumber,
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.7),
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Icon(
//                         Icons.call_received_outlined,
//                         color: Colors.green,
//                         size: 24,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: widget.onDecline,
//                           icon: const Icon(Icons.call_end, size: 20),
//                           label: const Text('Decline'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: widget.onAccept,
//                           icon: const Icon(Icons.phone, size: 20),
//                           label: const Text('Accept'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'CallKit - Tap to return to app',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // YouTube player controls
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [Colors.black.withOpacity(0.9), Colors.transparent],
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.skip_previous, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       _videoController.value.isPlaying
//                           ? Icons.pause
//                           : Icons.play_arrow,
//                       color: Colors.white,
//                       size: 30,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         if (_videoController.value.isPlaying) {
//                           _videoController.pause();
//                         } else {
//                           _videoController.play();
//                         }
//                       });
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.skip_next, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   Expanded(
//                     child: Slider(
//                       value: _videoController.value.position.inSeconds
//                           .toDouble(),
//                       min: 0,
//                       max: _videoController.value.duration.inSeconds.toDouble(),
//                       onChanged: (value) {
//                         _videoController.seekTo(
//                           Duration(seconds: value.toInt()),
//                         );
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.fullscreen, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Simulation indicator
//           Positioned(
//             bottom: 100,
//             right: 16,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.picture_in_picture, size: 14, color: Colors.grey),
//                   SizedBox(width: 6),
//                   Text(
//                     'Background App Simulation',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CallInProgressScreen extends StatelessWidget {
//   final String callerName;
//   final String callerNumber;
//   final int callDuration;
//   final VoidCallback onEndCall;
//   final VoidCallback onToggleMute;
//   final VoidCallback onToggleSpeaker;

//   const CallInProgressScreen({
//     super.key,
//     required this.callerName,
//     required this.callerNumber,
//     required this.callDuration,
//     required this.onEndCall,
//     required this.onToggleMute,
//     required this.onToggleSpeaker,
//   });

//   String _formatDuration(int seconds) {
//     final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
//     final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remainingSeconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Status Bar Spacer
//             Container(height: 20),

//             // Caller Info
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Caller Avatar
//                   Container(
//                     width: 140,
//                     height: 140,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [Colors.deepPurple, Colors.purple],
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.deepPurple.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: Text(
//                         callerName[0],
//                         style: const TextStyle(
//                           fontSize: 60,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 40),

//                   // Caller Name
//                   Text(
//                     callerName,
//                     style: const TextStyle(
//                       fontSize: 36,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   // Call Status
//                   Text(
//                     'Calling...',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.white.withOpacity(0.7),
//                     ),
//                   ),

//                   const SizedBox(height: 30),

//                   // Call Duration
//                   Text(
//                     _formatDuration(callDuration),
//                     style: const TextStyle(
//                       fontSize: 48,
//                       color: Colors.white,
//                       fontWeight: FontWeight.w300,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Call Controls
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
//               child: Column(
//                 children: [
//                   // Additional Controls
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildControlButton(
//                         icon: Icons.mic,
//                         label: 'Mute',
//                         onPressed: onToggleMute,
//                       ),
//                       _buildControlButton(
//                         icon: Icons.volume_up,
//                         label: 'Speaker',
//                         onPressed: onToggleSpeaker,
//                       ),
//                       _buildControlButton(
//                         icon: Icons.pause,
//                         label: 'Hold',
//                         onPressed: () {},
//                       ),
//                       _buildControlButton(
//                         icon: Icons.dialpad,
//                         label: 'Keypad',
//                         onPressed: () {},
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 40),

//                   // End Call Button
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.red,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.red.withOpacity(0.4),
//                           blurRadius: 15,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.call_end, size: 40),
//                       color: Colors.white,
//                       onPressed: onEndCall,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white.withOpacity(0.1),
//           ),
//           child: IconButton(
//             icon: Icon(icon, color: Colors.white, size: 24),
//             onPressed: onPressed,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
//         ),
//       ],
//     );
//   }
// }

// class InfoDialog extends StatelessWidget {
//   const InfoDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.info, color: Colors.blue),
//                 SizedBox(width: 12),
//                 Text(
//                   'CallKit Simulator Pro',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _buildInfoItem(
//               '🎯',
//               'Simulation Mode',
//               'Test calls with custom UI without real calls',
//             ),
//             _buildInfoItem(
//               '📱',
//               'Real CallKit Mode',
//               'Use native iOS CallKit / Android ConnectionService',
//             ),
//             _buildInfoItem(
//               '🔒',
//               'Locked Screen Simulation',
//               'Test how calls appear on locked devices',
//             ),
//             _buildInfoItem(
//               '📱',
//               'Background App Simulation',
//               'Test calls while using other applications',
//             ),
//             _buildInfoItem(
//               '⏱️',
//               'Call Duration Timer',
//               'Track call duration in real-time',
//             ),
//             _buildInfoItem(
//               '📊',
//               'Statistics',
//               'View call metrics and test history',
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Got it!'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(String emoji, String title, String description) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 20)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 Text(
//                   description,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();