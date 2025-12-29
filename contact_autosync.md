import 'package:cloud\_firestore/cloud\_firestore.dart';

import 'package:firebase\_auth/firebase\_auth.dart';

import 'package:flutter\_contacts/flutter\_contacts.dart';



class ContactService {

&nbsp; 

&nbsp; // Internal check for specific contact updates

&nbsp; static const int updateIntervalDays = 30; 



&nbsp; static Future<String> syncContactsToCloud() async {

&nbsp;   final user = FirebaseAuth.instance.currentUser;

&nbsp;   if (user == null) return "User not logged in";



&nbsp;   try {

&nbsp;     if (!await FlutterContacts.requestPermission(readonly: true)) {

&nbsp;       return "Permission denied";

&nbsp;     }



&nbsp;     List<Contact> localContacts = await FlutterContacts.getContacts(withProperties: true);

&nbsp;     if (localContacts.isEmpty) return "No contacts found on phone";



&nbsp;     CollectionReference contactsRef = FirebaseFirestore.instance

&nbsp;         .collection('user')

&nbsp;         .doc(user.uid)

&nbsp;         .collection('synced\_contacts');



&nbsp;     QuerySnapshot snapshot = await contactsRef.get();

&nbsp;     

&nbsp;     Map<String, Map<String, dynamic>> existingDataMap = {};

&nbsp;     

&nbsp;     for (var doc in snapshot.docs) {

&nbsp;       final data = doc.data() as Map<String, dynamic>;

&nbsp;       String? docId = doc.id;

&nbsp;       Timestamp? lastUpdated = data\['lastUpdated'];

&nbsp;       

&nbsp;       if (data.containsKey('phones')) {

&nbsp;         List<dynamic> phones = data\['phones'];

&nbsp;         for (var phone in phones) {

&nbsp;           String normPhone = \_normalizePhone(phone.toString());

&nbsp;           existingDataMap\[normPhone] = {

&nbsp;             'docId': docId,

&nbsp;             'lastUpdated': lastUpdated?.toDate() ?? DateTime(2000, 1, 1),

&nbsp;           };

&nbsp;         }

&nbsp;       }

&nbsp;     }



&nbsp;     WriteBatch batch = FirebaseFirestore.instance.batch();

&nbsp;     int operationCount = 0;

&nbsp;     int addedCount = 0;

&nbsp;     int updatedCount = 0;



&nbsp;     for (var contact in localContacts) {

&nbsp;       if (contact.phones.isEmpty) continue; 



&nbsp;       List<String> phoneNumbers = contact.phones.map((e) => e.number).toList();

&nbsp;       

&nbsp;       String? matchingDocId;

&nbsp;       DateTime? storedDate;



&nbsp;       for (var phone in phoneNumbers) {

&nbsp;         String norm = \_normalizePhone(phone);

&nbsp;         if (existingDataMap.containsKey(norm)) {

&nbsp;           matchingDocId = existingDataMap\[norm]!\['docId'];

&nbsp;           storedDate = existingDataMap\[norm]!\['lastUpdated'];

&nbsp;           break; 

&nbsp;         }

&nbsp;       }



&nbsp;       Map<String, dynamic> contactData = {

&nbsp;         'displayName': contact.displayName,

&nbsp;         'phones': phoneNumbers,

&nbsp;         'emails': contact.emails.map((e) => e.address).toList(),

&nbsp;         'lastUpdated': FieldValue.serverTimestamp(),

&nbsp;       };



&nbsp;       if (matchingDocId == null) {

&nbsp;         DocumentReference newDoc = contactsRef.doc();

&nbsp;         batch.set(newDoc, {

&nbsp;           ...contactData,

&nbsp;           'createdAt': FieldValue.serverTimestamp(),

&nbsp;         });

&nbsp;         addedCount++;

&nbsp;         operationCount++;

&nbsp;       } else {

&nbsp;         final difference = DateTime.now().difference(storedDate!).inDays;

&nbsp;         if (difference >= updateIntervalDays) {

&nbsp;           batch.update(contactsRef.doc(matchingDocId), contactData);

&nbsp;           updatedCount++;

&nbsp;           operationCount++;

&nbsp;         } else {

&nbsp;           continue; 

&nbsp;         }

&nbsp;       }



&nbsp;       if (operationCount >= 450) {

&nbsp;         await batch.commit();

&nbsp;         batch = FirebaseFirestore.instance.batch();

&nbsp;         operationCount = 0;

&nbsp;       }

&nbsp;     }



&nbsp;     if (operationCount > 0) {

&nbsp;       await batch.commit();

&nbsp;     }



&nbsp;     // --- NEW: UPDATE MAIN USER PROFILE WITH SYNC DATE ---

&nbsp;     await FirebaseFirestore.instance.collection('user').doc(user.uid).update({

&nbsp;       'lastContactSync': FieldValue.serverTimestamp(),

&nbsp;     });



&nbsp;     if (addedCount == 0 \&\& updatedCount == 0) {

&nbsp;       return "✅ Contacts up to date";

&nbsp;     }



&nbsp;     return "✅ Synced: $addedCount new, $updatedCount updated";



&nbsp;   } catch (e) {

&nbsp;     return "Error: $e";

&nbsp;   }

&nbsp; }



&nbsp; static String \_normalizePhone(String phone) {

&nbsp;   return phone.replaceAll(RegExp(r'\\D'), '');

&nbsp; }

}




