// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get welcomeTitle => 'Bem-vindo ao CallMe!';

  @override
  String get welcomeSubtitle => 'Comunicação direta, descentralizada e segura.';

  @override
  String get supportCardTitle =>
      'O CallMe é uma iniciativa focada em garantir aos gamers ligações em grupo através de redes P2P.';

  @override
  String get supportCardSubtitle =>
      'Desenvolver e manter tecnologias descentralizadas exige muito café e noites em claro. Considere apoiar o projeto! qualquer valor ajuda!';

  @override
  String get supportButton => 'Apoiar o Desenvolvimento';

  @override
  String get helperText =>
      'Crie o seu próprio espaço ou junte-se aos seus amigos na barra inferior.';

  @override
  String get createServer => 'Criar Servidor';

  @override
  String get join => 'Entrar';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get tabAppearance => 'Aparência';

  @override
  String get tabAudio => 'Áudio';

  @override
  String get tabSecurity => 'Segurança';

  @override
  String get tabNetwork => 'Rede';

  @override
  String get profileDisplayNameLabel => 'NOME DE EXIBIÇÃO';

  @override
  String get profileDisplayNameHint => 'Digite seu nome de exibição';

  @override
  String get profileLanguageLabel => 'IDIOMA DO APLICATIVO';

  @override
  String get profileSaveChanges => 'Salvar Alterações';

  @override
  String get profileSaveSuccess => 'Perfil atualizado com sucesso!';

  @override
  String get appearanceAppThemeLabel => 'TEMA DO APLICATIVO';

  @override
  String get appearanceAccentColorTitle => 'Cor de Destaque';

  @override
  String get appearanceAccentColorDesc =>
      'Muda a cor principal de botões, ícones e destaques do CallMe.';

  @override
  String get appearanceCustomColorTitle => 'Cor Customizada';

  @override
  String get appearanceTypographyLabel => 'TIPOGRAFIA';

  @override
  String get appearanceAppFontTitle => 'Fonte do Aplicativo';

  @override
  String get appearanceAppFontDesc =>
      'Altera o estilo do texto em toda a interface.';

  @override
  String get appearanceVoiceIndicatorLabel => 'INDICADOR DE VOZ';

  @override
  String get appearanceIndicatorColorTitle => 'Cor do Indicador';

  @override
  String get appearanceIndicatorColorDesc =>
      'Cor do card quando um usuário está falando na chamada.';

  @override
  String get appearanceNeonEffectTitle => 'Efeito Neon';

  @override
  String get appearanceNeonEffectDesc =>
      'Ativa um brilho ao redor do card quando o usuário fala.';

  @override
  String get appearanceBackgroundImagesLabel => 'IMAGENS DE FUNDO';

  @override
  String get appearanceAppBackgroundTitle => 'Plano de Fundo do App';

  @override
  String get appearanceAppBackgroundDesc =>
      'Personalize a imagem que aparece atrás de todas as telas.';

  @override
  String get appearanceNotifBackgroundTitle => 'Fundo da Notificação';

  @override
  String get appearanceNotifBackgroundDesc =>
      'Imagem exclusiva que aparece na notificação expansível durante uma chamada de voz.';

  @override
  String get btnSelectImage => 'Selecionar Imagem';

  @override
  String get imageConfigured => 'Imagem configurada';

  @override
  String get colorBlue => 'Azul (Padrão)';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorPurple => 'Roxo';

  @override
  String get colorOrange => 'Laranja';

  @override
  String get audioProcessingLabel => 'PROCESSAMENTO DE ÁUDIO (WEBRTC)';

  @override
  String get audioFiltersTitle => 'Filtros de Áudio (Gamers)';

  @override
  String get audioFiltersDesc =>
      'Desative os filtros abaixo se o seu áudio estiver muito baixo enquanto você joga ou escuta música. Isso fará o WebRTC enviar o áudio bruto no volume máximo.';

  @override
  String get audioAgcTitle => 'Controle Automático de Volume (AGC)';

  @override
  String get audioAgcDesc =>
      'Baixa o microfone automaticamente ao detectar som alto do jogo.';

  @override
  String get audioNoiseTitle => 'Supressão de Ruído';

  @override
  String get audioNoiseDesc =>
      'Remove ruídos de fundo (como ventilador ou som do jogo).';

  @override
  String get audioEchoTitle => 'Cancelamento de Eco';

  @override
  String get audioEchoDesc =>
      'Impede que os outros ouçam a própria voz saindo do seu alto-falante.';

  @override
  String get securityExportTitle => 'Exportar Conta';

  @override
  String get securityExportDesc =>
      'Salve seus dados em um arquivo binário para não perder sua identidade em caso de formatação.';

  @override
  String get securityExportPassHint => 'Crie uma senha para o backup';

  @override
  String get securityExportPassConfirmHint => 'Confirme a senha';

  @override
  String get securityExportBtn => 'Gerar Arquivo de Segurança';

  @override
  String get securityExportErrShort =>
      'A senha deve ter pelo menos 4 caracteres.';

  @override
  String get securityExportErrMatch => 'As senhas não coincidem.';

  @override
  String get securityExportSuccess =>
      'Backup gerado e pronto para compartilhar!';

  @override
  String get securityExportShareText => 'Meu Backup CallMe';

  @override
  String get securityExportErrorPrefix => 'Erro ao exportar: ';

  @override
  String get securityImportTitle => 'Restaurar Conta';

  @override
  String get securityImportDesc =>
      'Importe seu arquivo .clmbkp para recuperar sua identidade e acessar seus servidores.';

  @override
  String get securityImportSelectFile => 'Selecionar Arquivo';

  @override
  String get securityImportFileSelected => 'Arquivo selecionado';

  @override
  String get securityImportPassHint => 'Digite a senha do backup';

  @override
  String get securityImportBtn => 'Iniciar Restauração';

  @override
  String get securityImportSuccess => 'Conta restaurada com sucesso!';

  @override
  String get securityImportErrPass => 'Senha incorreta.';

  @override
  String get securityImportErrCorrupt =>
      'Erro: o arquivo pode ser inválido ou corrompido.';

  @override
  String get networkDiagnosticLabel => 'DIAGNÓSTICO DE REDE';

  @override
  String get networkDiagnosticDesc =>
      'Descubra as condições da sua rede e veja como o aplicativo está lidando com o WebRTC e o NAT (CGNAT).';

  @override
  String get networkDiagnosticRunning => 'Analisando...';

  @override
  String get networkDiagnosticBtn => 'Rodar Diagnóstico';

  @override
  String get networkDiagnosticResultsLabel => 'RESULTADOS';

  @override
  String get networkLocalIpv4 => 'IPv4 Local';

  @override
  String get networkPublicIpv4 => 'IPv4 Público';

  @override
  String get networkPublicIpv6 => 'IPv6 Público';

  @override
  String get networkStatusLabel => 'Situação da Rede';

  @override
  String get networkStatusCgnat => 'CGNAT (Restrito)';

  @override
  String get networkStatusNat => 'NAT (Roteador)';

  @override
  String get networkStatusOpen => 'Aberta (Sem NAT)';

  @override
  String get networkStatusUnknown => 'Desconhecida';

  @override
  String get networkExplanationTitle => 'O que isso significa?';

  @override
  String get networkExpIpv6 =>
      'Seu dispositivo possui IPv6! Isso significa que o CallMe consegue estabelecer uma conexão P2P direta com excelente qualidade, contornando qualquer NAT.';

  @override
  String get networkExpOpen =>
      'Não detectamos restrições de NAT. Conexões diretas devem funcionar perfeitamente.';

  @override
  String get networkExpNat =>
      'Você está atrás de um NAT comum (provavelmente um roteador Wi-Fi). O WebRTC tentará perfurar esse NAT (Holepunching). Na maioria das vezes, a conexão direta funciona.';

  @override
  String get networkExpCgnat =>
      'Detectamos CGNAT Estrito (NAT de Operadora Móvel). O WebRTC P2P tradicional não consegue atravessar isso. Mas não se preocupe! O CallMe está utilizando a rede Stealth Relay (MQTT) para garantir que sua voz chegue ao destino.';

  @override
  String get networkExpUnknown =>
      'Não foi possível determinar o tipo exato de NAT na sua rede (ou você está usando a versão Web).';

  @override
  String get donationTitle => 'Apoie o Projeto!';

  @override
  String get donationDesc =>
      'Gostando do CallMe? Nós não cobramos nada. Se você quiser ajudar a pagar os servidores de Relay e manter o projeto vivo, faça uma doação de qualquer valor!';

  @override
  String get donationPixCopied =>
      'Chave PIX copiada para a área de transferência!';

  @override
  String get donationCopyPix => 'Copiar Chave PIX';

  @override
  String get donationClose => 'Fechar';

  @override
  String get createServerDialogTitle => 'Criar seu servidor';

  @override
  String get createServerDialogDesc =>
      'Seu servidor é onde você e seus amigos se reúnem. Crie o seu e comece a conversar livremente.';

  @override
  String get createServerDialogNameLabel => 'NOME DO SERVIDOR';

  @override
  String get createServerDialogNameHint => 'Meu Servidor P2P';

  @override
  String get cancel => 'Cancelar';

  @override
  String createServerDialogError(String error) {
    return 'Erro ao criar servidor: $error';
  }
}
