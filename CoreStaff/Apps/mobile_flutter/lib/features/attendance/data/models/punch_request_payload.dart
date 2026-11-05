import 'dart:typed_data';

enum PunchAction {
  checkIn,
  checkOut;

  String get path => this == PunchAction.checkIn
      ? '/api/attendance/check-in'
      : '/api/attendance/check-out';
}

enum PunchWorkMode {
  inOffice('IN_OFFICE'),
  outOffice('OUT_OFFICE');

  final String value;
  const PunchWorkMode(this.value);

  static PunchWorkMode fromString(String? value) {
    if (value == 'OUT_OFFICE') return PunchWorkMode.outOffice;
    return PunchWorkMode.inOffice;
  }
}

class PunchLocationPayload {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? address;

  const PunchLocationPayload({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (address != null) 'address': address,
    };
  }
}

class PunchWifiPayload {
  final String? ssid;
  final String? bssid;

  const PunchWifiPayload({this.ssid, this.bssid});

  Map<String, dynamic> toJson() {
    return {
      if (ssid != null && ssid!.isNotEmpty) 'wifiSsid': ssid,
      if (bssid != null && bssid!.isNotEmpty) 'wifiBssid': bssid,
    };
  }
}

class PunchRequestPayload {
  final PunchWorkMode? workMode;
  final PunchLocationPayload? location;
  final PunchWifiPayload? wifi;

  /// Selfie bytes. Bytes (not a path) because `MultipartFile.fromFile` throws
  /// `UnsupportedError` on web, where the picked image is a blob URL.
  final Uint8List? selfieBytes;
  final String? note;
  final String? idempotencyKey;

  const PunchRequestPayload({
    this.workMode,
    this.location,
    this.wifi,
    this.selfieBytes,
    this.note,
    this.idempotencyKey,
  });

  bool get hasSelfie => selfieBytes != null && selfieBytes!.isNotEmpty;

  Map<String, dynamic> toJson({required bool isCheckIn}) {
    return {
      if (isCheckIn && workMode != null) 'workMode': workMode!.value,
      if (location != null) ...{
        'location': location!.toJson(),
        'latitude': location!.latitude,
        'longitude': location!.longitude,
        if (location!.accuracyMeters != null)
          'accuracyMeters': location!.accuracyMeters,
        if (location!.address != null) 'address': location!.address,
      },
      if (wifi?.ssid != null && wifi!.ssid!.isNotEmpty) 'wifiSsid': wifi!.ssid,
      if (wifi?.bssid != null && wifi!.bssid!.isNotEmpty)
        'wifiBssid': wifi!.bssid,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
