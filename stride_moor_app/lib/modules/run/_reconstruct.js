var fs = require("fs");
var tail = fs.readFileSync("D:\\AI\\StrideMoor\\stride_moor_app\\lib\\modules\\run\\_surviving_tail.dart", "utf8");

// Preamble: imports + class definitions + missing methods
// NOTE: warmOrange is NOT prefixed with _ because it's used as warmOrange in the tail
var preamble = [
  "import 'package:flutter/material.dart';",
  "import 'package:flutter_riverpod/flutter_riverpod.dart';",
  "import 'package:flutter_screenutil/flutter_screenutil.dart';",
  "import 'package:go_router/go_router.dart';",
  "import 'package:gmm_amap_flutter_base/gmm_amap_flutter_base.dart';",
  "import 'package:gmm_amap_flutter_map/gmm_amap_flutter_map.dart';",
  "",
  "import '../../config/constants.dart';",
  "import '../../config/theme.dart';",
  "import '../../core/models/run.dart';",
  "import '../../core/models/run_goal.dart';",
  "import '../../core/models/route.dart' as app_route;",
  "import '../../core/providers/app_providers.dart';",
  "import '../../core/providers/run_provider.dart';",
  "import '../../core/services/location_service.dart';",
  "import '../../core/services/debug_step_logger.dart';",
  "import '../../l10n/app_localizations.dart';",
  "import '../../widgets/amap_map_view.dart';",
  "import 'friends_route_select_page.dart';",
  "import 'run_finish_page.dart';",
  "import 'run_preparation_page.dart';",
  "",
  "/// 跑中页面",
  "const Color warmOrange = Color(0xFFFF8533);",
  "const Color warmOrangeLight = Color(0xFFFFAA66);",
  "",
  "class RunningPage extends ConsumerStatefulWidget {",
  "  const RunningPage({super.key});",
  "  static void Function(Run?)? onFinishRun;",
  "  @override",
  "  ConsumerState<RunningPage> createState() => _RunningPageState();",
  "}",
  "",
  "class _RunningPageState extends ConsumerState<RunningPage>",
  "    with TickerProviderStateMixin {",
  "  // ---------- Panel state ----------",
  "  double _panelHeight = 0;",
  "  double _panelDragStart = 0;",
  "  double _panelDragStartY = 0;",
  "  double _panelMinHeight = 0;",
  "  double _panelMaxHeight = 0;",
  "  double _buttonAreaHeight = 0;",
  "  final List<double> _snapFractions = [0.15, 0.50];",
  "",
  "  // ---------- Animations ----------",
  "  late AnimationController _pulseController;",
  "  late AnimationController _countdownAnimController;",
  "  late Animation<double> _countdownScale;",
  "  late Animation<double> _countdownOpacity;",
  "  int _countdownValue = 3;",
  "",
  "  // ---------- State ----------",
  "  bool _isLocked = false;",
  "  bool _initError = false;",
  "  String _initErrorMsg = '';",
  "  bool _voiceOk = false;",
  "",
  "  @override",
  "  void initState() {",
  "    super.initState();",
  "    _pulseController = AnimationController(",
  "      vsync: this,",
  "      duration: const Duration(milliseconds: 1500),",
  "    )..repeat();",
  "    _countdownAnimController = AnimationController(",
  "      vsync: this,",
  "      duration: const Duration(seconds: 3),",
  "    );",
  "    _countdownScale = Tween<double>(begin: 1.5, end: 0.8).animate(",
  "      CurvedAnimation(parent: _countdownAnimController, curve: Curves.easeOut),",
  "    );",
  "    _countdownOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(",
  "      CurvedAnimation(parent: _countdownAnimController, curve: Curves.easeIn),",
  "    );",
  "    _doInit();",
  "  }",
  "",
  "  @override",
  "  void dispose() {",
  "    _pulseController.dispose();",
  "    _countdownAnimController.dispose();",
  "    super.dispose();",
  "  }",
  "",
  "  void _doInit() {}",
  "",
  "  @override",
  "  Widget build(BuildContext context) {",
  "    final session = ref.watch(runSessionProvider);",
  "    final l10n = AppLocalizations.of(context)!;",
  "    final screenHeight = MediaQuery.of(context).size.height;",
  "",
  "    return Scaffold(",
  "      backgroundColor: const Color(0xFF0A0A1A),",
  "      body: Stack(",
  "        children: [",
  "          // Main content (map + panel + buttons)",
  "          _buildRunningContent(session, l10n, screenHeight),",
  "",
  "          // Init error overlay",
  "          if (_initError) _buildInitErrorOverlay(),",
  "",
  "          // Countdown overlay",
  "          if (_countdownValue > 0) _buildCountdownOverlay(),",
  "",
  "          // Lock screen overlay",
  "          if (_isLocked) _buildLockScreen(session, l10n),",
  "",
  "          // GPS search overlay",
  "          if (!_initError && !_locationInitialized) _buildGpsOverlay(l10n),",
  "        ],",
  "      ),",
  "    );",
  "  }",
  "",
  "  Widget _buildRunningContent(RunSessionState session, AppLocalizations l10n, double screenHeight) {",
  "    final bottomInset = MediaQuery.of(context).padding.bottom;",
  "    _buttonAreaHeight = 56.h + bottomInset;",
  "    _panelMinHeight = screenHeight * 0.15;",
  "    _panelMaxHeight = screenHeight * 0.50 - _buttonAreaHeight;",
  "",
  "    if (_panelHeight <= 0) {",
  "      _panelHeight = _panelMinHeight;",
  "    }",
  "",
  "    return Stack(",
  "      children: [",
  "        // Map layer (full screen)",
  "        Positioned.fill(child: _buildMapLayer(session)),",
  "",
  "        // Custom panel (above buttons)",
  "        Positioned(",
  "          left: 0, right: 0,",
  "          bottom: _buttonAreaHeight,",
  "          child: _buildCustomPanel(session, l10n),",
  "        ),",
  "",
  "        // Bottom control buttons",
  "        Positioned(",
  "          left: 0, right: 0,",
  "          bottom: 0,",
  "          child: _buildBottomControls(session, l10n),",
  "        ),",
  "      ],",
  "    );",
  "  }",
  "",
  "  Color _hrZoneColor(int hr) {",
  "    if (hr >= 165) return const Color(0xFFFF3B30);",
  "    if (hr >= 140) return const Color(0xFFFF6B35);",
  "    if (hr >= 120) return const Color(0xFFFF9500);",
  "    return const Color(0xFF34C759);",
  "  }",
  "",
].join("\n");

