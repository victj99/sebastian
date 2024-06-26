import 'package:flutter/material.dart';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:sebastian/data/lcu/models/champion_mastery.dart';
import 'package:sebastian/data/models/champion.dart';
import 'package:sebastian/di/di.dart';
import 'package:sebastian/presentation/core/colors.dart';
import 'package:sebastian/presentation/core/widgets/icons/chest_icon.dart';
import 'package:sebastian/presentation/core/widgets/icons/eternal_bonfire_icon.dart';
import 'package:sebastian/presentation/core/widgets/icons/mastery_icon.dart';

import 'bloc/champions_table_bloc.dart';

class ChampionsTableWidget extends StatelessWidget {
  const ChampionsTableWidget({super.key, required this.summonerId});

  final int summonerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChampionsTableBloc(summonerId, getIt(), getIt()),
      child: BlocBuilder<ChampionsTableBloc, ChampionsTableState>(
        builder: (context, state) {
          return switch (state) {
            SummaryChampionsTableState state => SummaryChampionsTableStateWidget(state: state),
            PickInfoChampionsTableState state => _PickTable(
                myChampion: state.myChampion,
                benchChampions: state.benchChampions,
                teamChampions: state.teamMatesChampions,
              ),
          };
        },
      ),
    );
  }
}

class SummaryChampionsTableStateWidget extends StatelessWidget {
  const SummaryChampionsTableStateWidget({
    super.key,
    required this.state,
  });

  final SummaryChampionsTableState state;

  DropdownMenuItem<ChampionRole> _roleMenuItem(ChampionRole? role, AppLocalizations appLocalizations) {
    return DropdownMenuItem(
      value: role,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(appLocalizations.championRole(role?.name ?? "")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              DropdownButton<ChampionRole>(
                value: state.roleFilter,
                underline: const SizedBox.shrink(),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                onChanged: (value) =>
                    context.read<ChampionsTableBloc>().add(ChangeRoleFilterChampionsTableEvent(value)),
                items: [
                  _roleMenuItem(null, appLocalizations),
                  for (var role in ChampionRole.values) _roleMenuItem(role, appLocalizations),
                ],
              ),
              const SizedBox(width: 16),
              FilterChip(
                selected: state.onlyMasterySet,
                onSelected: (selected) =>
                    context.read<ChampionsTableBloc>().add(ChangeOnlySetFilterChampionsTableEvent(selected)),
                label: Text(appLocalizations.masteryTableFilterSet),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ChampionsTable(
            champions: state.champions,
            sortAscending: state.ascending,
            sortColumnIndex: ChampionsTableColumn.values.indexOf(state.sortColumn),
            onSortColumn: (int columnIndex, bool ascending) {
              context.read<ChampionsTableBloc>().add(
                    ChangeSortChampionsTableEvent(
                      column: ChampionsTableColumn.values[columnIndex],
                      ascending: ascending,
                    ),
                  );
            },
          ),
        ),
      ],
    );
  }
}

const _kTableMinWidth = 800.0;
const _kTableColumnSpacing = 24.0;

class _ChampionsTable extends StatelessWidget {
  const _ChampionsTable({
    required this.champions,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSortColumn,
  });

  final List<Champion> champions;
  final bool sortAscending;
  final int? sortColumnIndex;
  final DataColumnSortCallback? onSortColumn;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return DataTable2(
      minWidth: _kTableMinWidth,
      columnSpacing: _kTableColumnSpacing,
      fixedLeftColumns: 1,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      headingTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      columns: _buildChampionColumns(appLocalizations, onSortColumn, true),
      rows: [
        for (var i = 0; i < champions.length; i++) _buildChampionRow(appLocalizations, champions[i], ordinal: i + 1),
      ],
    );
  }
}

class _PickTable extends StatelessWidget {
  const _PickTable({
    this.myChampion,
    required this.benchChampions,
    required this.teamChampions,
  });

  final Champion? myChampion;
  final List<Champion> benchChampions;
  final List<Champion> teamChampions;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return DataTable2(
      minWidth: _kTableMinWidth,
      columnSpacing: _kTableColumnSpacing,
      headingTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      columns: _buildChampionColumns(appLocalizations),
      rows: [
        for (var champion in benchChampions) _buildChampionRow(appLocalizations, champion),
        if (myChampion != null)
          _buildChampionRow(appLocalizations, myChampion!, color: SebastianColors.myChampionRowColor),
        for (var champion in teamChampions)
          _buildChampionRow(appLocalizations, champion, color: SebastianColors.myTeamChampionRowColor)
      ],
    );
  }
}

