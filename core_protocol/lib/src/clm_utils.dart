import 'dart:typed_data';

/// Helpers para ler e escrever inteiros de 64-bits (Big Endian)
/// Funciona de forma segura na Web (dart2js) onde ByteData.setInt64 falha.
class ClmUtils {
  static int readInt64Safe(Uint8List bytes, int offset) {
    // Na web, números são doubles de 64 bits que comportam com precisão inteiros até 53 bits.
    // Como os timestamps cabem tranquilamente em 41 bits, essa matemática é perfeitamente segura.
    int high = (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];
    int low = (bytes[offset + 4] << 24) | (bytes[offset + 5] << 16) | (bytes[offset + 6] << 8) | bytes[offset + 7];
    
    // Converte low para unsigned caso tenha se tornado negativo nas operações de bits (32 bits com sinal)
    final unsignedLow = low < 0 ? low + 4294967296 : low;
    final unsignedHigh = high < 0 ? high + 4294967296 : high;
    
    return (unsignedHigh * 4294967296) + unsignedLow;
  }

  static void writeInt64Safe(BytesBuilder builder, int value) {
    int high = (value / 4294967296).floor();
    int low = value - (high * 4294967296);
    
    final data = Uint8List(8);
    data[0] = (high >> 24) & 0xff;
    data[1] = (high >> 16) & 0xff;
    data[2] = (high >> 8) & 0xff;
    data[3] = high & 0xff;
    data[4] = (low >> 24) & 0xff;
    data[5] = (low >> 16) & 0xff;
    data[6] = (low >> 8) & 0xff;
    data[7] = low & 0xff;
    
    builder.add(data);
  }
}
