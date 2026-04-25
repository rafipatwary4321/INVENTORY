/// How the QR scanner should behave after a successful scan.
enum QRScanMode { stockIn, sell }

class QRScanArgs {
  QRScanArgs({required this.mode});
  final QRScanMode mode;
}
