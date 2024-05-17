import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Rx<String> debugData = ''.obs;
String dataToSend = "";
Rx<bool> isDeviceConnected = false.obs;
Rx<String> courses = ''.obs;

String selectedOption = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    var response = await http.get(Uri.parse('http://192.168.4.1/public'));
    if (response.statusCode == 200) {
      isDeviceConnected.value = true;
    } else {
      isDeviceConnected.value = false;
    }
    print("Connected: " + response.body);
    // TODO: Connect to device
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'Blue Sensor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
        ),
        home: const Splash());
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Home())));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Attendee", style: TextStyle(fontSize: 24)),
          SizedBox(
            height: 30,
          ),
          CircularProgressIndicator()
        ],
      )),
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    () async {
      GetCourses(courses);
      //TODO: Read Courses
    }();
    return Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0), // Decreased padding
              child: Obx(
                () => SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Obx(() {
                            String status = isDeviceConnected.value
                                ? "Connected"
                                : "Not Connected";
                            return Text("WIFI STATUS\n$status",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w600, // Decreased font size
                                    color: isDeviceConnected.value
                                        ? Colors.green
                                        : Colors.red));
                          }),
                          const Spacer(),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                Future<void> requestStoragePermission() async {
                                  // Check if permission is granted
                                  PermissionStatus status =
                                      await Permission.storage.request();

                                  // Handle the result
                                  if (status.isGranted) {
                                    Get.snackbar("Permission Granted",
                                        "You can save the files",
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 2));
                                  } else {
                                    Get.snackbar("Storage Permission Needed",
                                        "You cannot save any files",
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 2));
                                  }
                                }

                                requestStoragePermission();

                                var response = await http.get(
                                    Uri.parse('http://192.168.4.1/public'));
                                if (response.statusCode == 200) {
                                  isDeviceConnected.value = true;
                                  GetCourses(courses);
                                } else {
                                  isDeviceConnected.value = false;
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh),
                                  SizedBox(width: 8),
                                  Text('Refresh')
                                ],
                              )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      isDeviceConnected.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Add a new course",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Container(),
                      const SizedBox(height: 10),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width -
                                      70 -
                                      40,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Course Name',
                                    ),
                                    onChanged: (value) {
                                      dataToSend = value;
                                    },
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 70,
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        if (dataToSend.isNotEmpty) {
                                          if (await writeData(
                                              "/data/${dataToSend.replaceAll(' ', '_')}.txt")) {
                                            Get.snackbar("Success",
                                                "Course has been added successfully! It may take some time to appear in the list",
                                                snackPosition:
                                                    SnackPosition.BOTTOM,
                                                backgroundColor: Colors.green,
                                                colorText: Colors.white,
                                                duration:
                                                    const Duration(seconds: 2));
                                          } else {
                                            Get.snackbar("Error",
                                                "Please Check Your Connection. Please tap the reset button on the ESP32 device",
                                                snackPosition:
                                                    SnackPosition.BOTTOM,
                                                backgroundColor: Colors.red,
                                                colorText: Colors.white,
                                                duration:
                                                    const Duration(seconds: 2));
                                          }
                                        }
                                      },
                                      child: const Text('Add')),
                                ),
                                const Spacer(),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 30,
                      ),
                      isDeviceConnected.value
                          ? Row(
                              children: [
                                const Text(
                                  "List of courses",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                    onTap: () => GetCourses(courses),
                                    child: const Icon(Icons.refresh_sharp)),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 20,
                      ),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final List<String> dropdownOptions =
                                      courses.value.split("\n").toList();
                                  if (dropdownOptions.isNotEmpty) {
                                    dropdownOptions.removeLast();
                                    dropdownOptions.removeLast();
                                    if (!dropdownOptions
                                        .contains(selectedOption)) {
                                      selectedOption = '';
                                    }
                                  } else {
                                    return const Text("Nothing to Delete");
                                  }
                                  List<DropdownMenuItem<String>> dropdownItems =
                                      [];

                                  for (String option in dropdownOptions) {
                                    if (option.isNotEmpty ||
                                        option.length > 3) {
                                      dropdownItems
                                          .add(DropdownMenuItem<String>(
                                        value: option,
                                        child: Text(option),
                                      ));
                                    }
                                  }

                                  if (dropdownOptions.isNotEmpty) {
                                    return SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          40,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              counterText: "",
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16.0,
                                                      horizontal: 20.0),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              // Add more decoration..
                                            ),
                                            items: dropdownItems,
                                            hint: Text(
                                              'Select a Course',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    Theme.of(context).hintColor,
                                              ),
                                            ),
                                            value: selectedOption == ''
                                                ? null
                                                : selectedOption,
                                            onChanged: (String? value) {
                                              selectedOption = value!;
                                              courses.refresh();
                                            }),
                                      ),
                                    );
                                  } else {
                                    return const Text("Nothing to Delete");
                                  }
                                }),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 20,
                      ),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.green),
                                    ),
                                    onPressed: () {
                                      if (selectedOption != '') {
                                        SetCourse(selectedOption);
                                      }
                                    },
                                    child: const Text('Set As Current Course')),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        width: 10,
                      ),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.deepOrange),
                                    ),
                                    onPressed: () {
                                      if (selectedOption != '') {
                                        GetCurrentCourse();
                                      }
                                    },
                                    child: const Text('Check Current Course')),
                              ],
                            )
                          : Container(),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 75,
                                  child: ElevatedButton(
                                      onPressed: () {
                                        if (selectedOption != '') {
                                          ReadCourse(selectedOption);
                                        }
                                      },
                                      child: const Text('Read')),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.black),
                                    ),
                                    onPressed: () {
                                      syncCourses();
                                    },
                                    child: const Text('Sync Data')),
                              ],
                            )
                          : Container(),
                      isDeviceConnected.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(Colors.red),
                                    ),
                                    onPressed: () {
                                      if (selectedOption != '') {
                                        delData(selectedOption);
                                      }
                                    },
                                    child: const Text('Delete')),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 10,
                      ),
                      Obx(() => Text(debugData.value))
                    ],
                  ),
                ),
              ))),
    );
  }
}

