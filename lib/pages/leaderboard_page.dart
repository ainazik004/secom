import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shimmer/shimmer.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

enum _BoardType { trophies, streak }

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  static const double _itemExtent = 90.0;

  late final TabController _tabController;

  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _trophyFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _streakFuture;

  final ScrollController _trophyScroll = ScrollController();
  final ScrollController _streakScroll = ScrollController();

  // --- TROPHY visible tracking
  bool _trophyUserTileVisible = false;
  double _trophyViewportHeight = 0;
  int _trophyFirstVisibleIndex = 0;
  int _trophyLastVisibleIndex = 0;
  bool _trophyVisibleRangeReady = false;

  // --- STREAK visible tracking
  bool _streakUserTileVisible = false;
  double _streakViewportHeight = 0;
  int _streakFirstVisibleIndex = 0;
  int _streakLastVisibleIndex = 0;
  bool _streakVisibleRangeReady = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _trophyFuture = _loadLeaderboard(_BoardType.trophies);
    _streakFuture = _loadLeaderboard(_BoardType.streak);

    _trophyScroll.addListener(() => _updateVisibleRange(_BoardType.trophies));
    _streakScroll.addListener(() => _updateVisibleRange(_BoardType.streak));
  }

  @override
  void dispose() {
    _trophyScroll.dispose();
    _streakScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ✅ TOP-51 LOGIC:
  // - Load top 50
  // - If current user is not in top 50, append current user doc => 51 items max
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _loadLeaderboard(
      _BoardType type,
      ) async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return [];

    final field =
    type == _BoardType.trophies ? 'trophies' : 'currentStreakDays';

    final top50snap = await db
        .collection('users')
        .orderBy(field, descending: true)
        .limit(50)
        .get();

    final top50 = top50snap.docs;

    final me = await db.collection('users').doc(user.uid).get();
    final isInTop50 = top50.any((d) => d.id == user.uid);

    return isInTop50 ? top50 : [...top50, me];
  }

  Future<void> _onRefresh(_BoardType type) async {
    setState(() {
      if (type == _BoardType.trophies) {
        _trophyFuture = _loadLeaderboard(_BoardType.trophies);
        _trophyUserTileVisible = false;
        _trophyVisibleRangeReady = false;
        _trophyFirstVisibleIndex = 0;
        _trophyLastVisibleIndex = 0;
      } else {
        _streakFuture = _loadLeaderboard(_BoardType.streak);
        _streakUserTileVisible = false;
        _streakVisibleRangeReady = false;
        _streakFirstVisibleIndex = 0;
        _streakLastVisibleIndex = 0;
      }
    });

    if (type == _BoardType.trophies) {
      await _trophyFuture;
    } else {
      await _streakFuture;
    }
  }

  void _updateVisibleRange(_BoardType type) {
    final sc = type == _BoardType.trophies ? _trophyScroll : _streakScroll;
    final viewport =
    type == _BoardType.trophies ? _trophyViewportHeight : _streakViewportHeight;

    if (!sc.hasClients || viewport <= 0) return;

    final offset = sc.offset.clamp(0.0, double.infinity);

    final first = (offset / _itemExtent).floor().clamp(0, 1000000);
    final last = ((offset + viewport) / _itemExtent).floor().clamp(first, 1000000);

    setState(() {
      if (type == _BoardType.trophies) {
        if (first != _trophyFirstVisibleIndex ||
            last != _trophyLastVisibleIndex ||
            !_trophyVisibleRangeReady) {
          _trophyFirstVisibleIndex = first;
          _trophyLastVisibleIndex = last;
          _trophyVisibleRangeReady = true;
        }
      } else {
        if (first != _streakFirstVisibleIndex ||
            last != _streakLastVisibleIndex ||
            !_streakVisibleRangeReady) {
          _streakFirstVisibleIndex = first;
          _streakLastVisibleIndex = last;
          _streakVisibleRangeReady = true;
        }
      }
    });
  }

  // ✅ Prefer displayName, fallback to fullName, then others.
  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  void _openUserDialog(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    final fullName = _readDisplayName(data);

    final photoUrlRaw = data['photoUrl'];
    final photoUrl = (photoUrlRaw is String && photoUrlRaw.trim().isNotEmpty)
        ? photoUrlRaw
        : null;

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final trophies = readInt(data['trophies']);
    final streakDays = readInt(data['currentStreakDays']);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CenteredUserDialog(
        fullName: fullName,
        photoUrl: photoUrl,
        trophies: trophies,
        streakDays: streakDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs (icon-only)
              SizedBox(
                height: 44,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.60),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.45),
                      ),
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(12),
                    labelPadding: EdgeInsets.zero,
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    tabs: const [
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        icon: Icon(Icons.emoji_events_rounded, size: 22),
                      ),
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        icon: Icon(Icons.local_fire_department_rounded, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LeaderboardTab(
                      type: _BoardType.trophies,
                      future: _trophyFuture,
                      scrollController: _trophyScroll,
                      onRefresh: () => _onRefresh(_BoardType.trophies),
                      itemExtent: _itemExtent,
                      onViewportHeight: (h) {
                        if (_trophyViewportHeight != h) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _trophyViewportHeight = h;
                            _updateVisibleRange(_BoardType.trophies);
                          });
                        }
                      },
                      isUserTileVisible: _trophyUserTileVisible,
                      setUserTileVisible: (v) {
                        if (_trophyUserTileVisible != v) {
                          setState(() => _trophyUserTileVisible = v);
                        }
                      },
                      visibleRangeReady: _trophyVisibleRangeReady,
                      firstVisibleIndex: _trophyFirstVisibleIndex,
                      lastVisibleIndex: _trophyLastVisibleIndex,
                      metricField: 'trophies',
                      metricIcon: Icons.emoji_events_rounded,
                      metricIconColor: cs.tertiary,
                      shortenMetric: true,
                      onOpenUser: _openUserDialog,
                    ),
                    _LeaderboardTab(
                      type: _BoardType.streak,
                      future: _streakFuture,
                      scrollController: _streakScroll,
                      onRefresh: () => _onRefresh(_BoardType.streak),
                      itemExtent: _itemExtent,
                      onViewportHeight: (h) {
                        if (_streakViewportHeight != h) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _streakViewportHeight = h;
                            _updateVisibleRange(_BoardType.streak);
                          });
                        }
                      },
                      isUserTileVisible: _streakUserTileVisible,
                      setUserTileVisible: (v) {
                        if (_streakUserTileVisible != v) {
                          setState(() => _streakUserTileVisible = v);
                        }
                      },
                      visibleRangeReady: _streakVisibleRangeReady,
                      firstVisibleIndex: _streakFirstVisibleIndex,
                      lastVisibleIndex: _streakLastVisibleIndex,
                      metricField: 'currentStreakDays',
                      metricIcon: Icons.local_fire_department_rounded,
                      metricIconColor: const Color(0xFFFF5A00),
                      shortenMetric: false,
                      onOpenUser: _openUserDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final _BoardType type;
  final Future<List<DocumentSnapshot<Map<String, dynamic>>>> future;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final double itemExtent;

  final void Function(double height) onViewportHeight;

  final bool isUserTileVisible;
  final void Function(bool visible) setUserTileVisible;

  final bool visibleRangeReady;
  final int firstVisibleIndex;
  final int lastVisibleIndex;

  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;

  final bool shortenMetric;

  final void Function(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) onOpenUser;

  const _LeaderboardTab({
    required this.type,
    required this.future,
    required this.scrollController,
    required this.onRefresh,
    required this.itemExtent,
    required this.onViewportHeight,
    required this.isUserTileVisible,
    required this.setUserTileVisible,
    required this.visibleRangeReady,
    required this.firstVisibleIndex,
    required this.lastVisibleIndex,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onOpenUser,
  });

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  String? _readPhotoUrl(Map<String, dynamic> data) {
    final raw = data['photoUrl'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    // ✅ Highly visible shimmer palette (does NOT rely on your theme containers)
    final shimmerBase =
    isDark ? const Color(0xFF2A2434) : const Color(0xFFE3DDF0);
    final shimmerHighlight =
    isDark ? const Color(0xFF3A3346) : const Color(0xFFF9F7FF);

    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _LeaderboardShimmer(
            itemExtent: itemExtent,
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
          );
        }

        if (!snap.hasData || snap.data!.isEmpty || userId == null) {
          return Center(
            child: Text(
              "No users yet",
              style: TextStyle(
                color: cs.onBackground.withOpacity(0.65),
                fontSize: 14,
              ),
            ),
          );
        }

        final docs = snap.data!;
        final myIndex = docs.indexWhere((d) => d.id == userId);

        return LayoutBuilder(
          builder: (context, constraints) {
            onViewportHeight(constraints.maxHeight);

            bool showTop = false;
            bool showBottom = false;

            if (visibleRangeReady && myIndex != -1 && !isUserTileVisible) {
              if (myIndex < firstVisibleIndex) {
                showTop = true;
              } else if (myIndex > lastVisibleIndex) {
                showBottom = true;
              }
            }

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: Stack(
                children: [
                  ListView.separated(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() ?? {};

                      final String name = _readDisplayName(data);
                      final String? photoUrl = _readPhotoUrl(data);
                      final int metricValue = _readInt(data[metricField]);
                      final bool isMe = doc.id == userId;

                      final tile = LeaderboardUserTile(
                        index: index,
                        name: name,
                        metricValue: metricValue,
                        photoUrl: photoUrl,
                        isMe: isMe,
                        metricIcon: metricIcon,
                        metricIconColor: metricIconColor,
                        shortenMetric: shortenMetric,
                        onTap: () => onOpenUser(context, doc),
                      );

                      if (isMe) {
                        return VisibilityDetector(
                          key: Key("${type.name}-user-tile-$userId"),
                          onVisibilityChanged: (info) {
                            final visible = info.visibleFraction > 0.45;
                            setUserTileVisible(visible);
                          },
                          child: tile,
                        );
                      }

                      return tile;
                    },
                  ),
                  if (showTop || showBottom)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: showTop ? 4 : null,
                      bottom: showBottom ? 4 : null,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: -50, end: 0),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, value),
                            child: child,
                          );
                        },
                        child: _FloatingMyTile(
                          docs: docs,
                          userId: userId,
                          metricField: metricField,
                          metricIcon: metricIcon,
                          metricIconColor: metricIconColor,
                          shortenMetric: shortenMetric,
                          onTapDoc: (doc) => onOpenUser(context, doc),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ✅ Shimmer list placeholder (matches tile layout)
class _LeaderboardShimmer extends StatelessWidget {
  final double itemExtent;
  final Color baseColor;
  final Color highlightColor;

  const _LeaderboardShimmer({
    required this.itemExtent,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ No RefreshIndicator here (it can visually mask shimmer and is not needed)
    // ✅ All placeholders are opaque (white) so shimmer ALWAYS shows.
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 0),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _LeaderboardShimmerTile(itemExtent: itemExtent);
        },
      ),
    );
  }
}

