import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic> data = {};

//  @override
//  void initState() {
//    super.initState();
//  }

  @override
  Widget build(BuildContext context) {
    final routeData = ModalRoute.of(context)?.settings.arguments;
    if (data.isEmpty && routeData is Map) {
      data = Map<String, dynamic>.from(routeData);
    }

    final bool isDaytime = data['isDaytime'] == true;

    // set background image
    String bgImage = isDaytime ? 'day.png' : 'night.png';
    Color bgColor = isDaytime ? Colors.blue : Colors.indigo.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('World Time'),
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage('assets/$bgImage'),
            fit: BoxFit.cover,
          )),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 120.0, 0, 0),
            child: Column(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () async {
                    final result =
                        await Navigator.pushNamed(context, '/location');
                    if (result is Map) {
                      setState(() {
                        data = <String, dynamic>{
                          'time': result['time'],
                          'location': result['location'],
                          'isDaytime': result['isDaytime'],
                          'flag': result['flag']
                        };
                      });
                    }
                  },
                  icon: Icon(
                    Icons.edit_location,
                    color: Colors.grey[300],
                  ),
                  label: Text(
                    'Edit Location',
                    style: TextStyle(
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${data['location'] ?? ''}',
                      style: TextStyle(
                        fontSize: 28.0,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                Text('${data['time'] ?? ''}',
                    style: TextStyle(fontSize: 66.0, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: isDaytime ? null : Colors.black54,
        selectedItemColor: isDaytime ? null : Colors.white,
        unselectedItemColor: isDaytime ? null : Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Stopwatch',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/stopwatch',
              arguments: data,
            );
          }
        },
      ),
    );
  }
}
