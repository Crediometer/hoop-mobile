class FacialVerificationData {
  final String selfieImage; // base64 encoded image
  final String idImage; // base64 encoded image

  FacialVerificationData({
    required this.selfieImage,
    required this.idImage,
  });

  Map<String, dynamic> toJson() => {
        'selfieImage': selfieImage,
        'idImage': idImage,
      };
}
