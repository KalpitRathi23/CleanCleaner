import 'package:flutter/material.dart';

class ClientUtil {
  static Color getBalanceColor(double balance) {
    if (balance > 0) {
      return Colors.green;
    } else if (balance == 0) {
      return Colors.black;
    } else {
      return Colors.red;
    }
  }

  static Color getBadgeColor(String category) {
    switch (category.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'normal':
        return Colors.yellow.shade700;
      case 'bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String formatBalanceValue(double balance) {
    if (balance < 0) {
      return '-₹${balance.abs().toStringAsFixed(2)}';
    } else {
      return '₹${balance.toStringAsFixed(2)}';
    }
  }

  static String formatDetailValue(double value) {
    if (value < 0) {
      return '-₹${value.abs().toString()}';
    } else {
      return '₹${value.toString()}';
    }
  }

  static Widget buildBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(
        color: getBadgeColor(category),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category == '0' ? 'NA' : category,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static Future<DateTime?> pickCustomDate(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black,
            hintColor: Colors.black,
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
  }

  static Future<TimeOfDay?> pickCustomTime(BuildContext context) async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.black,
              dialHandColor: Colors.blue,
              dialTextColor: Colors.white,
              hourMinuteColor: Colors.black,
              helpTextStyle: const TextStyle(color: Colors.black),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white),
              entryModeIconColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  static String formatDate(DateTime date) {
    return "${date.day} ${monthName(date.month)} ${date.year}";
  }

  static String formatTime(DateTime date, BuildContext context) {
    TimeOfDay time = TimeOfDay(hour: date.hour, minute: date.minute);
    return time.format(context);
  }

  static String monthName(int month) {
    const monthNames = [
      "Jan",
      "Feb",
      "March",
      "April",
      "May",
      "June",
      "July",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return monthNames[month - 1];
  }

  static Widget buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDetailRowWithColor(
      String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
