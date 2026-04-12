import 'dart:convert';

import 'package:cotimax/core/constants/app_colors.dart';
import 'package:cotimax/core/constants/app_spacing.dart';
import 'package:cotimax/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

quill.QuillController buildRichTextController([String? stored]) {
  final document = richTextDocumentFromStorage(stored);
  final offset = document.length > 1 ? document.length - 1 : 0;
  return quill.QuillController(
    document: document,
    selection: TextSelection.collapsed(offset: offset),
  );
}

quill.Document richTextDocumentFromStorage(String? stored) {
  final raw = stored ?? '';
  final parsed = _tryParseStoredDelta(raw);
  if (parsed != null) {
    return quill.Document.fromJson(parsed);
  }

  if (raw.trim().isEmpty) {
    return quill.Document();
  }

  final normalized = raw.endsWith('\n') ? raw : '$raw\n';
  return quill.Document.fromJson([
    {'insert': normalized},
  ]);
}

List<Map<String, dynamic>> richTextDeltaOpsFromStorage(String? stored) {
  final document = richTextDocumentFromStorage(stored);
  return document
      .toDelta()
      .toJson()
      .map<Map<String, dynamic>>((operation) {
        return Map<String, dynamic>.from(operation as Map);
      })
      .toList(growable: false);
}

String serializeRichTextController(quill.QuillController controller) {
  final deltaJson = controller.document.toDelta().toJson();
  final normalized = deltaJson
      .map<Map<String, dynamic>>((operation) {
        return Map<String, dynamic>.from(operation as Map);
      })
      .toList(growable: false);
  final plainText = richTextPlainTextFromController(controller);
  final isEmptyDocument =
      plainText.isEmpty &&
      normalized.length == 1 &&
      normalized.first['insert'] == '\n';
  if (isEmptyDocument) {
    return '';
  }
  return jsonEncode(normalized);
}

String richTextPlainTextFromStorage(String? stored) {
  return richTextDocumentFromStorage(stored).toPlainText().trim();
}

String richTextPlainTextFromController(quill.QuillController controller) {
  return controller.document.toPlainText().trim();
}

bool richTextControllerHasContent(quill.QuillController controller) {
  return richTextPlainTextFromController(controller).isNotEmpty;
}

void replaceRichTextControllerContent(
  quill.QuillController controller,
  String? stored,
) {
  controller.document = richTextDocumentFromStorage(stored);
}

List<Map<String, dynamic>>? _tryParseStoredDelta(String raw) {
  if (raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item as Map);
        })
        .toList(growable: false);
  } catch (_) {
    return null;
  }
}

class CotimaxRichTextEditor extends StatefulWidget {
  const CotimaxRichTextEditor({
    required this.controller,
    required this.placeholder,
    this.editorHeight = 180,
    this.readOnly = false,
    super.key,
  });

  final quill.QuillController controller;
  final String placeholder;
  final double editorHeight;
  final bool readOnly;

  @override
  State<CotimaxRichTextEditor> createState() => _CotimaxRichTextEditorState();
}

class _CotimaxRichTextEditorState extends State<CotimaxRichTextEditor> {
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refocusEditor() {
    if (!widget.readOnly) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final editorFill =
        theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    final surfaceColor = theme.colorScheme.surface;
    final editorTextColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;
    final toolbarUnselectedColor = isDark
        ? theme.colorScheme.onSurface
        : AppColors.textPrimary;
    final toolbarSelectedColor = isDark
        ? theme.colorScheme.onPrimaryContainer
        : AppColors.white;
    final toolbarSelectedBackgroundColor = isDark
        ? theme.colorScheme.primaryContainer
        : AppColors.textPrimary;
    const toolbarButtonConstraints = BoxConstraints(
      minWidth: 36,
      minHeight: 36,
    );
    final toolbarButtonData = quill.IconButtonData(
      constraints: toolbarButtonConstraints,
      padding: const EdgeInsets.all(8),
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
      color: toolbarUnselectedColor,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.10),
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.10),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.16),
      style: IconButton.styleFrom(
        foregroundColor: toolbarUnselectedColor,
        backgroundColor: Colors.transparent,
      ),
    );
    final toolbarSelectedButtonData = toolbarButtonData.copyWith(
      color: toolbarSelectedColor,
      style: IconButton.styleFrom(
        foregroundColor: toolbarSelectedColor,
        backgroundColor: toolbarSelectedBackgroundColor,
      ),
    );
    final toolbarIconTheme = quill.QuillIconTheme(
      iconButtonUnselectedData: toolbarButtonData,
      iconButtonSelectedData: toolbarSelectedButtonData,
    );
    final editorTheme = theme.copyWith(
      canvasColor: surfaceColor,
      scaffoldBackgroundColor: surfaceColor,
      iconTheme: theme.iconTheme.copyWith(color: editorTextColor),
      dialogTheme: theme.dialogTheme.copyWith(
        backgroundColor: surfaceColor,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: editorTextColor,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: editorTextColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: mutedTextColor),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(color: mutedTextColor),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: editorFill,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!widget.readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Theme(
                data: editorTheme,
                child: quill.QuillSimpleToolbar(
                  controller: widget.controller,
                  config: quill.QuillSimpleToolbarConfig(
                    toolbarSize: 36,
                    toolbarRunSpacing: 6,
                    toolbarSectionSpacing: 6,
                    multiRowsDisplay: false,
                    showFontFamily: false,
                    showSmallButton: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showLink: false,
                    showSearchButton: false,
                    showDirection: false,
                    showClipboardCut: false,
                    showClipboardCopy: false,
                    showClipboardPaste: false,
                    showListCheck: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showLineHeightButton: false,
                    showAlignmentButtons: true,
                    showBackgroundColorButton: true,
                    showColorButton: true,
                    showHeaderStyle: true,
                    sectionDividerColor: AppColors.border,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                      base: quill.QuillToolbarBaseButtonOptions(
                        iconSize: 16,
                        iconButtonFactor: 1,
                        afterButtonPressed: _refocusEditor,
                        iconTheme: toolbarIconTheme,
                      ),
                      fontSize: quill.QuillToolbarFontSizeButtonOptions(
                        items: const {
                          '12px': '12',
                          '14px': '14',
                          '16px': '16',
                          '18px': '18',
                          '24px': '24',
                          'Limpiar': '0',
                        },
                        defaultDisplayText: '14px',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: widget.editorHeight,
            child: Theme(
              data: editorTheme,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: editorTextColor),
                child: quill.QuillEditor(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: quill.QuillEditorConfig(
                    placeholder: trText(widget.placeholder),
                    padding: const EdgeInsets.all(12),
                    autoFocus: false,
                    expands: false,
                    scrollable: true,
                    readOnlyMouseCursor: SystemMouseCursors.text,
                    textSelectionThemeData: theme.textSelectionTheme.copyWith(
                      cursorColor: theme.colorScheme.primary,
                      selectionColor: theme.colorScheme.primary.withValues(
                        alpha: 0.22,
                      ),
                      selectionHandleColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
