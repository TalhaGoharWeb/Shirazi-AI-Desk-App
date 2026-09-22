import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/shirazi_colors.dart';

class ScholarlyMarkdownView extends StatelessWidget {
  final String content;

  const ScholarlyMarkdownView({
    super.key,
    required this.content,
  });

  /// Detects if a text block contains predominantly Arabic/Urdu script
  static bool isRtlScript(String text) {
    if (text.trim().isEmpty) return false;
    int rtlCount = 0;
    int ltrCount = 0;

    for (final rune in text.runes) {
      // Arabic, Urdu, Persian, and Arabic supplement unicode ranges
      if ((rune >= 0x0600 && rune <= 0x06FF) ||
          (rune >= 0x0750 && rune <= 0x077F) ||
          (rune >= 0x08A0 && rune <= 0x08FF) ||
          (rune >= 0xFB50 && rune <= 0xFDFF) ||
          (rune >= 0xFE70 && rune <= 0xFEFF)) {
        rtlCount++;
      } else if ((rune >= 0x0041 && rune <= 0x005A) ||
                 (rune >= 0x0061 && rune <= 0x007A)) {
        ltrCount++;
      }
    }

    if (rtlCount == 0 && ltrCount == 0) return false;
    return rtlCount >= ltrCount;
  }

  /// Detects if Arabic-script text is Urdu based on Urdu-specific letters and markers
  static bool isUrduText(String text) {
    // Distinctive Urdu phonemes / letters: ے, ں, ٹ, ڈ, ڑ, ہ, چ, پ, ژ, گ, ھ
    final urduPattern = RegExp(r'[\u06D2\u06BA\u0679\u0688\u0691\u06C1\u0686\u067E\u0698\u06AF\u06BE]');
    if (urduPattern.hasMatch(text)) return true;

    // Common Urdu grammatical words
    final urduWords = RegExp(r'\b(کیا|ہے|ہیں|تھا|تھے|تھی|کے|سے|میں|کا|کی|کو|پر|اور|نہیں|کر|کرنے|والے)\b');
    return urduWords.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Split content into paragraphs/blocks while preserving the complete text
    final blocks = _splitIntoBlocks(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    );
  }

  List<_MarkdownBlock> _splitIntoBlocks(String raw) {
    final lines = raw.split('\n');
    final List<_MarkdownBlock> blocks = [];
    List<String> currentParagraphLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Heading (### , ## , # )
      if (trimmed.startsWith('#')) {
        if (currentParagraphLines.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
          currentParagraphLines = [];
        }
        int level = 0;
        while (level < trimmed.length && trimmed[level] == '#') {
          level++;
        }
        final text = trimmed.substring(level).trim();
        blocks.add(_MarkdownBlock(type: _BlockType.heading, text: text, level: level));
        continue;
      }

      // Blockquote (> )
      if (trimmed.startsWith('>')) {
        if (currentParagraphLines.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
          currentParagraphLines = [];
        }
        final quoteText = trimmed.substring(1).trim();
        blocks.add(_MarkdownBlock(type: _BlockType.blockquote, text: quoteText));
        continue;
      }

      // Bullet List Item (* , - , • )
      if (trimmed.startsWith('* ') || trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        if (currentParagraphLines.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
          currentParagraphLines = [];
        }
        final itemText = trimmed.substring(2).trim();
        blocks.add(_MarkdownBlock(type: _BlockType.bullet, text: itemText));
        continue;
      }

      // Numbered List Item (1. , 2. )
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        if (currentParagraphLines.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
          currentParagraphLines = [];
        }
        blocks.add(_MarkdownBlock(
          type: _BlockType.numbered,
          text: numMatch.group(2) ?? '',
          prefix: '${numMatch.group(1)}.',
        ));
        continue;
      }

      // Empty line signals paragraph separation
      if (trimmed.isEmpty) {
        if (currentParagraphLines.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
          currentParagraphLines = [];
        }
        continue;
      }

      // Regular prose line
      currentParagraphLines.add(line);
    }

    if (currentParagraphLines.isNotEmpty) {
      blocks.add(_MarkdownBlock(type: _BlockType.paragraph, text: currentParagraphLines.join('\n')));
    }

