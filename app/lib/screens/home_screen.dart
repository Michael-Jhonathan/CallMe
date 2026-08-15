import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'settings_screen.dart';
import '../widgets/home_footer.dart';
import '../widgets/create_server_dialog.dart';
import '../widgets/server_admin_dialog.dart';
import '../widgets/channel_admin_dialog.dart';
import '../widgets/active_call_diagnostic_dialog.dart';
import '../widgets/donation_dialog.dart';
import '../widgets/a_ads_banner.dart';
import 'package:core_protocol/core_protocol.dart'; // import to use ClmFile
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Ícone de topologia de malha (mesh network) com animação pulsante
class AnimatedMeshNetworkIcon extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? iconColor;

  const AnimatedMeshNetworkIcon({
    super.key,
    this.size = 80,
    this.color,
    this.iconColor,
  });

  @override
  State<AnimatedMeshNetworkIcon> createState() => _AnimatedMeshNetworkIconState();
}

class _AnimatedMeshNetworkIconState extends State<AnimatedMeshNetworkIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? CallMeTheme.primaryContainer;
    final ic = widget.iconColor ?? CallMeTheme.surfaceLow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: _glowAnimation.value),
                  blurRadius: widget.size * 0.6,
                  spreadRadius: widget.size * 0.1,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MeshPainter(color: c, iconColor: ic),
            ),
          ),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color color;
  final Color iconColor;
  _MeshPainter({required this.color, required this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.42;
    final nodeR = size.width * 0.10;
    const nodeCount = 6;

    final nodes = List.generate(nodeCount, (i) {
      final angle = (2 * pi * i / nodeCount) - (pi / 2);
      return Offset(cx + outerR * cos(angle), cy + outerR * sin(angle));
    });

    final linePaint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodeCount; i++) {
      for (int j = i + 1; j < nodeCount; j++) {
        canvas.drawLine(nodes[i], nodes[j], linePaint);
      }
    }

    final iconData = Icons.phone;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: nodeR * 1.2,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    void drawNode(Offset pos, double radius) {
      final nodePaint = Paint()..color = color;
      canvas.drawCircle(pos, radius, nodePaint);
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    drawNode(Offset(cx, cy), nodeR * 1.15);
    for (final pos in nodes) {
      drawNode(pos, nodeR);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado para qual canal de voz estamos conectados no momento (simulação)
  String? _connectedVoiceChannelId;
  String? _pendingVoiceChannelId;
  bool _isMuted = false;
  bool _isDeafened = false;
  
  bool isSidebarExpanded = false;
  int _sidebarAdReloadKey = 0;

  void _toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
      if (isSidebarExpanded) {
        _sidebarAdReloadKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: HomeFooter(
          onCreateServer: () {
            showDialog(
              context: context,
              builder: (context) => const CreateServerDialog(),
            );
          },
          onJoinServer: () {
            _showJoinServerDialog(context);
          },
        ),
        body: Stack(
          children: [
          // Área Principal (Canais ou Empty State) + Voice HUD
          // O padding garante que o conteúdo principal não fique escondido sob a sidebar recolhida (72px)
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Column(
              children: [
                Expanded(
                  child: appState.currentServer == null
                      ? _buildEmptyState()
                      : _buildServerChannelsArea(appState.currentServer!),
                ),
                if (_connectedVoiceChannelId != null) _buildVoiceHUD(appState),
              ],
            ),
          ),
          
          // Web: widgets ocultos para forçar o Chrome a reproduzir áudio WebRTC
          if (kIsWeb)
            Positioned(
              left: -1,
              top: -1,
              width: 1,
              height: 1,
              child: Builder(
                builder: (ctx) {
                  final renderers = context.watch<AppState>().webAudioRenderers;
                  return Stack(
                    children: renderers.map((entry) {
                      return RTCVideoView(
                        (entry as MapEntry<String, RTCVideoRenderer>).value,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          
          // Overlay para fechar a sidebar ao clicar fora dela
          if (isSidebarExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black54, // Fundo escurecido suave
                ),
              ),
            ),

          // Sidebar de Servidores
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _buildServerSidebar(appState),
          ),
        ],
      ),
    ));
  }

  Widget _buildServerSidebar(AppState appState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isSidebarExpanded ? 260 : 72,
      decoration: const BoxDecoration(
        color: CallMeTheme.surfaceLow,
        border: Border(
          right: BorderSide(color: CallMeTheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          const Divider(color: CallMeTheme.outlineVariant, indent: 16, endIndent: 16, height: 1),
          const SizedBox(height: 12),
          
          // Lista de Servidores
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: appState.savedServers.length,
              itemBuilder: (context, index) {
                final server = appState.savedServers[index];
                final isSelected = server == appState.currentServer;
                final initial = server.serverName.isNotEmpty ? server.serverName[0].toUpperCase() : '?';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      // Indicador de selecionado
                      Container(
                        width: 4,
                        height: isSelected ? 40 : 8,
                        decoration: BoxDecoration(
                          color: isSelected ? CallMeTheme.onSurface : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ícone do Servidor
                      Expanded(
                        child: GestureDetector(
                          onTap: () => appState.switchServer(server),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            height: 48,
                            padding: EdgeInsets.symmetric(horizontal: isSidebarExpanded ? 12 : 0),
                            decoration: BoxDecoration(
                              color: isSelected ? CallMeTheme.primaryContainer : CallMeTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
                            ),
                            alignment: isSidebarExpanded ? Alignment.centerLeft : Alignment.center,
                            child: Row(
                              mainAxisAlignment: isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                              children: [
                                Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? CallMeTheme.onPrimaryContainer : CallMeTheme.onSurfaceVariant,
                                  ),
                                ),
                                if (isSidebarExpanded) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      server.serverName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? CallMeTheme.onPrimaryContainer : CallMeTheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // A-Ads Banner na Sidebar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: CallMeTheme.outlineVariant, width: 1)),
            ),
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: isSidebarExpanded ? 260 : 72,
                  child: Center(
                    child: isSidebarExpanded
                        ? AAdsBanner(width: 240, height: 50, reloadKey: _sidebarAdReloadKey)
                        : const AAdsBanner(width: 60, height: 50),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    if (!isSidebarExpanded) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        child: IconButton(
          icon: const Icon(Icons.menu, color: CallMeTheme.onSurface),
          onPressed: _toggleSidebar,
          tooltip: 'Expandir',
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: CallMeTheme.onSurface),
              onPressed: _toggleSidebar,
              tooltip: 'Recolher',
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFbec2ff), // fallback color
                  child: Icon(
                    Icons.person,
                    color: Colors.black, // fallback color
                    size: 18,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: CallMeTheme.secondaryFixed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CallMeTheme.surfaceLow,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.watch<AppState>().currentUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    '#Online',
                    style: TextStyle(
                      color: CallMeTheme.secondaryFixed,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.settings,
                size: 20,
                color: CallMeTheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Efeitos de Fundo (Esferas Desfocadas)
            Positioned(
              top: -constraints.maxHeight * 0.1,
              left: -constraints.maxWidth * 0.2,
              child: Container(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxWidth * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CallMeTheme.primary.withValues(alpha: 0.04),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight * 0.1,
              right: -constraints.maxWidth * 0.2,
              child: Container(
                width: constraints.maxWidth * 0.6,
                height: constraints.maxWidth * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CallMeTheme.tertiary.withValues(alpha: 0.03),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Logo Animada
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Builder(
                          builder: (context) {
                            final size = constraints.maxWidth > 600 ? 300.0 : 180.0;
                            return SizedBox(
                              width: size,
                              height: size,
                              child: Center(child: AnimatedMeshNetworkIcon(size: size * 0.8)),
                            );
                          }
                        ),
                      ),
                      
                      // Texto de Boas Vindas com Gradiente
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            CallMeTheme.primary,
                            const Color(0xFFE2E2E8), // onSurface fallback
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          AppLocalizations.of(context)!.welcomeTitle,
                          textAlign: TextAlign.center,
                          style: CallMeTheme.textTheme.displayLarge?.copyWith(
                            color: Colors.white, // Necessário para o ShaderMask
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 384),
                        child: Text(
                          AppLocalizations.of(context)!.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                            color: CallMeTheme.onSurfaceVariant,
                            fontSize: constraints.maxWidth < 360 ? 14 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Cartão de Apoio (Glassmorphism)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: CallMeTheme.outlineVariant.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: EdgeInsets.all(constraints.maxWidth < 360 ? 20 : 28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      CallMeTheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      CallMeTheme.surfaceContainer.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.supportCardTitle,
                                      textAlign: TextAlign.center,
                                      style: CallMeTheme.textTheme.bodySmall?.copyWith(
                                        color: CallMeTheme.onSurface,
                                        fontSize: constraints.maxWidth < 360 ? 13 : 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.supportCardSubtitle,
                                      textAlign: TextAlign.center,
                                      style: CallMeTheme.textTheme.bodySmall?.copyWith(
                                        color: CallMeTheme.onSurface,
                                        fontSize: constraints.maxWidth < 360 ? 13 : 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    
                                    SizedBox(
                                      width: double.infinity,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          gradient: LinearGradient(
                                            colors: [
                                              CallMeTheme.primaryContainer,
                                              CallMeTheme.primaryContainer.withValues(alpha: 0.8),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CallMeTheme.primaryContainer.withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => const DonationDialog(),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.favorite,
                                            color: CallMeTheme.tertiary,
                                            size: 20,
                                          ),
                                          label: Text(
                                            AppLocalizations.of(context)!.supportButton,
                                            style: CallMeTheme.textTheme.titleSmall?.copyWith(
                                              color: Colors.white,
                                              fontSize: constraints.maxWidth < 360 ? 14 : 16,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Texto de Ajuda
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          AppLocalizations.of(context)!.helperText,
                          textAlign: TextAlign.center,
                          style: CallMeTheme.textTheme.bodySmall?.copyWith(
                            color: CallMeTheme.onSurfaceVariant.withValues(alpha: 0.8),
                            fontSize: constraints.maxWidth < 360 ? 12 : 14,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServerChannelsArea(ClmFile server) {
    return Container(
      color: Colors.transparent, // Permite visualizar o Wallpaper de fundo
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Servidor
          Container(
            height: 56, // h-14
            padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CallMeTheme.outlineVariant, width: 1)),
              color: CallMeTheme.surfaceContainer,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    server.serverName,
                    style: CallMeTheme.textTheme.headlineMedium?.copyWith(
                      color: CallMeTheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (context.watch<AppState>().isCurrentUserAdmin)
                  IconButton(
                    icon: const Icon(Icons.person_add, color: CallMeTheme.secondary),
                    tooltip: 'Convide Amigos',
                    onPressed: () {
                      _showInviteDialog(context, server);
                    },
                  ),
                if (context.watch<AppState>().isCurrentUserAdmin)
                  IconButton(
                    icon: const Icon(Icons.settings, color: CallMeTheme.onSurfaceVariant),
                    tooltip: 'Configurações do Servidor',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ServerAdminDialog(),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Lista de Canais na Tela Principal
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    _buildSectionTitle('CANAIS DE TEXTO', onAdd: null),
                    const SizedBox(height: 8),
                    if (server.textChannels.isEmpty)
                      const Padding(padding: EdgeInsets.only(left: 12), child: Text('Nenhum canal de texto.', style: TextStyle(color: CallMeTheme.onSurfaceVariant))),
                    ...server.textChannels.map((tc) => _buildChannelItem(
                      title: tc.title,
                      icon: Icons.tag,
                      onTap: () => _openTextChannelDialog(tc),
                      isActive: false,
                      isAdmin: context.watch<AppState>().isCurrentUserAdmin,
                      channel: tc,
                    )),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      'CANAIS DE VOZ',
                      onAdd: context.watch<AppState>().isCurrentUserAdmin
                          ? () => _showAddVoiceChannelDialog(context)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    if (server.channels.isEmpty)
                      const Padding(padding: EdgeInsets.only(left: 12), child: Text('Nenhum canal de voz.', style: TextStyle(color: CallMeTheme.onSurfaceVariant))),
                    ...server.channels.map((vc) {
                      final isConnected = _connectedVoiceChannelId == vc.id;
                      final isPending = _pendingVoiceChannelId == vc.id;
                      final appState = context.watch<AppState>();
                      final members = appState.connectedVoiceMembers[vc.id] ?? [];
                      
                      return _buildChannelItem(
                        title: vc.name,
                        icon: Icons.volume_up,
                        onTap: () {
                          setState(() {
                            if (isConnected) {
                              _connectedVoiceChannelId = null; // Disconnect
                              context.read<AppState>().leaveVoiceChannel(vc.id);
                            } else {
                              _pendingVoiceChannelId = vc.id; // Pending Join
                            }
                          });
                        },
                        isActive: isConnected || isPending,
                        isAdmin: appState.isCurrentUserAdmin,
                        channel: vc,
                        voiceMembers: members,
                      );
                    }),
                  ],
                ),

                // Floating Footer for Voice Connection Confirmation
                if (_pendingVoiceChannelId != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: CallMeTheme.surfaceBright,
                        border: Border(top: BorderSide(color: CallMeTheme.outlineVariant)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, color: CallMeTheme.secondaryFixed),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Conectar ao canal de voz?', style: TextStyle(color: CallMeTheme.onSurface, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _pendingVoiceChannelId = null;
                              });
                            },
                            child: const Text('Cancelar', style: TextStyle(color: CallMeTheme.onSurfaceVariant)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AppState>().joinVoiceChannel(_pendingVoiceChannelId!);
                              setState(() {
                                _connectedVoiceChannelId = _pendingVoiceChannelId;
                                _pendingVoiceChannelId = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CallMeTheme.secondaryFixed,
                              foregroundColor: CallMeTheme.background,
                            ),
                            child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            title,
            style: CallMeTheme.textTheme.labelSmall?.copyWith(
              color: CallMeTheme.secondaryContainer,
            ),
          ),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: CallMeTheme.onSurfaceVariant),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onAdd,
          ),
      ],
    );
  }

  Widget _buildChannelItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    required bool isAdmin,
    required dynamic channel,
    List<ClmMember>? voiceMembers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              minLeadingWidth: 20,
              leading: Icon(
                icon,
                color: CallMeTheme.onSurfaceVariant,
                size: 20,
              ),
              title: Text(
                title,
                style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                  color: isActive ? CallMeTheme.onSurface : CallMeTheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              tileColor: isActive ? CallMeTheme.surfaceContainerLow : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // rounded
              onTap: onTap,
              hoverColor: CallMeTheme.surfaceContainerLow,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    IconButton(
                      icon: Icon(Icons.hub, size: 18, color: CallMeTheme.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Diagnóstico de Conexão',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ActiveCallDiagnosticDialog(
                            channelId: channel.id,
                            members: voiceMembers ?? [],
                          ),
                        );
                      },
                    ),
                  if (isActive && isAdmin) const SizedBox(width: 8),
                  if (isAdmin) 
                    IconButton(
                      icon: const Icon(Icons.settings, size: 18, color: CallMeTheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ChannelAdminDialog(channel: channel),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        if (voiceMembers != null && voiceMembers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 8, top: 4),
            child: Column(
              children: voiceMembers.map((m) {
                final appState = context.read<AppState>();
                final isSpeaking = appState.voiceManager?.speakingStates[m.id] ?? false;
                
                final indicatorColor = appState.speakingColor ?? CallMeTheme.secondaryFixed;
                final enableNeon = appState.enableNeonEffect;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSpeaking ? indicatorColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSpeaking ? Border.all(color: indicatorColor, width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
                      boxShadow: isSpeaking && enableNeon
                          ? [
                              BoxShadow(
                                color: indicatorColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: CallMeTheme.primaryContainer,
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 10, color: CallMeTheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _openTextChannelDialog(ClmTextChannel channel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: CallMeTheme.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          height: 600,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Chat Header
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: CallMeTheme.surfaceBright,
                  border: Border(bottom: BorderSide(color: CallMeTheme.outlineVariant, width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: CallMeTheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      channel.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CallMeTheme.onSurface),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: CallMeTheme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Chat Body
              Expanded(
                child: Container(
                  color: CallMeTheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CallMeTheme.primaryContainer.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.tag, size: 32, color: CallMeTheme.primaryContainer),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Bem-vindo ao canal #${channel.title}',
                                style: TextStyle(
                                  color: CallMeTheme.onSurface,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: CallMeTheme.outlineVariant),
                        const SizedBox(height: 24),
                        MarkdownBody(
                          data: channel.content,
                          selectable: true,
                          onTapLink: (text, href, title) {
                            // Links externos desativados propositalmente
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontSize: 16, height: 1.5),
                            h1: const TextStyle(color: CallMeTheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: CallMeTheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: CallMeTheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                            strong: TextStyle(color: CallMeTheme.onSurface, fontWeight: FontWeight.bold),
                            em: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                            listBullet: TextStyle(color: CallMeTheme.primaryContainer, fontSize: 20),
                            blockquoteDecoration: BoxDecoration(
                              color: CallMeTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border(left: BorderSide(color: CallMeTheme.primaryContainer, width: 4)),
                            ),
                            blockquotePadding: const EdgeInsets.all(16),
                            code: const TextStyle(backgroundColor: CallMeTheme.surfaceVariant, fontFamily: 'monospace', color: CallMeTheme.secondaryFixed),
                            codeblockDecoration: BoxDecoration(
                              color: CallMeTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // A-Ads Banner no rodapé do texto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: const BoxDecoration(
                  color: CallMeTheme.surface,
                  border: Border(top: BorderSide(color: CallMeTheme.outlineVariant, width: 1)),
                ),
                alignment: Alignment.center,
                child: const AAdsBanner(width: 468, height: 60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVoiceChannelDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: CallMeTheme.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Novo Canal de Voz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CallMeTheme.onSurface)),
                  IconButton(
                    icon: const Icon(Icons.close, color: CallMeTheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 24),
              const Text('NOME DO CANAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CallMeTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: CallMeTheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: CallMeTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  hintText: 'ex: Lobby Principal',
                  hintStyle: const TextStyle(color: CallMeTheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      context.read<AppState>().addVoiceChannel(nameController.text.trim());
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CallMeTheme.primaryContainer,
                    foregroundColor: CallMeTheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Criar Canal', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceHUD(AppState appState) {
    // Buscar as informações do canal conectado
    String channelName = 'Canal Desconhecido';
    String serverName = 'Servidor Desconhecido';
    
    for (var srv in appState.savedServers) {
      for (var ch in srv.channels) {
        if (ch.id == _connectedVoiceChannelId) {
          channelName = ch.name;
          serverName = srv.serverName;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: CallMeTheme.surfaceLowest, // Fundo bem escuro para diferenciar
        border: Border(top: BorderSide(color: CallMeTheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Lado Esquerdo: Info da Conexão
          const Icon(Icons.signal_cellular_alt, color: CallMeTheme.secondaryFixed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voz Conectada',
                  style: const TextStyle(color: CallMeTheme.secondaryFixed, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$channelName / $serverName',
                  style: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Lado Direito: Controles
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, size: 20),
            color: _isMuted ? Colors.redAccent : CallMeTheme.onSurface,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
                if (!_isMuted) {
                  _isDeafened = false;
                }
              });
            },
            tooltip: _isMuted ? 'Ligar Microfone' : 'Mutar Microfone',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(_isDeafened ? Icons.headset_off : Icons.headset, size: 20),
            color: _isDeafened ? Colors.redAccent : CallMeTheme.onSurface,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isDeafened = !_isDeafened;
                if (_isDeafened) {
                  _isMuted = true;
                }
              });
            },
            tooltip: _isDeafened ? 'Ligar Fones' : 'Desligar Fones',
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              appState.leaveVoiceChannel(_connectedVoiceChannelId!);
              setState(() {
                _connectedVoiceChannelId = null;
                _isMuted = false;
                _isDeafened = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
            ),
            child: const Icon(Icons.call_end, size: 18),
          ),
        ],
      ),
    );
  }

  void _showJoinServerDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    bool isScanning = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: CallMeTheme.surfaceLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Entrar em um Servidor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CallMeTheme.onSurface)),
                        IconButton(
                          icon: const Icon(Icons.close, color: CallMeTheme.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('CÓDIGO DE CONVITE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CallMeTheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      style: const TextStyle(color: CallMeTheme.onSurface),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: CallMeTheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        hintText: 'Cole o código do seu amigo aqui',
                        hintStyle: const TextStyle(color: CallMeTheme.onSurfaceVariant),
                        suffixIcon: IconButton(
                          icon: Icon(isScanning ? Icons.qr_code_scanner_outlined : Icons.qr_code_scanner, color: isScanning ? CallMeTheme.primary : CallMeTheme.onSurfaceVariant),
                          tooltip: 'Escanear QR Code',
                          onPressed: () {
                            setStateDialog(() {
                              isScanning = !isScanning;
                            });
                          },
                        ),
                      ),
                    ),
                    if (isScanning) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.black,
                          child: MobileScanner(
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  codeController.text = barcode.rawValue!;
                                  setStateDialog(() {
                                    isScanning = false;
                                  });
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (codeController.text.trim().isNotEmpty) {
                            context.read<AppState>().requestJoinServer(codeController.text.trim());
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Solicitação enviada pelo Correio P2P! Aguarde a aprovação.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CallMeTheme.secondaryFixed,
                          foregroundColor: CallMeTheme.background,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context, ClmFile server) {
    bool showQr = false;
    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder para atualizar a lista de requests em tempo real
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final appState = context.watch<AppState>();
            final pending = appState.getPendingRequests();
            
            final inviteCode = server.serverAesKey != null 
                ? '${server.serverId}@${server.serverAesKey}'
                : server.serverId;
            
            return Dialog(
              backgroundColor: CallMeTheme.surfaceLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Convide Amigos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CallMeTheme.onSurface)),
                        IconButton(
                          icon: const Icon(Icons.close, color: CallMeTheme.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Seu Código de Convite:', style: TextStyle(color: CallMeTheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: CallMeTheme.surfaceLowest, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              inviteCode,
                              style: const TextStyle(color: CallMeTheme.secondaryFixed, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.qr_code, color: CallMeTheme.onSurfaceVariant),
                            tooltip: 'Mostrar QR Code',
                            onPressed: () {
                              setStateDialog(() {
                                showQr = !showQr;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: CallMeTheme.onSurfaceVariant),
                            tooltip: 'Copiar',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
                            },
                          )
                        ],
                      ),
                    ),
                    if (showQr) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: inviteCode,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Text('SOLICITAÇÕES DE ENTRADA PENDENTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CallMeTheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (pending.isEmpty)
                      const Text('Nenhum amigo pediu para entrar ainda.', style: TextStyle(color: CallMeTheme.onSurfaceVariant, fontStyle: FontStyle.italic))
                    else
                      ...pending.map((req) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: CallMeTheme.primaryContainer,
                          child: Text(req.name.isNotEmpty ? req.name[0].toUpperCase() : '?', style: TextStyle(color: CallMeTheme.onPrimaryContainer)),
                        ),
                        title: Text(req.name, style: const TextStyle(color: CallMeTheme.onSurface, fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${req.id.substring(0, 8)}...', style: const TextStyle(color: CallMeTheme.onSurfaceVariant, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () => appState.denyJoinRequest(req.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: CallMeTheme.secondaryFixed),
                              onPressed: () {
                                appState.approveJoinRequest(req);
                              },
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
