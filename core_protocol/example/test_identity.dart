import 'dart:convert';
import 'dart:typed_data';
import '../lib/src/clm_identity.dart';

void main() async {
  print('testes de segurança');

  // 1. Simula o João instalando o app pela primeira vez
  print(
    '\nGerando par de chaves criptográficas invisíveis no aparelho do João...',
  );
  final chavesJoao = await ClmIdentity.generateKeyPair();

  final idJoao = await ClmIdentity.getPublicKeyHex(chavesJoao);
  print('Chave Pública (O "ID") do João gerada: $idJoao');

  // 2. Simula o João criando um pacote Delta
  final payloadMensagem = utf8.encode(
    'João adicionou um novo canal de voz: Sala de Música',
  );

  print('\nJoão está assinando a ação com sua Chave Privada (invisível)...');
  final assinatura = await ClmIdentity.signPayload(
    Uint8List.fromList(payloadMensagem),
    chavesJoao,
  );
  print(
    'ação assinada digitalmente! (Assinatura tem ${assinatura.bytes.length} bytes)',
  );

  // 3. Simula o Marcos (outro usuário) recebendo o pacote
  print('\n--- VERIFICAÇÃO NO CELULAR DO MARCOS ---');
  print(
    'Marcos recebe o pacote e verifica matematicamente se quem enviou foi mesmo o dono do ID [$idJoao]...',
  );

  final ehValido = await ClmIdentity.verifySignature(
    payloadMensagem,
    assinatura,
    idJoao,
  );

  if (ehValido) {
    print('assinatura válida, é o verdadeiro João.');
  } else {
    print('assinatura inválida, fraude detectada');
  }

  // 4. Teste Anti-Fraude
  print('\n--- TESTE DE FRAUDE ---');
  print(
    'Hacker intercepta o pacote e tenta modificar o conteúdo para "Hacker baniu o Marcos", mas mantém a assinatura do João...',
  );
  final payloadFalso = utf8.encode('Hacker baniu o Marcos');

  final ehValidoHacker = await ClmIdentity.verifySignature(
    payloadFalso,
    assinatura,
    idJoao,
  );

  if (!ehValidoHacker) {
    print('assinatura não bate, possivel fraude');
  } else {
    print('assinatura bate, fraude não detectada');
  }

  print('\nTESTE DE SEGURANÇA CONCLUÍDO!');
}
