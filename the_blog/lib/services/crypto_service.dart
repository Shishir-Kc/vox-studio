import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  static final _key = encrypt.Key.fromUtf8(
    'tHe_BlOg_2024_S3cur3_K3y!@#\$%^&*', // 32 chars for AES-256
  );

  static String encryptText(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}|${encrypted.base64}';
  }

  static String decryptText(String encryptedData) {
    final parts = encryptedData.split('|');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.decrypt64(parts[1], iv: iv);
  }
}
