import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';

class TableCard extends StatelessWidget {
  final TableItem table;
  final VoidCallback onTap;

  const TableCard({
    Key? key,
    required this.table,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: table.isActive 
                ? Color(AppConstants.primaryColorValue) 
                : Color(AppConstants.primaryColorValue),
            width: table.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (table.isActive && table.orderAmount.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '₺${table.orderAmount}',
                  style: TextStyle(
                    color: Color(AppConstants.primaryColorValue),
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