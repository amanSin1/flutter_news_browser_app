import 'package:flutter/material.dart';
import 'package:flutter_browser/main.dart';
import 'package:flutter_browser/rss_news/graphqlQueries/getFeeds/fetch_feeds.dart';
import 'package:hive/hive.dart';

class SourcesSelectionScreen extends StatefulWidget {
  const SourcesSelectionScreen({Key? key});

  @override
  State<SourcesSelectionScreen> createState() => _SourcesSelectionScreenState();
}

class _SourcesSelectionScreenState extends State<SourcesSelectionScreen> {
  final FetchFeeds _fetchFeeds = FetchFeeds();
  String selectedCategory = "";

  List<String> allSources = [];
  List<String> selectedSources = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedCategories();
  }

  Future<void> _loadSelectedCategories() async {
    setState(() {
      _isLoading = true;
    });
    final box = Hive.box<List<String>>('preferences');
    final languages = box.get('selectedLanguages');
    final categories = box.get('selectedCategories');
    if (languages != null && categories != null) {
      final sourceFeeds =
          await _fetchFeeds.feedsBySelectedCategories(languages, categories);
      final sources = sourceFeeds.map((feed) => feed.source).toSet().toList();
      setState(() {
        allSources = sources;
        selectedSources = box.get('selectedSources') ?? [];
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _saveSelectedSources() async {
    if (selectedSources.isNotEmpty) {
      final box = Hive.box<List<String>>('preferences');
      box.put('selectedSources', selectedSources);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const FlutterBrowserApp(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.lightBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Sources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: allSources.map((source) {
                          return CheckboxListTile(
                            title: Text(
                              source,
                              style: const TextStyle(fontSize: 18),
                            ),
                            value: selectedSources.contains(source),
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  if (value) {
                                    selectedSources.add(source);
                                  } else {
                                    selectedSources.remove(source);
                                  }
                                });
                              }
                            },
                            activeColor: Colors.lightBlue,
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSelectedSources,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.lightBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
