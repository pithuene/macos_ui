import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/selectors/painters.dart';

typedef OnDateChanged = Function(DateTime date);

class MacosDatePicker extends StatefulWidget {
  const MacosDatePicker({
    Key? key,
    required this.format,
    required this.onDateChanged,
  }) : super(key: key);

  final DateFormat format;
  final OnDateChanged onDateChanged;

  @override
  State<MacosDatePicker> createState() => _MacosDatePickerState();
}

class _MacosDatePickerState extends State<MacosDatePicker> {
  final _initialDate = DateTime.now();
  late String formattedDate;
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isDaySelected = false;
  bool _isMonthSelected = false;
  bool _isYearSelected = false;

  @override
  void initState() {
    super.initState();
    formattedDate = widget.format.format(_initialDate);
    _parseInitialDate();
  }

  void _parseInitialDate() {
    _selectedYear = int.parse(formattedDate.split('/').last);
    _selectedMonth = int.parse(formattedDate.split('/').first);
    _selectedDay = int.parse(formattedDate.split('/')[1]);
  }

  DateTime _formatAsDateTime() {
    return DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  void _incrementElement() {
    if (_isDaySelected) {
      int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay + 1 <= daysInMonth) {
        setState(() => _selectedDay = (_selectedDay + 1));
      } else {
        setState(() => _selectedDay = 1);
      }
    }
    if (_isMonthSelected) {
      if (_selectedMonth + 1 <= 12) {
        setState(() => _selectedMonth++);
      } else {
        setState(() => _selectedMonth = 1);
      }
    }
    if (_isYearSelected) {
      setState(() => _selectedYear++);
    }
    widget.onDateChanged.call(_formatAsDateTime());
  }