writeData(String s) async {
  var response = await http.get(Uri.parse('http://192.168.4.1/write?$s@'));
  if (response.statusCode != 200) {
    return;
  }

  GetCourses(courses);
}

delData(String s) async {
  var response = await http.get(Uri.parse('http://192.168.4.1/del?$s@'));
  if (response.statusCode != 200) {
    return;
  }

  GetCourses(courses);

  Get.snackbar("Deleted", "Data has been deleted",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2));
}

void GetCourses(Rx<String> courses) async {
  var response = await http.get(Uri.parse('http://192.168.4.1/list_course'));
  if (response.statusCode != 200) {
    return;
  }
  courses.value = response.body.toString();
}

void ReadCourse(String coursename) async {
  var response =
      await http.get(Uri.parse('http://192.168.4.1/read?$coursename@'));
  if (response.statusCode != 200) {
    return;
  }
  showTextFile(response.body.substring(9));
}

void SetCourse(String coursename) async {
  String currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  // ignore: prefer_interpolation_to_compose_strings
  String urlString = "http://192.168.4.1/setcourse?/data/" +
      coursename +
      "\$\$\$" +
      currentDate +
      "@";
  var response = await http.get(Uri.parse(urlString));
  if (response.statusCode != 200) {
    return;
  }
  showTextFile(response.body);
  Get.snackbar("Success", "set as current successfully",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2));
}

void GetCurrentCourse() async {
  String urlString = "http://192.168.4.1/checkcurrent";
  var response = await http.get(Uri.parse(urlString));
  if (response.statusCode != 200) {
    return;
  }
  showTextFile(response.body);
}

void syncCourses() async {
  var response = await http.get(Uri.parse('http://192.168.4.1/sync'));
  if (response.statusCode != 200) {
    return;
  }
  String showingValue = response.body.substring(4);
  showTextFile(showingValue.replaceAll('@@@', '\n'));
}

bool isModalOpen = false;
Future<dynamic> showTextFile(String text) {
  isModalOpen = true;
  return showDialog(
    barrierDismissible: false,
    context: Get.context!,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Text File"),
              const SizedBox(height: 10),
              Text(text),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              isModalOpen = false;
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              isModalOpen = false;
              saveToFile("Attendee.txt", text);
            },
            child: const Text('Download'),
          ),
        ],
      );
    },
  );
}

Future<void> saveToFile(String fileName, String content) async {
  Directory directory = await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/$fileName';

  // Write the file.
  File file = File(filePath);
  await file.writeAsString(content);

  // Show a dialog to confirm the file has been saved.
  showDialog(
    context: Get.context!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('File Saved'),
        content: Text('File saved to $filePath'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
            },
            child: const Text('Do not Remove Content'),
          ),
          TextButton(
            onPressed: () async {
              var response =
                  await http.get(Uri.parse('http://192.168.4.1/delall'));
              Navigator.of(context).pop();
            },
            child: const Text('Remove Content'),
          ),
        ],
      );
    },
  );
}