// Fix _buildCustomPanel: replace unconditional Expanded with if/else
var customPanelStart = tail.indexOf("Widget _buildCustomPanel");
var expandedPos = tail.indexOf("          Expanded(", customPanelStart);
var openParenPos = tail.indexOf("(", expandedPos);

var depth = 1;
var endPos = 0;
for (var i = openParenPos + 1; i < tail.length; i++) {
  if (tail[i] == "(" || tail[i] == "{" || tail[i] == "[") depth++;
  if (tail[i] == ")" || tail[i] == "}" || tail[i] == "]") depth--;
  if (depth == 0) { endPos = i + 1; break; }
}
var oldExpanded = tail.substring(expandedPos, endPos);
console.log("Expanded at " + expandedPos + " -> " + endPos + " (" + oldExpanded.length + "b)");

// Build replacement
var dollar = "$";
var hrText = '                      "' + dollar + '{session.currentRun?.avgHeartRate ?? ' + "'--'" + '}",';

var r = [];
r.push("          if (_panelHeight > _panelMinHeight + 20.h)");
r.push("            Expanded(");
r.push("              child: SingleChildScrollView(");
r.push("                padding: EdgeInsets.symmetric(horizontal: 24.w),");
r.push("                child: _buildPanelContent(session, l10n),");
r.push("              ),");
r.push("            )");
r.push("          else");
r.push("            Expanded(");
r.push("              child: Center(");
r.push("                child: Row(");
r.push("                  mainAxisAlignment: MainAxisAlignment.center,");
r.push("                  children: [");
r.push("                    Text(");
r.push("                      _formatTime(session.currentRun?.duration ?? 0),");
r.push("                      style: TextStyle(");
r.push("                        fontSize: 20.sp, fontWeight: FontWeight.w700,");
r.push("                        color: Colors.white,");
r.push("                      ),");
r.push("                    ),");
r.push("                    SizedBox(width: 20.w),");
r.push("                    Icon(Icons.favorite, color: Color(0xFFFF3B30), size: 18.sp),");
r.push("                    SizedBox(width: 4.w),");
r.push("                    Text(");
r.push(hrText);
r.push("                      style: TextStyle(");
r.push("                        fontSize: 20.sp, fontWeight: FontWeight.w700,");
r.push("                        color: Colors.white,");
r.push("                      ),");
r.push("                    ),");
r.push("                  ],");
r.push("                ),");
r.push("              ),");
r.push("            )");
var replacement = r.join("\n");

var fixedTail = tail.replace(oldExpanded, replacement);

// Check if _snapPanel exists in tail - remove from preamble
// The tail has _snapPanel at 7470, so it's already there
console.log("_snapPanel in tail:", tail.indexOf("void _snapPanel"));

// Combine
var output = preamble + "\n" + fixedTail;
var opens = (output.match(/[{([]/g)||[]).length;
var closes = (output.match(/[})\]]/g)||[]).length;
console.log("Brackets: " + opens + "/" + closes + " => " + (opens == closes ? "BALANCED!" : "MISMATCH diff=" + (opens-closes)));

fs.writeFileSync("D:\\AI\\StrideMoor\\stride_moor_app\\lib\\modules\\run\\running_page.dart", output, "utf8");
console.log("Written! Length:", output.length);
