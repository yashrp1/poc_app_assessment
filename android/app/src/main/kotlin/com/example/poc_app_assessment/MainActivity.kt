package com.example.poc_app_assessment

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.sql.Connection
import java.sql.DriverManager
import java.sql.PreparedStatement
import java.sql.SQLException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.poc_app_assessment/employees"
    private val job = Job()
    private val uiScope = CoroutineScope(Dispatchers.Main + job)

    // Database connection details
    private val jdbcUrl = "jdbc:jtds:sqlserver://65.1.22.155:1433;databaseName=dev-db"
    private val username = "test"
    private val password = "Test@12345678"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "Application started")

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "fetchEmployees" -> fetchEmployees(result)
                "addEmployee" -> {
                    val employeeJson = call.arguments as Map<*, *>
                    addEmployee(employeeJson, result)
                }
                "updateEmployee" -> {
                    val employeeJson = call.arguments as Map<*, *>
                    updateEmployee(employeeJson, result)
                }
                else -> {
                    Log.d("MainActivity", "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        job.cancel()
    }

    private fun getConnection(): Connection? {
        return try {
            // Load the JDBC driver
            Class.forName("net.sourceforge.jtds.jdbc.Driver")
            // Establish and return the connection
            DriverManager.getConnection(jdbcUrl, username, password)
        } catch (e: ClassNotFoundException) {
            Log.e("DatabaseError", "JDBC Driver not found: ${e.message}", e)
            null
        } catch (e: SQLException) {
            Log.e("DatabaseError", "Error connecting to the database: ${e.message}", e)
            null
        }
    }

    private fun fetchEmployees(result: MethodChannel.Result) {
        uiScope.launch {
            val employees = withContext(Dispatchers.IO) { fetchEmployeeData() }
            if (employees != null) {
                Log.d("MainActivity", "Successfully fetched employee data: $employees")
                result.success(employees)
            } else {
                Log.e("MainActivity", "Failed to fetch employee data")
                result.error("UNAVAILABLE", "Employee data not available.", null)
            }
        }
    }

    private suspend fun fetchEmployeeData(): String? {
        var connection: Connection? = null
        val jsonArray = JSONArray()

        return try {
            Log.d("Database", "Attempting to connect to the database...")
            connection = getConnection()
            if (connection == null) return null

            Log.d("Database", "Connected to the database.")

            val statement = connection.createStatement()
            val query = "SELECT * FROM employees"
            Log.d("Database", "Executing query: $query")
            val resultSet = statement.executeQuery(query)

            resultSet.use {
                while (it.next()) {
                    val jsonObject = JSONObject()
                    for (i in 1..it.metaData.columnCount) {
                        val columnName = it.metaData.getColumnName(i)
                        val columnValue = it.getString(i)
                        jsonObject.put(columnName, columnValue)
                    }
                    jsonArray.put(jsonObject)
                }
            }

            jsonArray.toString()
        } catch (e: Exception) {
            Log.e("DatabaseError", "Error fetching employee data: ${e.message}", e)
            null
        } finally {
            try {
                connection?.close()
                Log.d("Database", "Database resources closed.")
            } catch (e: Exception) {
                Log.e("DatabaseError", "Error closing resources: ${e.message}", e)
            }
        }
    }

    private fun addEmployee(employeeJson: Map<*, *>, result: MethodChannel.Result) {
        uiScope.launch {
            withContext(Dispatchers.IO) {
                var connection: Connection? = null
                try {
                    connection = getConnection()
                    if (connection != null) {
                        val query = "INSERT INTO employees (EmployeeID, FirstName, LastName, DepartmentID, Salary, HireDate) VALUES (?, ?, ?, ?, ?, ?)"
                        val statement: PreparedStatement = connection.prepareStatement(query)
                        statement.setString(1, employeeJson["EmployeeID"] as String)
                        statement.setString(2, employeeJson["FirstName"] as String)
                        statement.setString(3, employeeJson["LastName"] as String)
                        statement.setString(4, employeeJson["DepartmentID"] as String)
                        statement.setString(5, employeeJson["Salary"] as String)
                        statement.setString(6, employeeJson["HireDate"] as String)
                        statement.executeUpdate()

                        result.success("Employee added successfully")
                    } else {
                        result.error("ERROR", "Failed to connect to the database", null)
                    }
                } catch (e: Exception) {
                    Log.e("DatabaseError", "Failed to add employee: ${e.message}", e)
                    result.error("ERROR", "Failed to add employee", null)
                } finally {
                    connection?.close()
                }
            }
        }
    }

    private fun updateEmployee(employeeJson: Map<*, *>, result: MethodChannel.Result) {
        uiScope.launch {
            withContext(Dispatchers.IO) {
                var connection: Connection? = null
                try {
                    connection = getConnection()
                    if (connection != null) {
                        val query = "UPDATE employees SET FirstName = ?, LastName = ?, DepartmentID = ?, Salary = ?, HireDate = ? WHERE EmployeeID = ?"
                        val statement: PreparedStatement = connection.prepareStatement(query)
                        statement.setString(1, employeeJson["FirstName"] as String)
                        statement.setString(2, employeeJson["LastName"] as String)
                        statement.setString(3, employeeJson["DepartmentID"] as String)
                        statement.setString(4, employeeJson["Salary"] as String)
                        statement.setString(5, employeeJson["HireDate"] as String)
                        statement.setString(6, employeeJson["EmployeeID"] as String)
                        statement.executeUpdate()

                        result.success("Employee updated successfully")
                    } else {
                        result.error("ERROR", "Failed to connect to the database", null)
                    }
                } catch (e: Exception) {
                    Log.e("DatabaseError", "Failed to update employee: ${e.message}", e)
                    result.error("ERROR", "Failed to update employee", null)
                } finally {
                    connection?.close()
                }
            }
        }
    }
}
