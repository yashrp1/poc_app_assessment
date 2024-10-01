class Employee {
   dynamic employeeID;
   String firstName;
   String lastName;
   String departmentID;
   String salary;
   String hireDate;

  Employee({
    required this.employeeID,
    required this.firstName,
    required this.lastName,
    required this.departmentID,
    required this.salary,
    required this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeID: json['EmployeeID'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      departmentID: json['DepartmentID'],
      salary: json['Salary'],
      hireDate: json['HireDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmployeeID': employeeID,
      'FirstName': firstName,
      'LastName': lastName,
      'DepartmentID': departmentID,
      'Salary': salary,
      'HireDate': hireDate,
    };
  }
}
