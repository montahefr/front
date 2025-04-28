import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeWeather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  String cityName = 'Paris';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  final TextEditingController _cityController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cityController.text = cityName;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    fetchWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true;
      _animationController.reset();
    });

    try {
      final data = await _weatherService.getWeather(cityName);
      setState(() {
        weatherData = data;
      });
      _animationController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching weather: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildCurrentWeather() {
    if (weatherData == null || weatherData!['list'].isEmpty) {
      return const SizedBox();
    }

    final current = weatherData!['list'][0];
    final temp = current['main']['temp'].toStringAsFixed(1);
    final tempValue = current['main']['temp'];
    final weatherMain = current['weather'][0]['main'];
    final icon = current['weather'][0]['icon'];
    final humidity = current['main']['humidity'];
    final windSpeed = current['wind']['speed'];
    final feelsLike = current['main']['feels_like'].toStringAsFixed(1);

    // Temperature status for bees
    String tempStatus;
    Color statusColor;
    IconData statusIcon;
    
    if (tempValue > 35) {
      tempStatus = 'Dangerous for bees!';
      statusColor = Colors.red[400]!;
      statusIcon = Icons.warning_rounded;
    } else if (tempValue > 30) {
      tempStatus = 'Hot for bees';
      statusColor = Colors.orange[400]!;
      statusIcon = Icons.whatshot_rounded;
    } else if (tempValue < 10) {
      tempStatus = 'Too cold for bees';
      statusColor = Colors.blue[400]!;
      statusIcon = Icons.ac_unit_rounded;
    } else {
      tempStatus = 'Ideal for bees';
      statusColor = Colors.green[400]!;
      statusIcon = Icons.check_circle_rounded;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade50,
              Colors.amber.shade100.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cityName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.location_on_rounded, color: Colors.amber[700]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/$icon@2x.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.cloud_rounded,
                    size: 80,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        height: 0.9,
                      ),
                    ),
                    Text(
                      'Feels like $feelsLike°',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weatherMain,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    tempStatus,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherInfo('Humidity', '$humidity%', Icons.water_drop_rounded),
                _buildWeatherInfo('Wind', '${windSpeed.toStringAsFixed(1)} m/s', Icons.air_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withOpacity(0.1),
          ),
          child: Icon(icon, size: 24, color: Colors.amber[700]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

 Widget _buildForecastItem(String date, String temp, String weather, String icon, double tempValue) {
  // Determine temperature status for bees
  String tempStatus;
  Color statusColor;
  IconData statusIcon;
  
  if (tempValue > 35) {
    tempStatus = 'Dangerous for bees! 🚨';
    statusColor = Colors.red[400]!;
    statusIcon = Icons.warning_rounded;
  } else if (tempValue > 30) {
    tempStatus = 'Hot for bees 🔥';
    statusColor = Colors.orange[400]!;
    statusIcon = Icons.whatshot_rounded;
  } else if (tempValue < 10) {
    tempStatus = 'Too cold for bees ❄️';
    statusColor = Colors.blue[400]!;
    statusIcon = Icons.ac_unit_rounded;
  } else {
    tempStatus = 'Ideal for bees ✅';
    statusColor = Colors.green[400]!;
    statusIcon = Icons.check_circle_rounded;
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$temp°C',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/$icon.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.cloud_rounded,
                size: 30,
                color: Colors.amber[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                weather,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tempStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildForecastList() {
  if (weatherData == null) {
    return const SizedBox();
  }

  final forecasts = weatherData!['list'];
  final dailyForecasts = <String, List<dynamic>>{};

  for (var forecast in forecasts) {
    final date = forecast['dt_txt'].split(' ')[0];
    if (!dailyForecasts.containsKey(date)) {
      dailyForecasts[date] = [];
    }
    dailyForecasts[date]!.add(forecast);
  }

  final today = forecasts[0]['dt_txt'].split(' ')[0];
  dailyForecasts.remove(today);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          '5-Day Bee Safety Forecast',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      ...dailyForecasts.entries.map((entry) {
        final date = entry.key;
        final dayForecasts = entry.value;
        final dayTemp = dayForecasts[0]['main']['temp'].toStringAsFixed(1);
        final tempValue = dayForecasts[0]['main']['temp'];
        final weatherMain = dayForecasts[0]['weather'][0]['main'];
        final icon = dayForecasts[0]['weather'][0]['icon'];

        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildForecastItem(date, dayTemp, weatherMain, icon, tempValue),
        );
      }).toList(),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BeeWeather'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: Colors.amber[700]),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Search City',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            hintText: 'Enter city name',
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                cityName = _cityController.text;
                              });
                              fetchWeather();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator.adaptive(
              color: Colors.amber[700],
              onRefresh: () async {
                fetchWeather();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCurrentWeather(),
                    _buildForecastList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}