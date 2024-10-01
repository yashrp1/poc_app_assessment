import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'employee_model.dart';
import 'package:flutter/services.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  EmployeeScreenState createState() => EmployeeScreenState();
}

class EmployeeScreenState extends State<EmployeeScreen> {
  List<Employee> employees = [];
  static const platform =
      MethodChannel('com.example.poc_app_assessment/employees');

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final String result = await platform.invokeMethod('fetchEmployees');
      final List<dynamic> employeeList = json.decode(result);
      setState(() {
        employees = employeeList
            .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Failed to fetch employees: $e");
      }
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      int newEmployeeID = employees.isNotEmpty
          ? employees
                  .map((e) => int.parse(e.employeeID))
                  .reduce((a, b) => a > b ? a : b) +
              1
          : 1; // Start from 1 if no employees exist

      employee.employeeID = newEmployeeID.toString(); // Set the new employee ID

      await platform.invokeMethod('addEmployee', employee.toJson());
      fetchEmployees(); // Refresh employee list
    } catch (e) {
      if (kDebugMode) {
        print("Failed to add employee: $e");
      }
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    try {
      await platform.invokeMethod('updateEmployee', employee.toJson());
      fetchEmployees(); // Refresh employee list
    } catch (e) {
      if (kDebugMode) {
        print("Failed to update employee: $e");
      }
    }
  }

  void _showEditDialog(Employee employee) {
    TextEditingController firstNameController =
        TextEditingController(text: employee.firstName);
    TextEditingController lastNameController =
        TextEditingController(text: employee.lastName);
    TextEditingController departmentIDController =
        TextEditingController(text: employee.departmentID);
    TextEditingController salaryController =
        TextEditingController(text: employee.salary);
    TextEditingController hireDateController =
        TextEditingController(text: employee.hireDate);

    Future<void> selectHireDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000), // Set a reasonable starting year
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != DateTime.now()) {
        hireDateController.text =
            "${picked.toLocal()}".split(' ')[0]; // Format to yyyy-MM-dd
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: departmentIDController,
                  decoration: const InputDecoration(labelText: 'Department ID'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: salaryController,
                  decoration: const InputDecoration(labelText: 'Salary'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: hireDateController,
                  decoration: const InputDecoration(labelText: 'Hire Date'),
                  readOnly: true, // Prevent manual input
                  onTap: () =>
                      selectHireDate(context), // Show date picker on tap
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                employee.firstName = firstNameController.text;
                employee.lastName = lastNameController.text;
                employee.departmentID = departmentIDController.text;
                employee.salary = salaryController.text;
                employee.hireDate = hireDateController.text;

                updateEmployee(employee);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Records'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Enable vertical scrolling
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Employee ID')),
                    DataColumn(label: Text('First Name')),
                    DataColumn(label: Text('Last Name')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Salary')),
                    DataColumn(label: Text('Edit')),
                  ],
                  rows: employees.map((employee) {
                    return DataRow(cells: [
                      DataCell(Text(employee.employeeID)),
                      DataCell(Text(employee.firstName)),
                      DataCell(Text(employee.lastName)),
                      DataCell(Text(employee.departmentID)),
                      DataCell(Text(employee.salary)),
                      DataCell(IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(employee);
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.blue; // Color when pressed
                  }
                  return Colors.blueAccent; // Default color
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                 
                  return Colors.black; // Default color
                },
              ),
            ),
            onPressed: () {
              _showAddEmployeeDialog();
            },
            child: const Text('Add Employee'),
          ),
          const SizedBox(height: 5,)
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    TextEditingController firstNameController = TextEditingController();
    TextEditingController lastNameController = TextEditingController();
    TextEditingController departmentIDController = TextEditingController();
    TextEditingController salaryController = TextEditingController();
    TextEditingController hireDateController = TextEditingController();

    Future<void> selectHireDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000), // Set a reasonable starting year
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != DateTime.now()) {
        hireDateController.text =
            "${picked.toLocal()}".split(' ')[0]; // Format to yyyy-MM-dd
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: departmentIDController,
                  decoration: const InputDecoration(labelText: 'Department ID'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: salaryController,
                  decoration: const InputDecoration(labelText: 'Salary'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: hireDateController,
                  decoration: const InputDecoration(labelText: 'Hire Date'),
                  readOnly: true, // Prevent manual input
                  onTap: () =>
                      selectHireDate(context), // Show date picker on tap
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                addEmployee(Employee(
                  employeeID: DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  departmentID: departmentIDController.text,
                  salary: salaryController.text,
                  hireDate: hireDateController.text,
                ));
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
