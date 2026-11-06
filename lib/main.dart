import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MovaApp());
}

const Color navy = Color(0xFF101B2D);
const Color green = Color(0xFF20C997);
const Color background = Color(0xFFF4F6F9);

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOVA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFavorites =
        prefs.getStringList('favorite_buses') ?? [];

    final savedName =
        prefs.getString('user_name') ?? 'Пользователь MOVA';

    final savedPhone =
        prefs.getString('user_phone') ?? '';

    final savedNotifications =
        prefs.getBool('notifications_enabled') ?? true;

    if (!mounted) return;

    setState(() {
      favoriteBusNumbers = savedFavorites.toSet();
      userName = savedName;
      userPhone = savedPhone;
      notificationsEnabled = savedNotifications;
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favorite_buses',
      favoriteBusNumbers.toList(),
    );

    await prefs.setString('user_name', userName);
    await prefs.setString('user_phone', userPhone);

    await prefs.setBool(
      'notifications_enabled',
      notificationsEnabled,
    );
  }
  String search = '';
  String fromLocation = '';
  String toLocation = '';
  bool routeSearched = false;
  List<Map<String, dynamic>> suitableBuses = [];
  Set<String> favoriteBusNumbers = {};
  String userName = 'Пользователь MOVA';
  String userPhone = '';
  bool notificationsEnabled = true;

  final List<Map<String, dynamic>> buses = [
    {
      'number': '8',
      'destination': 'Аламедин-1 — Ошский рынок',
      'time': '3 мин',
      'status': 'Свободно',
      'level': 1,
      'color': const Color(0xFF20B989),
    },
    {
      'number': '42',
      'destination': 'Джал — Восток-5',
      'time': '6 мин',
      'status': 'Средняя',
      'level': 2,
      'color': const Color(0xFFF3B94E),
    },
    {
      'number': '7',
      'destination': 'Микрорайон — Филармония',
      'time': '9 мин',
      'status': 'Переполнен',
      'level': 3,
      'color': const Color(0xFFE76B6B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: selectedTab == 0 ? _buildHome() : _buildOtherPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: navy,
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Твой город. Твой маршрут.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Уведомления',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 55,
                              color: green,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'У вас пока нет уведомлений',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Закрыть',
                              style: TextStyle(color: green),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },

                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final filteredBuses = buses.where((bus) {
      final query = search.toLowerCase();
      return bus['number'].toString().contains(query) ||
          bus['destination'].toString().toLowerCase().contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: green),
              const SizedBox(width: 5),
              const Text(
                'Бишкек, Кыргызстан',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ДЕМО',
                  style: TextStyle(
                    color: Color(0xFF138D69),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          _buildMap(),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                'Ближайший транспорт',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredBuses.length} маршрута',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Остановка: Площадь Ала-Тоо',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 13),
          if (filteredBuses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Ничего не найдено')),
            ),
          ...filteredBuses.map((bus) => _buildBusCard(bus)),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  void _showBusDetails(Map<String, dynamic> bus) {
    final int level = bus['level'];

    final int occupancy = level == 1
        ? 30
        : level == 2
            ? 65
            : 95;

    final String freeSeats = level == 1
        ? 'Много'
        : level == 2
            ? 'Несколько'
            : 'Почти нет';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Автобус №${bus['number']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bus['destination'],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Загруженность автобуса',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: occupancy / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bus['color'],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$occupancy% занято',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _detailRow(
                Icons.access_time,
                'До прибытия',
                bus['time'],
              ),
              _detailRow(
                Icons.event_seat,
                'Свободные места',
                freeSeats,
              ),
              _detailRow(
                Icons.info_outline,
                'Источник данных',
                'Демонстрационный',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF20B989)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final query = search.trim().toLowerCase();

    final filteredBuses = buses.where((bus) {
      return bus['number'].toString().toLowerCase().contains(query) ||
          bus['destination'].toString().toLowerCase().contains(query);
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(42.8752, 74.6000),
                initialZoom: 13,
                minZoom: 11,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'kg.mova.mova',
                ),
                MarkerLayer(
                  markers: [
                    for (final bus in filteredBuses)
                      Marker(
                        point: bus['number'] == '8'
                            ? LatLng(42.8752, 74.6000)
                            : bus['number'] == '42'
                                ? LatLng(42.8705, 74.5850)
                                : LatLng(42.8820, 74.6120),
                        width: 55,
                        height: 55,
                        child: GestureDetector(
                          onTap: () {
                            _showBusDetails(bus);
                          },
                          child: _buildBusMarker(
                            bus['number'].toString(),
                            bus['number'] == '8'
                                ? green
                                : bus['number'] == '42'
                                    ? const Color(0xFFF3B94E)
                                    : const Color(0xFFE76B6B),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: green,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Бишкек',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 7,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                color: Colors.white.withOpacity(0.9),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusMarker(String number, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    final Color color = bus['color'];
    final String busNumber = bus['number'].toString();
    final bool isFavorite = favoriteBusNumbers.contains(busNumber);

    return InkWell(
      onTap: () {
        _showBusDetails(bus);
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                bus['number'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Автобус №${bus['number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bus['destination'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.people_alt, color: color, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        bus['status'],
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (isFavorite) {
                        favoriteBusNumbers.remove(busNumber);
                      } else {
                        favoriteBusNumbers.add(busNumber);
                      }
                    });

                    _saveFavorites();
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  tooltip: isFavorite
                      ? 'Убрать из избранного'
                      : 'Добавить в избранное',
                ),
                Text(
                  bus['time'],
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const Text(
                  'до прибытия',
                  style: TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уровень загруженности',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(color: Color(0xFF20B989), label: 'Свободно'),
              _LegendItem(color: Color(0xFFF3B94E), label: 'Средняя'),
              _LegendItem(color: Color(0xFFE76B6B), label: 'Много людей'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Проверяем, включена ли геолокация
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Включите геолокацию на устройстве'),
          ),
        );
        return;
      }

      // Проверяем разрешение
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет разрешения на геолокацию'),
          ),
        );
        return;
      }

      // Получаем координаты
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Записываем координаты в поле "Откуда"
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Моё местоположение';

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        address = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((item) => item != null && item.isNotEmpty).join(', ');

        if (address.isEmpty) {
          address = 'Моё местоположение';
        }
      }

      if (!mounted) return;

      setState(() {
        fromLocation = address;
        routeSearched = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Местоположение определено!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось определить местоположение: $e'),
        ),
      );
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: userName);
    final phoneController = TextEditingController(text: userPhone);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Редактировать профиль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+996',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newPhone = phoneController.text.trim();

      if (newName.isNotEmpty) {
        setState(() {
          userName = newName;
          userPhone = newPhone;
        });

        await _saveFavorites();
      }
    }

    nameController.dispose();
    phoneController.dispose();
  }

  Widget _buildOtherPage() {
    if (selectedTab == 3) {
      final favoriteBuses = buses.where((bus) {
        return favoriteBusNumbers.contains(
          bus['number'].toString(),
        );
      }).toList();

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избранное',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ваши любимые маршруты',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (favoriteBuses.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 65,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Здесь пока ничего нет',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Нажмите на сердечко у автобуса',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: favoriteBuses.map((bus) {
                    return _buildBusCard(bus);
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }
    if (selectedTab == 1) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Найти автобус или маршрут',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _buildMap(),
            ),
          ],
        ),
      );
    }

    if (selectedTab == 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Построить маршрут',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Укажите начальную и конечную точки поездки',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Поле "Откуда"
            TextField(
            controller: TextEditingController(text: fromLocation),
              onChanged: (value) {
                setState(() {
                  fromLocation = value;
                  routeSearched = false;
                });
              },
              decoration: InputDecoration(
                hintText: 'Откуда',
                prefixIcon: const Icon(
                  Icons.circle,
                  color: Color(0xFF20C997),
                  size: 18,
                ),
                suffixIcon: IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(
                    Icons.my_location,
                    color: Color(0xFF20C997),
                  ),
                  tooltip: 'Моё местоположение',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Поле "Куда"
            TextField(
              onChanged: (value) {
                setState(() {
                  toLocation = value;
                  routeSearched = false;
                });
              },
              decoration: InputDecoration(
                hintText: 'Куда',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFFE76B6B),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Кнопка поиска
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (fromLocation.trim().isEmpty ||
                      toLocation.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Укажите обе точки маршрута'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    final to = toLocation.toLowerCase().trim();

                    suitableBuses = buses.where((bus) {
                      final route =
                      bus['destination'].toString().toLowerCase();

                      return route.contains(to);
                    }).toList();

                    routeSearched = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20C997),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Найти маршрут',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (routeSearched) ...[
              const Text(
                'Подходящие маршруты',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: suitableBuses.isEmpty
                    ? const Center(
                  child: Text(
                    'Подходящие маршруты не найдены',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView(
                  children: suitableBuses.map((bus) {
                    return _buildBusCard(bus);
                  }).toList(),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.route,
                        size: 65,
                        color: Color(0xFF20C997),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Здесь появятся подходящие автобусы',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (selectedTab == 4) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Мой профиль',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Управляйте своими данными и настройками',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Личные данные',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Имя', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Номер телефона',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userPhone.isEmpty ? 'Не указан' : userPhone,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать данные'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Уведомления'),
                    subtitle: const Text(
                      'Получать уведомления приложения',
                    ),
                    activeColor: green,
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        notificationsEnabled = value;
                      });
                      _saveFavorites();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'О приложении',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'MOVA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Умный помощник для поездок по городу',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Версия 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final titles = [
      'Главная',
      'Карта',
      'Маршруты',
      'Избранное',
      'Профиль',
    ];

    final icons = [
      Icons.home_rounded,
      Icons.map_outlined,
      Icons.route,
      Icons.favorite_border,
      Icons.person_outline,
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons[selectedTab],
            size: 60,
            color: const Color(0xFF20C997),
          ),
          const SizedBox(height: 15),
          Text(
            titles[selectedTab],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Раздел находится в разработке',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    final items = [
      Icons.home_rounded,
      Icons.map_outlined,
      Icons.route,
      Icons.favorite_border,
      Icons.person_outline,
    ];

    final labels = [
      'Главная',
      'Карта',
      'Маршруты',
      'Избранное',
      'Профиль',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = selectedTab == index;

              return InkWell(
                onTap: () {
                  setState(() => selectedTab = index);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index],
                        color: selected ? green : Colors.grey,
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? green : Colors.grey,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String number;
  final Color color;

  const _MapMarker({
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5),
        ],
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: navy),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE6EDE8);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bg,
    );

    final park = Paint()..color = const Color(0xFFD0E5D1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.68,
          size.height * 0.1,
          size.width * 0.22,
          size.height * 0.35,
        ),
        const Radius.circular(18),
      ),
      park,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-20, size.height * 0.35),
      Offset(size.width + 20, size.height * 0.65),
      road,
    );

    canvas.drawLine(
      Offset(size.width * 0.25, -20),
      Offset(size.width * 0.55, size.height + 20),
      road,
    );

    canvas.drawLine(
      Offset(size.width * 0.85, -20),
      Offset(size.width * 0.65, size.height + 20),
      road,
    );

    canvas.drawLine(
      Offset(-20, size.height * 0.85),
      Offset(size.width + 20, size.height * 0.2),
      road,
    );

    final smallRoad = Paint()
      ..color = const Color(0xFFD2DCD5)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, size.height * 0.15),
      Offset(size.width, size.height * 0.15),
      smallRoad,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.95),
      Offset(size.width, size.height * 0.95),
      smallRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