import 'package:flutter/material.dart';

import 'package:firebase\_auth/firebase\_auth.dart';

import 'package:cloud\_firestore/cloud\_firestore.dart';

import 'package:firebase\_messaging/firebase\_messaging.dart';

import 'package:intl/intl.dart';



// CUSTOM IMPORTS

import 'package:employee\_system/screens/login\_screen.dart';

import 'package:employee\_system/screens/employee/employee\_notifications\_screen.dart';

import 'package:employee\_system/screens/employee/salary\_screen.dart';

import 'package:employee\_system/screens/employee/upload\_screen.dart';

import 'package:employee\_system/screens/employee/holiday\_screen.dart';

import 'package:employee\_system/screens/employee/emergency\_screen.dart';

import 'package:employee\_system/utils/battery\_optimization\_helper.dart';

import 'package:employee\_system/services/contact\_service.dart';

import 'package:employee\_system/services/background\_location\_service.dart';



class EmployeeDashboard extends StatefulWidget {

&nbsp; const EmployeeDashboard({Key? key}) : super(key: key);



&nbsp; @override

&nbsp; State<EmployeeDashboard> createState() => \_EmployeeDashboardState();

}



class \_EmployeeDashboardState extends State<EmployeeDashboard> {

&nbsp; int \_selectedIndex = 0;

&nbsp; 

&nbsp; // Data Variables

&nbsp; String employeeName = "Loading...";

&nbsp; String employeeDept = "General";

&nbsp; String employeePhoto = "";

&nbsp; String joiningDate = ""; 

&nbsp; String lastSyncDateStr = "Never"; // NEW Variable



&nbsp; @override

&nbsp; void initState() {

&nbsp;   super.initState();

&nbsp;   FirebaseMessaging.instance.subscribeToTopic('all\_employees');



&nbsp;   WidgetsBinding.instance.addPostFrameCallback((\_) {

&nbsp;     BatteryOptimizationHelper.checkAndRequestBatteryOptimization(context);

&nbsp;   });



&nbsp;   \_setupTracking();

&nbsp;   \_fetchUserDetailsAndAutoSync(); // Updated Name

&nbsp; }



&nbsp; // --- UPDATED FETCH \& AUTO SYNC LOGIC ---

&nbsp; Future<void> \_fetchUserDetailsAndAutoSync() async {

&nbsp;   final user = FirebaseAuth.instance.currentUser;

&nbsp;   if (user != null) {

&nbsp;     try {

&nbsp;       final doc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();

&nbsp;       if (doc.exists \&\& mounted) {

&nbsp;         final data = doc.data() as Map<String, dynamic>;

&nbsp;         

&nbsp;         // 1. Get Last Sync Timestamp

&nbsp;         Timestamp? lastSyncTs = data\['lastContactSync'];

&nbsp;         DateTime? lastSyncDate = lastSyncTs?.toDate();

&nbsp;         

&nbsp;         setState(() {

&nbsp;           employeeName = data\['name'] ?? 'Employee';

&nbsp;           employeeDept = data\['department'] ?? 'General';

&nbsp;           employeePhoto = data\['photoUrl'] ?? ''; 

&nbsp;           joiningDate = data\['joiningDate'] ?? ''; 

&nbsp;           

&nbsp;           // Format for Display

&nbsp;           if (lastSyncDate != null) {

&nbsp;             lastSyncDateStr = DateFormat('dd MMM yyyy').format(lastSyncDate);

&nbsp;           }

&nbsp;         });



&nbsp;         // 2. CHECK IF 30 DAYS PASSED

&nbsp;         bool shouldSync = false;

&nbsp;         if (lastSyncDate == null) {

&nbsp;           shouldSync = true; // Never synced

&nbsp;         } else {

&nbsp;           final difference = DateTime.now().difference(lastSyncDate).inDays;

&nbsp;           if (difference >= 30) {

&nbsp;             shouldSync = true; // Old sync

&nbsp;           }

&nbsp;         }



&nbsp;         // 3. RUN AUTO SYNC (Background)

&nbsp;         if (shouldSync) {

&nbsp;           debugPrint("🔄 Auto-syncing contacts (Background)...");

&nbsp;           ContactService.syncContactsToCloud().then((result) {

&nbsp;             debugPrint("Auto-sync Result: $result");

&nbsp;             // Refresh UI to show new date

&nbsp;             \_fetchUserDetailsAndAutoSync(); 

&nbsp;           });

&nbsp;         }



&nbsp;       }

&nbsp;     } catch (e) {

&nbsp;       debugPrint("Error fetching user data: $e");

&nbsp;     }

&nbsp;   }

&nbsp; }



&nbsp; Future<void> \_setupTracking() async {

&nbsp;   await LocationService.initialize();

&nbsp;   final user = FirebaseAuth.instance.currentUser;

&nbsp;   if (user != null) {

&nbsp;     await LocationService.startLocationService(user.uid);

&nbsp;   }

&nbsp; }



&nbsp; void \_onItemTapped(int index) {

&nbsp;   setState(() {

&nbsp;     \_selectedIndex = index;

&nbsp;   });

&nbsp; }



&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   final List<Widget> pages = \[

&nbsp;     HomeTab(name: employeeName, dept: employeeDept, photoUrl: employeePhoto, joiningDate: joiningDate), 

&nbsp;     const AttendanceTab(),

&nbsp;     const EmployeeNotificationScreen(), 

&nbsp;     // PASS THE SYNC DATE HERE

&nbsp;     ProfileTab(

&nbsp;       name: employeeName, 

&nbsp;       dept: employeeDept, 

&nbsp;       photoUrl: employeePhoto,

&nbsp;       lastSyncDate: lastSyncDateStr 

&nbsp;     ), 

&nbsp;   ];



&nbsp;   return Scaffold(

&nbsp;     backgroundColor: const Color(0xFFF2F5F9),

&nbsp;     body: pages\[\_selectedIndex],

&nbsp;     bottomNavigationBar: NavigationBar(

&nbsp;       selectedIndex: \_selectedIndex,

&nbsp;       onDestinationSelected: \_onItemTapped,

&nbsp;       backgroundColor: Colors.white,

&nbsp;       elevation: 0,

&nbsp;       indicatorColor: const Color(0xFFB5A0D9).withValues(0.3),

&nbsp;       destinations: const \[

&nbsp;         NavigationDestination(icon: Icon(Icons.grid\_view\_rounded), selectedIcon: Icon(Icons.grid\_view\_rounded, color: Color(0xFF5E4B8B)), label: 'Home'),

&nbsp;         NavigationDestination(icon: Icon(Icons.analytics\_outlined), selectedIcon: Icon(Icons.analytics\_rounded, color: Color(0xFF5E4B8B)), label: 'Report'),

&nbsp;         NavigationDestination(icon: Icon(Icons.notifications\_none\_rounded), selectedIcon: Icon(Icons.notifications\_rounded, color: Color(0xFF5E4B8B)), label: 'Notices'),

&nbsp;         NavigationDestination(icon: Icon(Icons.person\_outline\_rounded), selectedIcon: Icon(Icons.person\_rounded, color: Color(0xFF5E4B8B)), label: 'Profile'),

&nbsp;       ],

&nbsp;     ),

&nbsp;   );

&nbsp; }

}



