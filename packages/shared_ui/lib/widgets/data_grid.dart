import 'package:flutter/material.dart';

class DataGrid extends StatelessWidget {
  final List<String> columnHeaders;
  final List<String> rowHeaders;
  final Widget Function(BuildContext context, int row, int col) cellBuilder;
  final double cellWidth;
  final double cellHeight;
  final double headerWidth;
  final double headerHeight;

  const DataGrid({
    super.key,
    required this.columnHeaders,
    required this.rowHeaders,
    required this.cellBuilder,
    this.cellWidth = 100.0,
    this.cellHeight = 60.0,
    this.headerWidth = 60.0,
    this.headerHeight = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top header row (empty corner + column headers)
        Row(
          children: [
            SizedBox(width: headerWidth, height: headerHeight),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: List.generate(columnHeaders.length, (colIndex) {
                    return SizedBox(
                      width: cellWidth,
                      height: headerHeight,
                      child: Center(
                        child: Text(
                          columnHeaders[colIndex],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        // Rows
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed row headers column
                Column(
                  children: List.generate(rowHeaders.length, (rowIndex) {
                    return SizedBox(
                      width: headerWidth,
                      height: cellHeight,
                      child: Center(
                        child: Text(
                          rowHeaders[rowIndex],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),
                // Grid cells
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: List.generate(rowHeaders.length, (rowIndex) {
                        return Row(
                          children: List.generate(columnHeaders.length, (
                            colIndex,
                          ) {
                            return SizedBox(
                              width: cellWidth,
                              height: cellHeight,
                              child: cellBuilder(context, rowIndex, colIndex),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