class _LeaderboardShimmerTile extends StatelessWidget {
  final double itemExtent;

  const _LeaderboardShimmerTile({required this.itemExtent});

  @override
  Widget build(BuildContext context) {
    Widget pill({double w = 80, double h = 14, double r = 10}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white, // ✅ opaque
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      height: itemExtent,
      decoration: BoxDecoration(
        color: Colors.white, // ✅ opaque
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pill(w: 160, h: 14),
                const SizedBox(height: 8),
                pill(w: 110, h: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          pill(w: 48, h: 14),
        ],
      ),
    );
  }
}

class _FloatingMyTile extends StatelessWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> docs;
  final String userId;
  final String metricField;
  final IconData metricIcon;
  final Color metricIconColor;
  final bool shortenMetric;
  final void Function(DocumentSnapshot<Map<String, dynamic>> doc) onTapDoc;

  const _FloatingMyTile({
    super.key,
    required this.docs,
    required this.userId,
    required this.metricField,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onTapDoc,
  });

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String _readDisplayName(Map<String, dynamic> data) {
    String pick(dynamic v) => (v ?? '').toString().trim();

    final displayName = pick(data['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final fullName = pick(data['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = pick(data['firstName']);
    final surname = pick(data['surname']);
    final combined = ('$firstName $surname').trim();
    if (combined.isNotEmpty) return combined;

    final name = pick(data['name']);
    if (name.isNotEmpty) return name;

    return '—';
  }

  String? _readPhotoUrl(Map<String, dynamic> data) {
    final raw = data['photoUrl'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final doc = docs.firstWhere((d) => d.id == userId);
    final data = doc.data() ?? {};

    final String name = _readDisplayName(data);
    final String? photoUrl = _readPhotoUrl(data);
    final int metricValue = _readInt(data[metricField]);

    return LeaderboardUserTile(
      index: docs.indexOf(doc),
      name: name,
      metricValue: metricValue,
      photoUrl: photoUrl,
      isMe: true,
      metricIcon: metricIcon,
      metricIconColor: metricIconColor,
      shortenMetric: shortenMetric,
      onTap: () => onTapDoc(doc),
    );
  }
}

class LeaderboardUserTile extends StatelessWidget {
  final int index;
  final String name;
  final int metricValue;
  final String? photoUrl;
  final bool isMe;

  final IconData metricIcon;
  final Color metricIconColor;
  final bool shortenMetric;

  final VoidCallback onTap;

  const LeaderboardUserTile({
    super.key,
    required this.index,
    required this.name,
    required this.metricValue,
    required this.photoUrl,
    required this.isMe,
    required this.metricIcon,
    required this.metricIconColor,
    required this.shortenMetric,
    required this.onTap,
  });

  Color _rankColor(ColorScheme cs, int rankIndex) {
    final gold = Color.lerp(cs.tertiary, cs.secondary, 0.40)!;
    final silver = Color.lerp(cs.primary, cs.onSurface, 0.55)!;
    final bronze = Color.lerp(cs.secondary, cs.primary, 0.65)!;

    switch (rankIndex) {
      case 0:
        return gold;
      case 1:
        return silver;
      case 2:
        return bronze;
      default:
        return cs.primary;
    }
  }

  String _shortenCount(int value) {
    if (value < 1000) return value.toString();
    if (value < 10000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value < 1000000) return "${(value / 1000).floor()}k";
    if (value < 10000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    return "${(value / 1000000).floor()}M";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final isDark = brightness == Brightness.dark;

    final rank = index + 1;
    final rankColor = _rankColor(cs, index);

    // -------------------------------
    // BACKGROUND HIERARCHY (NO BORDERS)
    // -------------------------------
    final baseTile = cs.surfaceContainerHigh;

    // ✅ Branded light-purple highlight for user tile
    final meTile = isLight
        ? Color.alphaBlend(
      cs.primary.withOpacity(0.18),
      cs.surfaceContainerHighest,
    )
        : Color.alphaBlend(
      cs.primary.withOpacity(0.22),
      cs.surfaceContainerHigh,
    );

    final tileColor = isMe ? meTile : baseTile;

    final displayMetric =
    shortenMetric ? _shortenCount(metricValue) : "$metricValue";

    return AnimatedScale(
      scale: isMe ? 1.025 : 1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(18),
              // ❌ NO borders / outlines
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(
                    isMe ? (isLight ? 0.18 : 0.28) : (isDark ? 0.24 : 0.10),
                  ),
                  blurRadius: isMe ? 22 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // ✅ Left brand accent stripe (main differentiator)
                if (isMe)
                  Positioned(
                    left: 0,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(left: isMe ? 10 : 0),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rankColor.withOpacity(isDark ? 0.16 : 0.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "$rank",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        backgroundImage:
                        (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Name + YOU badge
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (isMe)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "YOU",
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Metric
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(metricIcon, size: 20, color: metricIconColor),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 72),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                displayMetric,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Centered dialog (not bottom sheet)
class _CenteredUserDialog extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final int trophies;
  final int streakDays;

  const _CenteredUserDialog({
    required this.fullName,
    required this.photoUrl,
    required this.trophies,
    required this.streakDays,
  });

  String _shortenCount(int value) {
    if (value < 1000) return value.toString();
    if (value < 10000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value < 1000000) return "${(value / 1000).floor()}k";
    if (value < 10000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    return "${(value / 1000000).floor()}M";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.scrim.withOpacity(0.35),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? Text(
                          fullName.isNotEmpty
                              ? fullName[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: cs.onSurface.withOpacity(0.75),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Trophies",
                          value: _shortenCount(trophies),
                          icon: Icons.emoji_events_rounded,
                          iconColor: cs.tertiary,
                          bg: cs.tertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: "Streak",
                          value: "$streakDays",
                          icon: Icons.local_fire_department_rounded,
                          iconColor: cs.secondary,
                          bg: cs.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.50)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.70),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