/// Do not forget change order in [ChampionsTableColumn]
List<DataColumn> _buildChampionColumns(
  AppLocalizations appLocalizations, [
  DataColumnSortCallback? onSortColumn,
  bool withOrdinalColumn = false,
]) {
  return <DataColumn>[
    if (withOrdinalColumn)
      const DataColumn2(
        fixedWidth: 36,
        label: SizedBox.shrink(),
      ),
    DataColumn2(
      onSort: onSortColumn,
      size: ColumnSize.M,
      label: Text(appLocalizations.masteryTableColumnChampion),
    ),
    DataColumn2(
      onSort: onSortColumn,
      fixedWidth: 85,
      label: Center(
        child: Padding(
          padding: EdgeInsets.only(left: onSortColumn != null ? 18 : 0),
          child: const MasteryIcon(
            size: Size(24, 24),
            color: Colors.white,
          ),
        ),
      ),
    ),
    DataColumn2(
      onSort: onSortColumn,
      numeric: true,
      size: ColumnSize.M,
      label: Text(appLocalizations.masteryTableColumnPoints),
    ),
    DataColumn2(
      onSort: onSortColumn,
      numeric: true,
      size: ColumnSize.M,
      label: Text(appLocalizations.masteryTableColumnProgress),
    ),
    DataColumn2(
      onSort: onSortColumn,
      numeric: true,
      size: ColumnSize.L,
      label: Text(appLocalizations.masteryTableColumnMilestones),
    ),
    DataColumn2(
      onSort: onSortColumn,
      size: ColumnSize.M,
      numeric: true,
      label: Text(appLocalizations.masteryTableColumnEternals),
    ),
  ];
}

DataRow _buildChampionRow(
  AppLocalizations appLocalizations,
  Champion champion, {
  Color? color,
  int? ordinal,
}) {
  return DataRow(
    key: ValueKey(champion.id),
    color: color != null ? WidgetStateProperty.all(color) : null,
    cells: <DataCell>[
      if (ordinal != null) DataCell(Center(child: Text(ordinal.toString())), placeholder: true),
      DataCell(_ChampionNameWidget(
        championName: champion.name,
        inMasterySet: champion.inMasterySet,
      )),
      DataCell(Center(child: Text(champion.mastery.championLevel.toString()))),
      DataCell(Text(champion.mastery.championPoints.toString())),
      DataCell(
        Text(champion.mastery.championPointsUntilNextLevel > 0
            ? champion.mastery.championPointsUntilNextLevel.toString()
            : '${champion.mastery.tokensEarned} / ${champion.mastery.markRequiredForNextLevel}'),
      ),
      DataCell(_MasteryMilestoneWidget(mastery: champion.mastery)),
      DataCell(_StatStoneWidget(
        milestonesPassed: champion.statStones.milestonesPassed,
        stonesOwned: champion.statStones.stonesOwned,
      )),
    ],
  );
}

class _ChampionNameWidget extends StatelessWidget {
  const _ChampionNameWidget({
    required this.championName,
    required this.inMasterySet,
  });

  final String championName;
  final bool inMasterySet;

  @override
  Widget build(BuildContext context) {
    if (!inMasterySet) {
      return Text(championName);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: Text(championName)),
        const SizedBox(width: 8),
        const ChestIcon(
          size: Size(16, 16),
        ),
      ],
    );
  }
}

class _MasteryMilestoneWidget extends StatelessWidget {
  const _MasteryMilestoneWidget({
    required this.mastery,
  });

  final ChampionMastery mastery;

  static int _gradeCompare(String a, String b) {
    const gradeRank = {'S': 0, 'A': 1, 'B': 2, 'C': 3, 'D': 4};
    return (gradeRank[a] ?? 0).compareTo(gradeRank[b] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final requiredGrades = <String>[];
    mastery.nextSeasonMilestone.requireGradeCounts.forEach((key, value) {
      for (var i = 0; i < value; i++) {
        requiredGrades.add(key[0]);
      }
    });
    requiredGrades.sort(_gradeCompare);

    final milestoneGrades = mastery.milestoneGrades.map((e) => e[0]).toList();
    milestoneGrades.sort(_gradeCompare);

    final gradeWidgets = <Widget>[];
    for (var grade in requiredGrades) {
      var earned = false;

      for (var milestoneGrade in milestoneGrades) {
        if (_gradeCompare(grade, milestoneGrade) >= 0) {
          earned = true;
          milestoneGrades.remove(milestoneGrade);
          break;
        }
      }

      gradeWidgets.add(Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          grade,
          style: earned ? null : const TextStyle(color: Colors.white24),
        ),
      ));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${mastery.championSeasonMilestone}'),
        const VerticalDivider(indent: 12, endIndent: 12),
        ...gradeWidgets,
      ],
    );
  }
}

class _StatStoneWidget extends StatelessWidget {
  const _StatStoneWidget({
    required this.milestonesPassed,
    required this.stonesOwned,
  });

  final int milestonesPassed;
  final int stonesOwned;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(milestonesPassed.toString()),
        const SizedBox(width: 4),
        const EternalBonfireIcon(size: Size(16, 16)),
        const SizedBox(width: 12),
        Text(appLocalizations.masteryTableStatStonesCount(stonesOwned))
      ],
    );
  }
}