  void _decrementElement() {
    if (_isDaySelected) {
      int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay - 1 >= 1) {
        setState(() => _selectedDay = (_selectedDay - 1));
      } else {
        setState(() => _selectedDay = daysInMonth);
      }
    }
    if (_isMonthSelected) {
      if (_selectedMonth - 1 >= 1) {
        setState(() => _selectedMonth--);
      } else {
        setState(() => _selectedMonth = 12);
      }
    }
    if (_isYearSelected) {
      setState(() => _selectedYear--);
    }
    widget.onDateChanged.call(_formatAsDateTime());
  }

  List<Widget> _dayHeaders(
    TextStyle? headerStyle,
    MaterialLocalizations localizations,
  ) {
    final result = <Widget>[];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final weekday = localizations.narrowWeekdays[i];
      result.add(
        ExcludeSemantics(
          child: Center(
            child: Text(
              weekday,
              style: headerStyle,
            ),
          ),
        ),
      );
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final datePickerTheme = MacosDatePickerTheme.of(context);
    const dayStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10.0,
      letterSpacing: 0.12,
    );
    final localizations = MaterialLocalizations.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final dayOffset =
        DateUtils.firstDayOffset(_selectedYear, _selectedMonth, localizations);
    final dayHeaders = _dayHeaders(
      MacosTheme.of(context).typography.caption1.copyWith(
            color: datePickerTheme.monthViewWeekdayHeaderColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.12,
          ),
      localizations,
    );
    // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
    // a leap year.
    int day = -dayOffset;

    final dayItems = <Widget>[];

    while (day < daysInMonth) {
      day++;
      if (day < 1) {
        dayItems.add(const SizedBox.shrink());
      } else {
        final dayToBuild = DateTime(_selectedYear, _selectedMonth, day);
        final isDisabled = dayToBuild.day < 1 && dayToBuild.day > daysInMonth;
        final isSelectedDay = DateUtils.isSameDay(
          DateTime(_selectedYear, _selectedMonth, _selectedDay),
          dayToBuild,
        );
        final isToday = DateUtils.isSameDay(_initialDate, dayToBuild);

        BoxDecoration? decoration;
        Widget? dayText;

        if (isToday && isSelectedDay) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle,
          );
          decoration = BoxDecoration(
            color: datePickerTheme.monthViewCurrentDateColor,
            borderRadius: BorderRadius.circular(3.0),
          );
        } else if (isToday) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle.apply(
              color: datePickerTheme.monthViewCurrentDateColor,
            ),
          );
        } else if (isSelectedDay) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle,
          );
          decoration = BoxDecoration(
            color: datePickerTheme.monthViewSelectedDateColor,
            borderRadius: BorderRadius.circular(3.0),
          );
        }

        Widget dayWidget = GestureDetector(
          onTap: () {
            setState(() {
              _isDaySelected = true;
              _selectedDay = dayToBuild.day;
            });
            widget.onDateChanged.call(_formatAsDateTime());
          },
          child: Container(
            decoration: decoration,
            child: Center(
              child: dayText ??
                  Text(
                    localizations.formatDecimal(day),
                    style: dayStyle,
                  ),
            ),
          ),
        );

        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        }

        dayItems.add(dayWidget);
      }
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhysicalModel(
              color: datePickerTheme.shadowColor!,
              elevation: 1,
              child: ColoredBox(
                color: datePickerTheme.backgroundColor!,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FieldElement(
                        element: '$_selectedMonth',
                        backgroundColor: _isMonthSelected
                            ? datePickerTheme.selectedElementColor!
                            : MacosColors.transparent,
                        onSelected: () {
                          setState(() {
                            _isMonthSelected = !_isMonthSelected;
                            _isDaySelected = false;
                            _isYearSelected = false;
                          });
                        },
                      ),
                      const Text('/'),
                      FieldElement(
                        element: '$_selectedDay',
                        backgroundColor: _isDaySelected
                            ? datePickerTheme.selectedElementColor!
                            : MacosColors.transparent,
                        onSelected: () {
                          setState(() {
                            _isDaySelected = !_isDaySelected;
                            _isMonthSelected = false;
                            _isYearSelected = false;
                          });
                        },
                      ),
                      const Text('/'),
                      FieldElement(
                        element: '$_selectedYear',
                        backgroundColor: _isYearSelected
                            ? datePickerTheme.selectedElementColor!
                            : MacosColors.transparent,
                        onSelected: () {
                          setState(() {
                            _isYearSelected = !_isYearSelected;
                            _isDaySelected = false;
                            _isMonthSelected = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4.0),
            Column(
              children: [
                SizedBox(
                  height: 10.0,
                  width: 12.0,
                  child: GestureDetector(
                    onTap: _incrementElement,
                    child: PhysicalModel(
                      color: datePickerTheme.shadowColor!,
                      elevation: 1,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5.0),
                      ),
                      child: CustomPaint(
                        painter: UpCaretPainter(
                          color: datePickerTheme.caretColor!,
                          backgroundColor:
                              datePickerTheme.caretControlsBackgroundColor!,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 1.0,
                  child: ColoredBox(
                    color: datePickerTheme.caretControlsSeparatorColor!,
                  ),
                ),
                SizedBox(
                  height: 10.0,
                  width: 12.0,
                  child: GestureDetector(
                    onTap: _decrementElement,
                    child: PhysicalModel(
                      color: datePickerTheme.shadowColor!,
                      elevation: 1,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(5.0),
                      ),
                      child: CustomPaint(
                        painter: DownCaretPainter(
                          color: datePickerTheme.caretColor!,
                          backgroundColor:
                              datePickerTheme.caretControlsBackgroundColor!,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        PhysicalModel(
          color: datePickerTheme.shadowColor!,
          child: SizedBox(
            width: 138.0,
            child: ColoredBox(
              color: datePickerTheme.backgroundColor!,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2.0, 2.0, 0.0, 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${intToMonthAbbr(_selectedMonth)} $_selectedYear',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.08,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MacosIconButton(
                              icon: MacosIcon(
                                CupertinoIcons.arrowtriangle_left_fill,
                                size: 10.0,
                                color: datePickerTheme.monthViewControlsColor,
                              ),
                              backgroundColor: MacosColors.transparent,
                              borderRadius: BorderRadius.zero,
                              padding: EdgeInsets.zero,
                              boxConstraints: const BoxConstraints(
                                maxWidth: 12.0,
                              ),
                              onPressed: () {
                                setState(() => _selectedMonth--);
                                widget.onDateChanged.call(_formatAsDateTime());
                              },
                            ),
                            const SizedBox(width: 6.0),
                            MacosIconButton(
                              icon: MacosIcon(
                                CupertinoIcons.circle_fill,
                                size: 8.0,
                                color: datePickerTheme.monthViewControlsColor,
                              ),
                              backgroundColor: MacosColors.transparent,
                              borderRadius: BorderRadius.zero,
                              padding: EdgeInsets.zero,
                              boxConstraints: const BoxConstraints(
                                maxWidth: 12.0,
                              ),
                              onPressed: () {
                                setState(() => _parseInitialDate());
                                widget.onDateChanged.call(_formatAsDateTime());
                              },
                            ),
                            const SizedBox(width: 6.0),
                            MacosIconButton(
                              icon: MacosIcon(
                                CupertinoIcons.arrowtriangle_right_fill,
                                size: 10.0,
                                color: datePickerTheme.monthViewControlsColor,
                              ),
                              backgroundColor: MacosColors.transparent,
                              borderRadius: BorderRadius.zero,
                              padding: EdgeInsets.zero,
                              boxConstraints: const BoxConstraints(
                                maxWidth: 12.0,
                              ),
                              onPressed: () {
                                setState(() => _selectedMonth++);
                                widget.onDateChanged.call(_formatAsDateTime());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6.0, 0.0, 5.0, 0.0),
                    child: Column(
                      children: [
                        GridView.custom(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          gridDelegate: _dayPickerGridDelegate,
                          childrenDelegate: SliverChildListDelegate(
                            dayHeaders,
                            addRepaintBoundaries: false,
                          ),
                        ),
                        Divider(
                          color: datePickerTheme.monthViewHeaderDividerColor,
                          height: 0,
                        ),
                        GridView.custom(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          gridDelegate: _dayPickerGridDelegate,
                          childrenDelegate: SliverChildListDelegate(
                            dayItems,
                            addRepaintBoundaries: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(
      20.0,
      constraints.viewportMainAxisExtent / (6 + 1),
    );
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _dayPickerGridDelegate = _DayPickerGridDelegate();

class FieldElement extends StatelessWidget {
  const FieldElement({
    Key? key,
    required this.element,
    required this.backgroundColor,
    required this.onSelected,
  }) : super(key: key);

  final String element;
  final Color backgroundColor;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: ColoredBox(
        color: backgroundColor,
        child: Text(
          element,
          style: const TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.08,
          ),
        ),
      ),
    );
  }
}