    return blocks;
  }

  Widget _buildBlock(BuildContext context, _MarkdownBlock block) {
    final isRtl = isRtlScript(block.text);
    final isUrdu = isRtl && isUrduText(block.text);
    final direction = isRtl ? TextDirection.rtl : TextDirection.ltr;

    switch (block.type) {
      case _BlockType.heading:
        final double size = block.level == 1 ? 20 : (block.level == 2 ? 18 : 16);
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Directionality(
            textDirection: direction,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: size,
                  decoration: BoxDecoration(
                    color: ShiraziColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    block.text,
                    style: isUrdu
                        ? GoogleFonts.notoNastaliqUrdu(
                            fontSize: size + 1,
                            fontWeight: FontWeight.bold,
                            color: ShiraziColors.primaryFixed,
                            height: 1.8,
                          )
                        : (isRtl
                            ? GoogleFonts.amiri(
                                fontSize: size + 2,
                                fontWeight: FontWeight.bold,
                                color: ShiraziColors.primaryFixed,
                                height: 1.4,
                              )
                            : GoogleFonts.notoSerif(
                                fontSize: size,
                                fontWeight: FontWeight.bold,
                                color: ShiraziColors.primaryFixed,
                                height: 1.3,
                              )),
                    textDirection: direction,
                  ),
                ),
              ],
            ),
          ),
        );

      case _BlockType.blockquote:
        // Ideal for Qur'anic verses & Hadith text
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              right: isRtl ? const BorderSide(color: Color(0xFFD4AF37), width: 3.5) : BorderSide.none,
              left: isRtl ? BorderSide.none : const BorderSide(color: Color(0xFFD4AF37), width: 3.5),
            ),
          ),
          child: Directionality(
            textDirection: direction,
            child: SelectableText(
              block.text,
              style: isUrdu
                  ? GoogleFonts.notoNastaliqUrdu(
                      fontSize: 15.5,
                      color: ShiraziColors.primaryFixedDim,
                      height: 2.0,
                    )
                  : (isRtl
                      ? GoogleFonts.amiri(
                          fontSize: 17.5,
                          color: ShiraziColors.primaryFixedDim,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                        )
                      : GoogleFonts.notoSerif(
                          fontSize: 14.5,
                          fontStyle: FontStyle.italic,
                          color: ShiraziColors.primaryFixedDim,
                          height: 1.5,
                        )),
              textDirection: direction,
            ),
          ),
        );

      case _BlockType.bullet:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Directionality(
            textDirection: direction,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '✦ ',
                    style: TextStyle(color: ShiraziColors.primary, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(block.text, isRtl, isUrdu, direction),
                ),
              ],
            ),
          ),
        );

      case _BlockType.numbered:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Directionality(
            textDirection: direction,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${block.prefix ?? ""} ',
                  style: TextStyle(
                    color: ShiraziColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(block.text, isRtl, isUrdu, direction),
                ),
              ],
            ),
          ),
        );

      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Directionality(
            textDirection: direction,
            child: _buildRichInlineText(block.text, isRtl, isUrdu, direction),
          ),
        );
    }
  }

  /// Parses inline bold (**text**) and renders formatted text spans
  Widget _buildRichInlineText(String text, bool isRtl, bool isUrdu, TextDirection direction) {
    final baseStyle = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(
            fontSize: 15.5,
            color: ShiraziColors.onSurface,
            height: 2.0,
          )
        : (isRtl
            ? GoogleFonts.amiri(
                fontSize: 17.5,
                color: ShiraziColors.onSurface,
                height: 1.7,
              )
            : GoogleFonts.inter(
                fontSize: 15.0,
                color: ShiraziColors.onSurface,
                height: 1.6,
              ));

    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: ShiraziColors.primaryFixed,
    );

    // Fast path: if no bold markers, render directly
    if (!text.contains('**')) {
      return SelectableText(
        text,
        style: baseStyle,
        textDirection: direction,
      );
    }

    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: isBold ? boldStyle : baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textDirection: direction,
    );
  }
}

enum _BlockType {
  paragraph,
  heading,
  blockquote,
  bullet,
  numbered,
}

class _MarkdownBlock {
  final _BlockType type;
  final String text;
  final int level;
  final String? prefix;

  const _MarkdownBlock({
    required this.type,
    required this.text,
    this.level = 1,
    this.prefix,
  });
}
