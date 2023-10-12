import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
//import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
              child: Text(
            'DiagnoTech',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          )),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(),
            FundusScreen(),
            lung_colonScreen(),
            AlzheimerScreen(),
          ],
        ),
        drawer: NavigationDrawer(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          unselectedItemColor: Colors.grey, // Set color for unselected icons
          selectedItemColor: Colors.blue, // Set color for selected icon
          selectedLabelStyle:
              TextStyle(color: Colors.blue), // Set color for selected label
          unselectedLabelStyle:
              TextStyle(color: Colors.grey), // Set color for unselected label
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye),
              label: 'Fundus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science),
              label: 'Lung/Colon Cancer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Alzheimer',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Image.asset('assets/DiagnoTech Logo.jpg'),
          ),
        ],
      ),
    );
  }
}

class FundusScreen extends StatefulWidget {
  @override
  _FundusScreenState createState() => _FundusScreenState();
}

class _FundusScreenState extends State<FundusScreen> {
  bool _isLoading = false;
  String _prediction = '';
  double _confidence = 0.0;
  File? _selectedImage;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _sexController = TextEditingController();
  // Add name controller

  final _databaseHelper = DatabaseHelper();

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict/fundus');

    try {
      final List<int> imageBytes = _selectedImage!.readAsBytesSync();

      final response = await http.post(
        apiUrl,
        body: jsonEncode({'image_bytes': base64Encode(imageBytes)}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction = data['predicted_class'];
          _confidence = data['confidence'];
          final name = _nameController.text;
          final age = int.parse(_ageController.text);
          final sex = _sexController.text; // Get the user's name
          _databaseHelper.insertData(name, age, sex, _prediction, _confidence);
        });
      } else {
        throw Exception('Failed to make a prediction.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _prediction = '';
        _confidence; // Clear any previous prediction.
      });
    }
  }

  Future<void> _navigateToHistoryPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Fundus Image Classifier',
            style: TextStyle(
              fontSize: 24, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _navigateToHistoryPage(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
                width: 100,
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Age'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _sexController,
                  decoration: InputDecoration(labelText: 'Sex'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 200,
                  width: 200,
                )
              else
                const Text('No image selected.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _makePrediction();
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('Get Prediction'),
              ),
              const SizedBox(height: 20),
              Container(
                //widget shown according to the state
                child: Center(
                  child: !_isLoading
                      ? Text(
                          'Prediction: $_prediction \nConfidence level: $_confidence')
                      : const CircularProgressIndicator(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DatabaseHelper {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      final dbPath = await getDatabasesPath();
      //final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(dbPath, 'Fundus_v2.db');

      _database = await openDatabase(
        databasePath,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE predictions(id INTEGER PRIMARY KEY, name TEXT, age INTEGER, sex TEXT, prediction TEXT, confidence REAL)',
          );
        },
        version: 1,
      );
    }
  }

  Future<void> insertData(String name, int age, String sex, String prediction,
      double confidence) async {
    final db = await database;
    await db.insert(
      'predictions',
      {
        'name': name,
        'age': age,
        'sex': sex,
        'prediction': prediction,
        'confidence': confidence
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database;
    return db.query('predictions');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<Database> get database async {
    if (_database == null) {
      await initializeDatabase();
    }
    return _database!;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('predictions');
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _databaseHelper = DatabaseHelper();

  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final history = await _databaseHelper.getPredictions();
    setState(() {
      _historyData = history;
    });
  }

  void _clearHistory() async {
    final databaseHelper = DatabaseHelper();
    await databaseHelper.clearDatabase();
    _loadHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final prediction = _historyData[index];
          return Container(
            width: 200,
            height: 150,
            child: ListTile(
              title: Text('Name: ${prediction['name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Age: ${prediction['age']}'),
                  Text('Sex: ${prediction['sex']}'),
                  Text('Prediction: ${prediction['prediction']}'),
                  Text('Confidence level: ${prediction['confidence']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class lung_colonScreen extends StatefulWidget {
  _lung_colonScreenState createState() => _lung_colonScreenState();
}

class _lung_colonScreenState extends State<lung_colonScreen> {
  bool _isLoading = false;
  String _prediction1 = '';
  double _confidence1 = 0.0;

  File? _selectedImage;
  TextEditingController _nameController =
      TextEditingController(); // Add name controller

  final _databaseHelperX = DatabaseHelperX();

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict/lungcolon');

    try {
      final List<int> imageBytes = _selectedImage!.readAsBytesSync();

      final response = await http.post(
        apiUrl,
        body: jsonEncode({'image_bytes': base64Encode(imageBytes)}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction1 = data['predicted_class'];
          _confidence1 = data['confidence'];
          final name = _nameController.text; // Get the user's name
          _databaseHelperX.insertData(name, _prediction1, _confidence1);
        });
      } else {
        throw Exception('Failed to make a prediction.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _prediction1 = '';
        _confidence1;
      });
    }
  }

  Future<void> _navigateToHistoryPageX(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPageX()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Lung/Colon Cancer Image Classifier',
            style: TextStyle(
              fontSize: 25, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              _navigateToHistoryPageX(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
              width: 100,
            ),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                width: 200,
              )
            else
              const Text('No image selected.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                await _makePrediction();
                setState(() {
                  _isLoading = false;
                });
              },
              child: const Text('Get Prediction'),
            ),
            const SizedBox(height: 20),
            Container(
              //widget shown according to the state
              child: Center(
                child: !_isLoading
                    ? Text(
                        'Prediction: $_prediction1 \nConfidence level: $_confidence1')
                    : const CircularProgressIndicator(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DatabaseHelperX {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      final dbPath = await getDatabasesPath();
      //final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(dbPath, 'lung_colon.db');

      _database = await openDatabase(
        databasePath,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE predictions(id INTEGER PRIMARY KEY, name TEXT, prediction TEXT, confidence REAL)',
          );
        },
        version: 1,
      );
    }
  }

  Future<void> insertData(
      String name, String prediction, double confidence) async {
    final db = await database;
    await db.insert(
      'predictions',
      {'name': name, 'prediction': prediction, 'confidence': confidence},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database;
    return db.query('predictions');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<Database> get database async {
    if (_database == null) {
      await initializeDatabase();
    }
    return _database!;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('predictions');
  }
}

class HistoryPageX extends StatefulWidget {
  @override
  _HistoryPageStateX createState() => _HistoryPageStateX();
}

class _HistoryPageStateX extends State<HistoryPageX> {
  final _databaseHelperX = DatabaseHelperX();

  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final history = await _databaseHelperX.getPredictions();
    setState(() {
      _historyData = history;
    });
  }

  void _clearHistory() async {
    final databaseHelperX = DatabaseHelperX();
    await databaseHelperX.clearDatabase();
    _loadHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final prediction = _historyData[index];
          return ListTile(
            title: Text('Name: ${prediction['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prediction: ${prediction['prediction']}'),
                Text('Confidence level: ${prediction['confidence']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AlzheimerScreen extends StatefulWidget {
  @override
  _AlzheimerScreenState createState() => _AlzheimerScreenState();
}

class _AlzheimerScreenState extends State<AlzheimerScreen> {
  bool _isLoading = false;
  String _prediction = '';
  double _confidence = 0.0;
  File? _selectedImage;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _sexController =
      TextEditingController(); // Add name controller

  final _databaseHelperA = DatabaseHelperA();

  Future<void> _makePrediction() async {
    if (_selectedImage == null) {
      print('No image selected.');
      return;
    }

    final apiUrl = Uri.parse('http://127.0.0.1:5000/predict/alzheimer');

    try {
      final List<int> imageBytes = _selectedImage!.readAsBytesSync();

      final response = await http.post(
        apiUrl,
        body: jsonEncode({'image_bytes': base64Encode(imageBytes)}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction = data['predicted_class'];
          _confidence = data['confidence'];
          final name = _nameController.text; // Get the user's name
          final age = int.parse(_ageController.text);
          final sex = _sexController.text; // Get the user's name
          _databaseHelperA.insertData(name, age, sex, _prediction, _confidence);
        });
      } else {
        throw Exception('Failed to make a prediction.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _prediction = '';
        _confidence; // Clear any previous prediction.
      });
    }
  }

  Future<void> _navigateToHistoryPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPageA()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Alzheimer Classifier',
            style: TextStyle(
              fontSize: 24, // Set your desired font size
              fontWeight: FontWeight.bold, // You can customize the style
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _navigateToHistoryPage(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
                width: 100,
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Age'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _sexController,
                  decoration: InputDecoration(labelText: 'Sex'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 20),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 200,
                  width: 200,
                )
              else
                const Text('No image selected.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _makePrediction();
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('Get Prediction'),
              ),
              const SizedBox(height: 20),
              Container(
                //widget shown according to the state
                child: Center(
                  child: !_isLoading
                      ? Text(
                          'Prediction: $_prediction \nConfidence level: $_confidence')
                      : const CircularProgressIndicator(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DatabaseHelperA {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database == null) {
      final dbPath = await getDatabasesPath();
      //final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(dbPath, 'Alzheimer_v2.db');

      _database = await openDatabase(
        databasePath,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE predictions(id INTEGER PRIMARY KEY, name TEXT, age INTEGER, sex TEXT, prediction TEXT, confidence REAL)',
          );
        },
        version: 1,
      );
    }
  }

  Future<void> insertData(String name, int age, String sex, String prediction,
      double confidence) async {
    final db = await database;
    await db.insert(
      'predictions',
      {
        'name': name,
        'age': age,
        'sex': sex,
        'prediction': prediction,
        'confidence': confidence
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database;
    return db.query('predictions');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<Database> get database async {
    if (_database == null) {
      await initializeDatabase();
    }
    return _database!;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('predictions');
  }
}

class HistoryPageA extends StatefulWidget {
  @override
  _HistoryPageStateA createState() => _HistoryPageStateA();
}

class _HistoryPageStateA extends State<HistoryPageA> {
  final _databaseHelperA = DatabaseHelperA();

  List<Map<String, dynamic>> _historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final history = await _databaseHelperA.getPredictions();
    setState(() {
      _historyData = history;
    });
  }

  void _clearHistory() async {
    final databaseHelperA = DatabaseHelperA();
    await databaseHelperA.clearDatabase();
    _loadHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final prediction = _historyData[index];
          return Container(
            width: 200,
            height: 150,
            child: ListTile(
              title: Text('Name: ${prediction['name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Age: ${prediction['age']}'),
                  Text('Sex: ${prediction['sex']}'),
                  Text('Prediction: ${prediction['prediction']}'),
                  Text('Confidence level: ${prediction['confidence']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavigationDrawer extends StatefulWidget {
  @override
  _NavigationDrawerScreen createState() => _NavigationDrawerScreen();
}

class _NavigationDrawerScreen extends State<NavigationDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'More',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutAppPage()),
              );
              // Navigate to the about page or perform an action.
              // Add your code here.
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutHelpPage()),
              );
              // Navigate to the help page or perform an action.
              // Add your code here.
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('References'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutReferencePage()),
              );
              // Navigate to the references page or perform an action.
              // Add your code here.
            },
          ),
        ],
      ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'DiagnoTech',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Version: 1.0.0',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "\n\nThe 'DiagnoTech' app is a powerful tool for doctors, leveraging advanced machine learning algorithms\n to analyze patient data, medical images, and symptoms. It aids in the rapid and accurate\nidentification of diseases, providing real-time diagnostic insights, treatment recommendations, \nand relevant medical literature, enhancing clinical decision-making and patient care.",
              style: TextStyle(
                fontSize: 18, // Set your desired font size
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Our Incredible Team:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Abhay Lejith',
              style: TextStyle(
                fontSize: 18, // Set your desired font size
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                "Shreesha M",
                style: TextStyle(
                  fontSize: 18, // Set your desired font size
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutHelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
              text: const TextSpan(
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  children: [
                TextSpan(
                    text: "For more help, contact us at:\n",
                    style: TextStyle(fontSize: 18)),
                TextSpan(
                    text: "abhaylejith@gmail.com\nshreesha2k22@yahoo.com",
                    style: TextStyle(fontSize: 14))
              ]))
        ]),
      ),
    );
  }
}

class AboutReferencePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('References'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
                text: const TextSpan(
                    style: TextStyle(
                        color: Color.fromARGB(
                            255, 0, 0, 0)), //style for all textspan
                    children: [
                  TextSpan(
                      text: "Datasets:\n\n",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: "1)Fundus images\n",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "Cen, LP., Ji, J., Lin, JW. et al. Automatic detection of 39 fundus diseases and conditions in retinal photographs using deep neural networks. Nat Commun 12, 4828 (2021). https://doi.org/10.1038/s41467-021-25138-w\n",
                      style: TextStyle(fontSize: 16)),
                  TextSpan(
                      text: "2)Lung/Colon Cancer histopathological images\n",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "Borkowski AA, Bui MM, Thomas LB, Wilson CP, DeLand LA, Mastorides SM. Lung and Colon Cancer Histopathological Image Dataset (LC25000). arXiv:1912.12142v1 [eess.IV], 2019\n",
                      style: TextStyle(fontSize: 16)),
                  TextSpan(
                      text: "3)Alzheimer's brain MRI images \n",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "https://www.kaggle.com/datasets/tourist55/alzheimers-dataset-4-class-of-images/data\n\n",
                      style: TextStyle(fontSize: 16)),
                  TextSpan(
                      text: "Others:\n\n",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "1)Code referred to for fundus and lung/colon cancer model\n",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "https://www.kaggle.com/code/tenebris97/lung-colon-all-5-classes-efficientnetb7-98\n",
                      style: TextStyle(fontSize: 16)),
                  TextSpan(
                      text:
                          "2)Google Teachable Machine for alzheimer's model\n",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: "https://teachablemachine.withgoogle.com/\n",
                      style: TextStyle(fontSize: 16)),
                ]))
          ],
        ),
      ),
    );
  }
}