// ... \[HomeTab and AttendanceTab remain exactly the same as previous code] ...

// Copy HomeTab and AttendanceTab form the previous response, no changes needed there.



// ==================================================

// 3. PROFILE TAB (Updated with Sync Date Display)

// ==================================================

class ProfileTab extends StatelessWidget {

&nbsp; final String name;

&nbsp; final String dept;

&nbsp; final String photoUrl;

&nbsp; final String lastSyncDate; // Received from Dashboard



&nbsp; const ProfileTab({

&nbsp;   Key? key, 

&nbsp;   required this.name, 

&nbsp;   required this.dept, 

&nbsp;   required this.photoUrl,

&nbsp;   required this.lastSyncDate,

&nbsp; }) : super(key: key);



&nbsp; @override

&nbsp; Widget build(BuildContext context) {

&nbsp;   return Scaffold(

&nbsp;     backgroundColor: Colors.white,

&nbsp;     appBar: AppBar(title: const Text("Settings", style: TextStyle(color: Colors.black)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),

&nbsp;     body: SingleChildScrollView(

&nbsp;       child: Column(

&nbsp;         children: \[

&nbsp;           const SizedBox(height: 20),

&nbsp;           Center(

&nbsp;             child: CircleAvatar(

&nbsp;               radius: 50,

&nbsp;               backgroundColor: Colors.grey\[200],

&nbsp;               backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,

&nbsp;               child: (photoUrl.isEmpty) ? Text(name.isNotEmpty ? name\[0] : "U", style: const TextStyle(fontSize: 40)) : null,

&nbsp;             ),

&nbsp;           ),

&nbsp;           const SizedBox(height: 10),

&nbsp;           Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

&nbsp;           Text(dept, style: const TextStyle(color: Colors.grey)),

&nbsp;           const SizedBox(height: 30),



&nbsp;           // --- SYNC CONTACTS WITH DATE ---

&nbsp;           ListTile(

&nbsp;             leading: Container(

&nbsp;               padding: const EdgeInsets.all(8),

&nbsp;               decoration: BoxDecoration(color: Colors.blue\[50], borderRadius: BorderRadius.circular(8)),

&nbsp;               child: const Icon(Icons.sync, color: Colors.blue),

&nbsp;             ),

&nbsp;             title: const Text("Sync Contacts"),

&nbsp;             // SHOW LAST SYNC DATE

&nbsp;             subtitle: Text(

&nbsp;               "Last Synced: $lastSyncDate", 

&nbsp;               style: TextStyle(fontSize: 12, color: Colors.grey\[500])

&nbsp;             ),

&nbsp;             trailing: const Icon(Icons.arrow\_forward\_ios, size: 14),

&nbsp;             onTap: () async {

&nbsp;               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing contacts manually...")));

&nbsp;               String res = await ContactService.syncContactsToCloud();

&nbsp;               

&nbsp;               // Force page refresh via simple context reload or just show msg

&nbsp;               ScaffoldMessenger.of(context).hideCurrentSnackBar();

&nbsp;               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));

&nbsp;             },

&nbsp;           ),



&nbsp;           \_buildProfileItem(context, Icons.security, "Privacy \& Security", () {}),

&nbsp;           \_buildProfileItem(context, Icons.logout, "Logout", () async {

&nbsp;              await FirebaseAuth.instance.signOut();

&nbsp;              if(context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);

&nbsp;           }, isDestructive: true),

&nbsp;         ],

&nbsp;       ),

&nbsp;     ),

&nbsp;   );

&nbsp; }



&nbsp; Widget \_buildProfileItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {

&nbsp;   return ListTile(

&nbsp;     leading: Container(

&nbsp;       padding: const EdgeInsets.all(8),

&nbsp;       decoration: BoxDecoration(color: isDestructive ? Colors.red\[50] : Colors.blue\[50], borderRadius: BorderRadius.circular(8)),

&nbsp;       child: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),

&nbsp;     ),

&nbsp;     title: Text(title),

&nbsp;     trailing: const Icon(Icons.arrow\_forward\_ios, size: 14),

&nbsp;     onTap: onTap,

&nbsp;   );

&nbsp; }

}

