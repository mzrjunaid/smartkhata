/// Data point for the monthly performance bar chart.
class MonthlyStat {
  const MonthlyStat({
    required this.month,
    required this.disbursed,
    required this.collected,
  });

  final String month;
  final double disbursed;
  final double collected;

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: json['month'] as String,
      disbursed: (json['disbursed'] as num).toDouble(),
      collected: (json['collected'] as num).toDouble(),
    );
  }
}
