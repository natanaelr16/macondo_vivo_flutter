import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas y zonas horarias
class DateUtils {
  /// Obtiene la fecha y hora actual en la zona horaria local del dispositivo
  static DateTime getCurrentLocalDateTime() {
    return DateTime.now();
  }

  /// Obtiene la fecha y hora actual en UTC
  static DateTime getCurrentUTCDateTime() {
    return DateTime.now().toUtc();
  }

  /// Convierte una fecha local a UTC
  static DateTime localToUTC(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Convierte una fecha UTC a local
  static DateTime utcToLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Formatea una fecha para mostrar en la interfaz
  static String formatForDisplay(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Formatea una fecha para mostrar solo la fecha
  static String formatDateOnly(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Formatea una fecha para mostrar solo la hora
  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Convierte una fecha a string ISO8601 en UTC
  static String toUTCISOString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Convierte una fecha a string ISO8601 en zona horaria local
  static String toLocalISOString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parsea una fecha desde string ISO8601 y la convierte a zona horaria local
  static DateTime parseFromISOString(String isoString) {
    return DateTime.parse(isoString).toLocal();
  }

  /// Obtiene la fecha actual en formato YYYY-MM-DD para campos de fecha
  static String getCurrentDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Obtiene la hora actual en formato HH:mm para campos de hora
  static String getCurrentTimeString() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  /// Verifica si una fecha es en el futuro
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }

  /// Verifica si una fecha es en el pasado
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Obtiene el nombre del día de la semana
  static String getDayName(DateTime dateTime) {
    return DateFormat('EEEE', 'es').format(dateTime);
  }

  /// Obtiene el nombre del mes
  static String getMonthName(DateTime dateTime) {
    return DateFormat('MMMM', 'es').format(dateTime);
  }

  /// Calcula la diferencia en días entre dos fechas
  static int daysDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays;
  }

  /// Calcula la diferencia en horas entre dos fechas
  static int hoursDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inHours;
  }

  /// Obtiene la zona horaria actual del dispositivo
  static String getCurrentTimezone() {
    return DateTime.now().timeZoneName;
  }

  /// Obtiene el offset de zona horaria actual
  static Duration getCurrentTimezoneOffset() {
    return DateTime.now().timeZoneOffset;
  }

  /// Formatea el offset de zona horaria como string
  static String formatTimezoneOffset(Duration offset) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes % 60;
    final sign = offset.isNegative ? '-' : '+';
    return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Obtiene información completa de la zona horaria actual
  static String getCurrentTimezoneInfo() {
    final now = DateTime.now();
    final offset = formatTimezoneOffset(now.timeZoneOffset);
    return '${now.timeZoneName} (UTC$offset)';
  }
} 