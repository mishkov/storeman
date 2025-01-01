import 'package:flutter/material.dart';
import 'package:storeman/clean_flutter_projects/clean_flutter_projects_page.dart';
import 'package:storeman/space_usage/space_usage_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_selectedPage) {
            0 => 'Space Usage',
            1 => 'Flutter Clean',
            _ => 'StoreMan',
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('StoreMan'),
            ),
            ListTile(
              title: const Text('Home'),
              selected: _selectedPage == 0,
              onTap: () {
                setState(() {
                  _selectedPage = 0;
                });

                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Flutter Clean'),
              selected: _selectedPage == 1,
              onTap: () {
                setState(() {
                  _selectedPage = 1;
                });

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: [
          SpaceUsage(),
          CleanFlutterProjectsPage(),
        ][_selectedPage],
      ),
    );
  }
}
