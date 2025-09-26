import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/core/theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? valueDetails;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final int labelFlex;
  final int valueFlex;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueDetails,
    this.labelStyle,
    this.valueStyle,
    this.labelFlex = 2,
    this.valueFlex = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: labelFlex,
            child: Text(
              '$label:',
              softWrap: true,
              style: labelStyle ??
                  const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.PRIMARY,
                  ),
            ),
          ),
          const SizedBox(width: 8),
// REPLACE ONLY the inner Row under: Expanded(flex: valueFlex, child: Row(...))
          Expanded(
            flex: valueFlex,
            child: value.isEmpty
                ? const Text('-')
                : RichText(
                    textWidthBasis: TextWidthBasis.parent,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.merge(
                            valueStyle ??
                                const TextStyle(fontWeight: FontWeight.w400),
                          ),
                      children: [
                        TextSpan(text: value),
                        if (valueDetails != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment
                                .middle, // keeps icon inline
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Tooltip(
                                message: valueDetails ?? 'No details available',
                                preferBelow: true,
                                child: GestureDetector(
                                  onTap: () {
                                    Fluttertoast.showToast(
                                      msg:
                                          "Press and hold to view activity description",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  },
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
