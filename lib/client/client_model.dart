class Client {
  final String clientID;
  final String name;
  final String mobile;
  final String address;
  final double billAmt;
  final double balance;
  final double debit;
  final String description;
  final String currentDate;
  final String reminder;
  final String category;

  Client({
    required this.clientID,
    required this.name,
    required this.mobile,
    required this.address,
    required this.billAmt,
    required this.balance,
    required this.debit,
    required this.description,
    required this.currentDate,
    required this.reminder,
    required this.category,
  });

  factory Client.fromFirestore(Map<String, dynamic> data) {
    return Client(
      clientID: data['cid'] ?? '',
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      address: data['address'] ?? '',
      billAmt: data['billAmt'] ?? 0,
      balance: data['balance'] ?? 0,
      debit: data['debit'] ?? 0,
      description: data['description'] ?? '',
      currentDate: data['currentDate'] ?? '',
      reminder: data['reminder'] ?? '',
      category: data['category'] ?? '',
    );
  }
}
