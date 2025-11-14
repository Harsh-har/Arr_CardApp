import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../All_Rooms_Access/Room_Access/Card_Rooms_Access.dart';
import '../Scenes/Active_Provider.dart';
import 'Provider_Loader.dart';

class CardBaseScreen extends StatefulWidget {
  const CardBaseScreen({super.key});

  @override
  State<CardBaseScreen> createState() => _CardBaseScreenState();
}

class _CardBaseScreenState extends State<CardBaseScreen>  with TickerProviderStateMixin  {
  List<String> _rooms = [];
  final ScrollController _scrollController = ScrollController();
  bool _showDownArrow = false;
  bool _arrowBouncing = true;
  late AnimationController _floorController;


  @override
  void initState() {
    super.initState();
    _initProviderRooms();
    _scrollController.addListener(_updateArrowVisibility);
    _floorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _initProviderRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRooms = prefs.getStringList('main_rooms') ?? [];

    final roomsProvider = Provider.of<ProviderLoader>(context, listen: false);
    roomsProvider.setRooms(savedRooms);

    setState(() {
      _rooms = savedRooms;
    });

    // Update arrow visibility after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _updateArrowVisibility());
  }

  Future<void> _saveRooms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('main_rooms', _rooms);
  }

  Future<void> _deleteRoom(String room) async {
    setState(() {
      _rooms.remove(room);
    });
    await _saveRooms();

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _updateArrowVisibility());
  }

  void _showAddRoomDialog() {
    final roomController = TextEditingController();
    final topicController = TextEditingController();
    String? warningMessage;

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  backgroundColor: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.meeting_room, color: Colors.tealAccent),
                      SizedBox(width: 8),
                      Text("Add Room", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Room Name
                        TextField(
                          controller: roomController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.home, color: Colors.tealAccent),
                            hintText: "Enter room name",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            final newRoom = value.trim();
                            setDialogState(() {
                              warningMessage = newRoom.isNotEmpty &&
                                  _rooms.contains(newRoom)
                                  ? "Room '$newRoom' already exists!"
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Base Topic (single input)
                        TextField(
                          controller: topicController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.topic, color: Colors.orangeAccent),
                            hintText: "Enter Topic",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        if (warningMessage != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                  Icons.warning, color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  warningMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                          "Cancel", style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final newRoom = roomController.text.trim();
                        final baseTopic = topicController.text.trim();

                        if (newRoom.isEmpty || _rooms.contains(newRoom)) return;
                        if (baseTopic.isEmpty) return;

                        // ✅ Auto-append /in and /out
                        final pub = "$baseTopic/in";
                        final sub = "$baseTopic/out";

                        setState(() => _rooms.add(newRoom));
                        await _saveRooms();

                        // 🔹 Save topics globally
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString("saved_topic_$newRoom", pub);
                        await prefs.setStringList(
                            "saved_topics_$newRoom", [pub]);

                        await prefs.setString(
                            "saved_subscribeTopic_$newRoom", sub);
                        await prefs.setStringList(
                            "saved_subscribeTopics_$newRoom", [sub]);

                        WidgetsBinding.instance.addPostFrameCallback((_) =>
                            _updateArrowVisibility());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Create"),
                    ),
                  ],
                ),
          ),
    );
  }

  void _openAllRoomAccess(BuildContext context, String roomName) {
    final roomProvider = Provider.of<ActiveRoomProvider>(
        context, listen: false);
    roomProvider.setActiveRoom(roomName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CardRoomsAccess(
              roomName: roomName,
              appBarTitle: roomName,
            ),
      ),
    );
  }

  Future<void> _handleLongPress(String roomName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Delete Room",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Are you sure you want to delete '$roomName'?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      _deleteRoom(roomName);
    }
  }

  void _updateArrowVisibility() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final shouldShow = maxScroll > 0 && currentScroll < maxScroll;

    if (_showDownArrow != shouldShow) {
      setState(() {
        _showDownArrow = shouldShow;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final roomsProvider = context.watch<ProviderLoader>();
    final roomProvider = context.watch<ActiveRoomProvider>();
    _rooms = roomsProvider.rooms;

    final List<String> favorites = [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Area",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: _showAddRoomDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
         _buildMainBody(favorites, roomProvider),
        ],
      ),
    );
  }

  Widget _buildMainBody(List<String> favorites, ActiveRoomProvider roomProvider) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 27.0, right: 10,left: 10, top: 5),
          child: GridView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final roomName = _rooms[index];
              final isActive = roomProvider.activeRoom == roomName;

              return GestureDetector(
                onTap: () {
                  final isActive = roomProvider.activeRoom == roomName;
                  roomProvider.setActiveRoom(isActive ? null : roomName);
                },
                onDoubleTap: () => _openAllRoomAccess(context, roomName),
                onLongPress: () => _handleLongPress(roomName),
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive ? Colors.blueAccent : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_rooms.isNotEmpty && _showDownArrow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _arrowBouncing ? 0 : 8, // start vertical offset
                  end: _arrowBouncing ? 8 : 0,   // end vertical offset
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                onEnd: () {
                  if (_rooms.isNotEmpty && _showDownArrow) {
                    setState(() {
                      _arrowBouncing = !_arrowBouncing; // reverse direction
                    });
                  }
                },
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 35,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}


