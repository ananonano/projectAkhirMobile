import 'package:flutter/material.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_drawer.dart';

class AdminDatabaseScreen extends StatefulWidget {
  const AdminDatabaseScreen({super.key});

  @override
  State<AdminDatabaseScreen> createState() => _AdminDatabaseScreenState();
}

class _AdminDatabaseScreenState extends State<AdminDatabaseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _columns = [];
  bool _isLoading = true;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
      );
      
      final tables = result.map((row) => row['name'] as String).toList();
      
      if (mounted) {
        setState(() {
          _tables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Database] Error loading tables: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _selectedTable = tableName;
      _isLoadingData = true;
      _tableData = [];
      _columns = [];
    });

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get table info for columns
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final columns = tableInfo.map((col) => col['name'] as String).toList();
      
      // Get all data from table
      final data = await db.query(tableName);
      
      if (mounted) {
        setState(() {
          _columns = columns;
          _tableData = data;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('[Database] Error loading table data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTableCard(String tableName) {
    final isSelected = _selectedTable == tableName;
    
    return GestureDetector(
      onTap: () => _loadTableData(tableName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE8E8E4),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.table_chart_rounded,
              size: 20,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tableName,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF1A1C1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAF5),
      drawer: AdminDrawer(
        activeMenu: AdminMenuIndex.database,
        scaffoldKey: _scaffoldKey,
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tables section
                        const Text(
                          'Database Tables',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_tables.length} tables available',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 13,
                            color: Color(0xFF78716C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Table list
                        ...(_tables.map((table) => _buildTableCard(table))),
                        
                        const SizedBox(height: 24),
                        
                        // Table data section
                        if (_selectedTable != null) ...[
                          const Divider(height: 32),
                          Row(
                            children: [
                              const Icon(
                                Icons.storage_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTable!,
                                style: const TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1C1A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_tableData.length} rows',
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isLoadingData)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          else if (_tableData.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox_rounded,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tabel kosong',
                                      style: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE8E8E4),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.primary.withValues(alpha: 0.1),
                                  ),
                                  columnSpacing: 24,
                                  horizontalMargin: 16,
                                  columns: _columns.map((col) {
                                    return DataColumn(
                                      label: Text(
                                        col,
                                        style: const TextStyle(
                                          fontFamily: 'Lexend',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  rows: _tableData.map((row) {
                                    return DataRow(
                                      cells: _columns.map((col) {
                                        final value = row[col];
                                        String displayValue = value?.toString() ?? 'NULL';
                                        
                                        // Truncate long text
                                        if (displayValue.length > 50) {
                                          displayValue = '${displayValue.substring(0, 47)}...';
                                        }
                                        
                                        return DataCell(
                                          Text(
                                            displayValue,
                                            style: TextStyle(
                                              fontFamily: 'Lexend',
                                              fontSize: 11,
                                              color: value == null
                                                  ? Colors.grey
                                                  : const Color(0xFF1A1C1A),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
          ),
          
          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBar(
              title: 'Database Viewer',
              scaffoldKey: _scaffoldKey,
            ),
          ),
        ],
      ),
    );
  }
}

