import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../services/network_diagnostic_service.dart';
import '../widgets/a_ads_banner.dart';
import 'package:app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Permite visualizar o wallpaper
        appBar: AppBar(
          backgroundColor: CallMeTheme.surfaceContainer,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 56, // h-14
          title: Text(
            AppLocalizations.of(context)!.settings,
            style: CallMeTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurface,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CallMeTheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: CallMeTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: CallMeTheme.primary,
            unselectedLabelColor: CallMeTheme.onSurfaceVariant,
            labelStyle: CallMeTheme.textTheme.titleSmall,
            unselectedLabelStyle: CallMeTheme.textTheme.titleSmall,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.tabProfile),
              Tab(text: AppLocalizations.of(context)!.tabAppearance),
              Tab(text: AppLocalizations.of(context)!.tabAudio),
              Tab(text: AppLocalizations.of(context)!.tabSecurity),
              Tab(text: AppLocalizations.of(context)!.tabNetwork),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const AAdsBanner()],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _ProfileTab(),
            _AppearanceTab(),
            _AudioTab(),
            _SecurityTab(),
            _NetworkTab(),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<AppState>();
    _nameController = TextEditingController(text: currentState.currentUserName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      context.read<AppState>().setUserName(newName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileSaveSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0), // p-margin-desktop
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.profileDisplayNameLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8), // gap-sm
              TextField(
                controller: _nameController,
                maxLength: 12,
                style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                  color: CallMeTheme.onSurface,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2B2D31), // bg-[#2B2D31]
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: CallMeTheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: CallMeTheme.primary,
                      width: 1,
                    ),
                  ),
                  hintText: AppLocalizations.of(
                    context,
                  )!.profileDisplayNameHint,
                  hintStyle: CallMeTheme.textTheme.bodyMedium?.copyWith(
                    color: CallMeTheme.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ), // px-4 py-3
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.profileLanguageLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2D31),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CallMeTheme.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: context.watch<AppState>().currentLocale.languageCode,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2B2D31),
                    style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                      color: CallMeTheme.onSurface,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: CallMeTheme.onSurfaceVariant,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'pt',
                        child: Text(
                          AppLocalizations.of(context)!.languagePortuguese,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(
                          AppLocalizations.of(context)!.languageEnglish,
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        context.read<AppState>().setLocale(Locale(newValue));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32), // mt-4
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CallMeTheme.primaryContainer,
                    foregroundColor: CallMeTheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ), // px-4 py-3
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2, // shadow-md
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.profileSaveChanges,
                    style: CallMeTheme.textTheme.titleSmall?.copyWith(
                      color: CallMeTheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceTab extends StatelessWidget {
  const _AppearanceTab();

  static const List<Map<String, dynamic>> _themeColors = [
    {'name': 'Azul (Padrão)', 'color': Color(0xFFbec2ff)},
    {'name': 'Verde', 'color': Color(0xFF66de8b)},
    {'name': 'Rosa', 'color': Color(0xFFffb3ae)},
    {'name': 'Roxo', 'color': Color(0xFFbb86fc)},
    {'name': 'Laranja', 'color': Color(0xFFffb74d)},
  ];

  static const List<String> _fonts = [
    'Inter',
    'Roboto',
    'Outfit',
    'Poppins',
    'Montserrat',
  ];

  Future<void> _pickAppBackground(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<AppState>().setAppBackgroundImage(result.files.single.path);
    }
  }

  Future<void> _pickNotifBackground(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      context.read<AppState>().setNotifBackgroundImage(
        result.files.single.path,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cores do Tema
              Text(
                AppLocalizations.of(context)!.appearanceAppThemeLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.appearanceAccentColorTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.appearanceAccentColorDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          _themeColors.map((themeInfo) {
                            final color = themeInfo['color'] as Color;
                            final isSelected =
                                appState.appColor?.toARGB32() ==
                                    color.toARGB32() ||
                                (appState.appColor == null &&
                                    themeInfo['name'] == 'Azul (Padrão)');

                            return GestureDetector(
                              onTap: () => appState.setAppColor(color),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList()..add(
                            GestureDetector(
                              onTap: () async {
                                Color current =
                                    appState.appColor ??
                                    const Color(0xFFbec2ff);
                                Color newColor = await showColorPickerDialog(
                                  context,
                                  current,
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.appearanceCustomColorTitle,
                                    style: CallMeTheme.textTheme.titleMedium,
                                  ),
                                  pickersEnabled: const <ColorPickerType, bool>{
                                    ColorPickerType.both: true,
                                    ColorPickerType.primary: false,
                                    ColorPickerType.accent: false,
                                    ColorPickerType.bw: false,
                                    ColorPickerType.custom: false,
                                    ColorPickerType.wheel: true,
                                  },
                                );
                                if (newColor != current) {
                                  appState.setAppColor(newColor);
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CallMeTheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.colorize,
                                  color: CallMeTheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tipografia
              Text(
                AppLocalizations.of(context)!.appearanceTypographyLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.appearanceAppFontTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.appearanceAppFontDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _fonts.map((font) {
                        final isSelected = appState.appFontFamily == font;
                        return ChoiceChip(
                          label: Text(font, style: TextStyle(fontFamily: font)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              appState.setAppFontFamily(font);
                            }
                          },
                          selectedColor: CallMeTheme.primary,
                          backgroundColor: CallMeTheme.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? CallMeTheme.onPrimary
                                : CallMeTheme.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Indicador de Voz
              Text(
                AppLocalizations.of(context)!.appearanceVoiceIndicatorLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.appearanceIndicatorColorTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.appearanceIndicatorColorDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        Color current =
                            appState.speakingColor ??
                            CallMeTheme.secondaryFixed;
                        Color newColor = await showColorPickerDialog(
                          context,
                          current,
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.appearanceIndicatorColorTitle,
                            style: CallMeTheme.textTheme.titleMedium,
                          ),
                          pickersEnabled: const <ColorPickerType, bool>{
                            ColorPickerType.both: true,
                            ColorPickerType.primary: false,
                            ColorPickerType.accent: false,
                            ColorPickerType.bw: false,
                            ColorPickerType.custom: false,
                            ColorPickerType.wheel: true,
                          },
                        );
                        if (newColor != current) {
                          appState.setSpeakingColor(newColor);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              appState.speakingColor ??
                              CallMeTheme.secondaryFixed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CallMeTheme.outline,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: CallMeTheme.surfaceVariant),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.appearanceNeonEffectTitle,
                        style: CallMeTheme.textTheme.titleSmall?.copyWith(
                          color: CallMeTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.appearanceNeonEffectDesc,
                        style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                          color: CallMeTheme.onSurfaceVariant,
                        ),
                      ),
                      value: appState.enableNeonEffect,
                      activeThumbColor: CallMeTheme.primary,
                      onChanged: (val) => appState.setEnableNeonEffect(val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Plano de Fundo do App
              Text(
                AppLocalizations.of(context)!.appearanceBackgroundImagesLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              _buildBackgroundCard(
                context: context,
                title: AppLocalizations.of(
                  context,
                )!.appearanceAppBackgroundTitle,
                description: AppLocalizations.of(
                  context,
                )!.appearanceAppBackgroundDesc,
                imagePath: appState.appBackgroundImagePath,
                onPick: () => _pickAppBackground(context),
                onClear: () => appState.setAppBackgroundImage(null),
              ),

              const SizedBox(height: 24),
              _buildBackgroundCard(
                context: context,
                title: AppLocalizations.of(
                  context,
                )!.appearanceNotifBackgroundTitle,
                description: AppLocalizations.of(
                  context,
                )!.appearanceNotifBackgroundDesc,
                imagePath: appState.notifBackgroundImagePath,
                onPick: () => _pickNotifBackground(context),
                onClear: () => appState.setNotifBackgroundImage(null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard({
    required BuildContext context,
    required String title,
    required String description,
    required String? imagePath,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wallpaper, color: CallMeTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: CallMeTheme.textTheme.titleSmall?.copyWith(
                  color: CallMeTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          if (imagePath == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.image, size: 20),
                label: Text(
                  AppLocalizations.of(context)!.btnSelectImage,
                  style: CallMeTheme.textTheme.titleSmall,
                ),
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CallMeTheme.primary,
                  side: BorderSide(color: CallMeTheme.primary, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2D31),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: CallMeTheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.imageConfigured,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClear,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioTab extends StatelessWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.audioProcessingLabel,
              style: CallMeTheme.textTheme.labelSmall?.copyWith(
                color: CallMeTheme.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.audioFiltersTitle,
                    style: CallMeTheme.textTheme.titleSmall?.copyWith(
                      color: CallMeTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.audioFiltersDesc,
                    style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                      color: CallMeTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.audioAgcTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.audioAgcDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    value: appState.enableAutoGainControl,
                    activeThumbColor: CallMeTheme.primary,
                    onChanged: (val) => appState.setAudioFilters(
                      echo: appState.enableEchoCancellation,
                      noise: appState.enableNoiseSuppression,
                      agc: val,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: CallMeTheme.surfaceVariant),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.audioNoiseTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.audioNoiseDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    value: appState.enableNoiseSuppression,
                    activeThumbColor: CallMeTheme.primary,
                    onChanged: (val) => appState.setAudioFilters(
                      echo: appState.enableEchoCancellation,
                      noise: val,
                      agc: appState.enableAutoGainControl,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: CallMeTheme.surfaceVariant),
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.audioEchoTitle,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.audioEchoDesc,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurfaceVariant,
                      ),
                    ),
                    value: appState.enableEchoCancellation,
                    activeThumbColor: CallMeTheme.primary,
                    onChanged: (val) => appState.setAudioFilters(
                      echo: val,
                      noise: appState.enableNoiseSuppression,
                      agc: appState.enableAutoGainControl,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityTab extends StatefulWidget {
  const _SecurityTab();

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  // Controles de Exportação
  final _exportPassController = TextEditingController();
  final _exportConfirmController = TextEditingController();
  String _exportError = '';
  bool _isExporting = false;

  // Controles de Importação
  String? _selectedFilePath;
  String? _selectedFileName;
  final _importPassController = TextEditingController();
  String _importError = '';
  bool _isImporting = false;

  @override
  void dispose() {
    _exportPassController.dispose();
    _exportConfirmController.dispose();
    _importPassController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final pass = _exportPassController.text;
    final confirm = _exportConfirmController.text;

    if (pass.isEmpty || pass.length < 4) {
      setState(
        () =>
            _exportError = AppLocalizations.of(context)!.securityExportErrShort,
      );
      return;
    }
    if (pass != confirm) {
      setState(
        () =>
            _exportError = AppLocalizations.of(context)!.securityExportErrMatch,
      );
      return;
    }

    setState(() {
      _exportError = '';
      _isExporting = true;
    });

    try {
      final appState = context.read<AppState>();
      final backupBytes = await appState.exportBackup(pass);

      if (backupBytes == null) {
        throw Exception('Identidade não encontrada para backup.');
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/callme_conta.clmbkp');
      await backupFile.writeAsBytes(backupBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: AppLocalizations.of(context)!.securityExportShareText,
        ),
      );

      _exportPassController.clear();
      _exportConfirmController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.securityExportSuccess),
          ),
        );
      }
    } catch (e) {
      setState(
        () => _exportError =
            '${AppLocalizations.of(context)!.securityExportErrorPrefix}$e',
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSelectImportFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType
          .any, // No Android, custom extension pode bugar o SAF em algumas versões
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _importError = '';
        _importPassController.clear();
      });
    }
  }

  Future<void> _handleImport() async {
    final pass = _importPassController.text;
    if (pass.isEmpty) {
      setState(
        () =>
            _importError = AppLocalizations.of(context)!.securityImportPassHint,
      );
      return;
    }
    if (_selectedFilePath == null) return;

    setState(() {
      _importError = '';
      _isImporting = true;
    });

    try {
      final file = File(_selectedFilePath!);
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      final appState = context.read<AppState>();
      await appState.importBackup(bytes, pass);

      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.securityImportSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('Senha incorreta')) {
          _importError = AppLocalizations.of(context)!.securityImportErrPass;
        } else {
          _importError = AppLocalizations.of(context)!.securityImportErrCorrupt;
        }
      });
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExportCard(),
              const SizedBox(height: 24),
              _buildImportCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22), // bg-[#1E1F22]
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      padding: const EdgeInsets.all(24.0), // p-lg
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: CallMeTheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.securityExportTitle,
                style: CallMeTheme.textTheme.titleSmall?.copyWith(
                  color: CallMeTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.securityExportDesc,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _exportPassController,
            obscureText: true,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2B2D31), // bg-[#2B2D31]
              hintText: AppLocalizations.of(context)!.securityExportPassHint,
              hintStyle: CallMeTheme.textTheme.bodyMedium?.copyWith(
                color: CallMeTheme.outline,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CallMeTheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _exportConfirmController,
            obscureText: true,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2B2D31), // bg-[#2B2D31]
              hintText: AppLocalizations.of(
                context,
              )!.securityExportPassConfirmHint,
              hintStyle: CallMeTheme.textTheme.bodyMedium?.copyWith(
                color: CallMeTheme.outline,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CallMeTheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (_exportError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _exportError,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isExporting ? null : _handleExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: CallMeTheme.primaryContainer,
                foregroundColor: CallMeTheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.securityExportBtn,
                      style: CallMeTheme.textTheme.titleSmall?.copyWith(
                        color: CallMeTheme.onPrimaryContainer,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: CallMeTheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.securityImportTitle,
                style: CallMeTheme.textTheme.titleSmall?.copyWith(
                  color: CallMeTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.securityImportDesc,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedFilePath == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 20),
                label: Text(
                  AppLocalizations.of(context)!.securityImportSelectFile,
                  style: CallMeTheme.textTheme.titleSmall,
                ),
                onPressed: _isImporting ? null : _handleSelectImportFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CallMeTheme.primary,
                  side: BorderSide(color: CallMeTheme.primary, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2D31),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: CallMeTheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName ??
                          AppLocalizations.of(
                            context,
                          )!.securityImportFileSelected,
                      style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                        color: CallMeTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: CallMeTheme.onSurfaceVariant,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedFilePath = null;
                        _importError = '';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _importPassController,
              obscureText: true,
              style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                color: CallMeTheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2B2D31),
                hintText: AppLocalizations.of(context)!.securityImportPassHint,
                hintStyle: CallMeTheme.textTheme.bodyMedium?.copyWith(
                  color: CallMeTheme.outline,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: CallMeTheme.primary, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (_importError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _importError,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CallMeTheme.primaryContainer,
                  foregroundColor: CallMeTheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.securityImportBtn,
                        style: CallMeTheme.textTheme.titleSmall?.copyWith(
                          color: CallMeTheme.onPrimaryContainer,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NetworkTab extends StatefulWidget {
  const _NetworkTab();

  @override
  State<_NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<_NetworkTab> {
  bool _isLoading = false;
  NetworkDiagnosticResult? _result;

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final res = await NetworkDiagnosticService.runDiagnostics();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = res;
      });
    }
  }

  Widget _buildResultCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CallMeTheme.textTheme.labelMedium?.copyWith(
                    color: CallMeTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: CallMeTheme.textTheme.bodyLarge?.copyWith(
                    color: CallMeTheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    if (_result == null) return const SizedBox.shrink();

    String explanation = "";
    Color alertColor = CallMeTheme.primary;

    if (_result!.hasIpv6) {
      explanation = AppLocalizations.of(context)!.networkExpIpv6;
      alertColor = Colors.greenAccent;
    } else {
      switch (_result!.natType) {
        case NatType.open:
          explanation = AppLocalizations.of(context)!.networkExpOpen;
          alertColor = Colors.greenAccent;
          break;
        case NatType.standardNat:
          explanation = AppLocalizations.of(context)!.networkExpNat;
          alertColor = Colors.orangeAccent;
          break;
        case NatType.cgnat:
          explanation = AppLocalizations.of(context)!.networkExpCgnat;
          alertColor = Colors.redAccent;
          break;
        case NatType.unknown:
          explanation = AppLocalizations.of(context)!.networkExpUnknown;
          alertColor = Colors.orangeAccent;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.1),
        border: Border.all(color: alertColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: alertColor),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.networkExplanationTitle,
                style: CallMeTheme.textTheme.titleSmall?.copyWith(
                  color: alertColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: CallMeTheme.textTheme.bodyMedium?.copyWith(
              color: CallMeTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.networkDiagnosticLabel,
              style: CallMeTheme.textTheme.labelSmall?.copyWith(
                color: CallMeTheme.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.networkDiagnosticDesc,
              style: CallMeTheme.textTheme.bodyMedium?.copyWith(
                color: CallMeTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.network_check),
                label: Text(
                  _isLoading
                      ? AppLocalizations.of(context)!.networkDiagnosticRunning
                      : AppLocalizations.of(context)!.networkDiagnosticBtn,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CallMeTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _runDiagnostic,
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.networkDiagnosticResultsLabel,
                style: CallMeTheme.textTheme.labelSmall?.copyWith(
                  color: CallMeTheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              _buildResultCard(
                AppLocalizations.of(context)!.networkLocalIpv4,
                _result!.localIp,
                Icons.computer,
                Colors.lightBlue,
              ),
              _buildResultCard(
                AppLocalizations.of(context)!.networkPublicIpv4,
                _result!.publicIpv4,
                Icons.public,
                Colors.blueAccent,
              ),
              _buildResultCard(
                AppLocalizations.of(context)!.networkPublicIpv6,
                _result!.publicIpv6,
                Icons.public,
                _result!.hasIpv6 ? Colors.green : Colors.grey,
              ),
              _buildResultCard(
                AppLocalizations.of(context)!.networkStatusLabel,
                _result!.natType == NatType.cgnat
                    ? AppLocalizations.of(context)!.networkStatusCgnat
                    : _result!.natType == NatType.standardNat
                    ? AppLocalizations.of(context)!.networkStatusNat
                    : _result!.natType == NatType.open
                    ? AppLocalizations.of(context)!.networkStatusOpen
                    : AppLocalizations.of(context)!.networkStatusUnknown,
                _result!.natType == NatType.cgnat
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                _result!.natType == NatType.cgnat
                    ? Colors.redAccent
                    : Colors.greenAccent,
              ),

              _buildExplanation(),
            ],
          ],
        ),
      ),
    );
  }
}
