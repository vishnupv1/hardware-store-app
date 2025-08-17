import 'package:flutter/material.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/breadcrumb.dart';
import '../../../../core/theme/app_colors.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({Key? key}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Employee> employees = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  bool hasMoreData = true;
  final TextEditingController searchController = TextEditingController();
  String? selectedDepartment;
  String? selectedRole;
  bool? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        hasMoreData = true;
      });
    }

    if (!hasMoreData && !refresh) return;

    setState(() {
      if (refresh) {
        isLoading = true;
        employees.clear();
      }
      errorMessage = null;
    });

    try {
      final response = await apiService.getEmployees(
        page: currentPage,
        search: searchController.text.isNotEmpty ? searchController.text : null,
        department: selectedDepartment,
        role: selectedRole,
        isActive: selectedStatus,
      );

      if (response['success']) {
        final List<dynamic> data = response['data']['docs'] ?? [];
        final newEmployees = data.map((json) => Employee.fromJson(json)).toList();

        setState(() {
          if (refresh) {
            employees = newEmployees;
          } else {
            employees.addAll(newEmployees);
          }
          hasMoreData = newEmployees.length == 20; // Assuming page size is 20
          if (hasMoreData) currentPage++;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load employees';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please check your connection.';
        isLoading = false;
      });
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Employee Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', employee.fullName),
              _buildDetailRow('Employee ID', employee.employeeId),
              _buildDetailRow('Email', employee.email),
              _buildDetailRow('Department', employee.department),
              _buildDetailRow('Position', employee.position),
              _buildDetailRow('Role', employee.role),
              _buildDetailRow('Hire Date', _formatDate(employee.hireDate)),
              _buildDetailRow('Years of Service', '${employee.yearsOfService} years'),
              if (employee.salary != null)
                _buildDetailRow('Salary', '₹${employee.salary!.toStringAsFixed(2)}'),
              _buildDetailRow('Status', employee.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Phone', employee.phoneNumber ?? 'Not provided'),
              const SizedBox(height: 16),
              const Text(
                'Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: employee.permissions.map((permission) {
                  return Chip(
                    label: Text(permission.replaceAll('_', ' ')),
                                                                      backgroundColor: AppColors.primary500.withOpacity(0.1),
                                                  labelStyle: TextStyle(color: AppColors.primary500),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Employee Management',
            showBackButton: true,
          ),
          Breadcrumb(
            items: [
              BreadcrumbItem(label: 'Admin'),
              BreadcrumbItem(label: 'Employees'),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search and Filter Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search employees...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onSubmitted: (_) => _loadEmployees(refresh: true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _loadEmployees(refresh: true),
                                icon: const Icon(Icons.search),
                                label: const Text('Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary500,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDepartment,
                                  decoration: InputDecoration(
                                    labelText: 'Department',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All Departments'),
                                    ),
                                    ...['Sales', 'Marketing', 'IT', 'HR', 'Finance', 'Operations']
                                        .map((dept) => DropdownMenuItem(
                                              value: dept,
                                              child: Text(dept),
                                            ))
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDepartment = value;
                                    });
                                    _loadEmployees(refresh: true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Role',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All Roles'),
                                    ),
                                    ...['employee', 'supervisor', 'manager', 'admin']
                                        .map((role) => DropdownMenuItem(
                                              value: role,
                                              child: Text(role.toUpperCase()),
                                            ))
                                        .toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value;
                                    });
                                    _loadEmployees(refresh: true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<bool>(
                                  value: selectedStatus,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All Status'),
                                    ),
                                    const DropdownMenuItem(
                                      value: true,
                                      child: Text('Active'),
                                    ),
                                    const DropdownMenuItem(
                                      value: false,
                                      child: Text('Inactive'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value;
                                    });
                                    _loadEmployees(refresh: true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Employees List
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: AppColors.error500,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      errorMessage!,
                                      style: TextStyle(color: AppColors.error500),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _loadEmployees(refresh: true),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : employees.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No employees found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => _loadEmployees(refresh: true),
                                    child: ListView.builder(
                                      itemCount: employees.length + (hasMoreData ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == employees.length) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        final employee = employees[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                                                                         leading: CircleAvatar(
                                               backgroundColor: AppColors.primary500,
                                               child: Text(
                                                employee.firstName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              employee.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${employee.employeeId} • ${employee.department}'),
                                                Text('${employee.position} • ${employee.role.toUpperCase()}'),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: employee.isActive
                                                        ? Colors.green.withOpacity(0.1)
                                                        : Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    employee.isActive ? 'Active' : 'Inactive',
                                                    style: TextStyle(
                                                      color: employee.isActive
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () => _showEmployeeDetails(employee),
                                                  icon: const Icon(Icons.info_outline),
                                                ),
                                              ],
                                            ),
                                            onTap: () => _showEmployeeDetails(employee),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add employee page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Employee functionality coming soon!')),
          );
        },
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
