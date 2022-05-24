import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:champmastery/data/models/chamption.dart';
import 'package:champmastery/di/di.dart';
import 'package:champmastery/presentation/core/unknown_bloc_state.dart';

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
          if (state is SummaryChampionsTableState) {
            return _ChampionsTable(
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
            );
          }

          if (state is PickInfoChampionsTableState) {
            return _PickTable(
              myChampion: state.myChampion,
              benchChampions: state.benchChampions,
              teamChampions: state.teamMatesChampions,
            );
          }

          return UnknownBlocState(blocState: state);
        },
      ),
    );
  }
}

class _ChampionsTable extends StatelessWidget {
  const _ChampionsTable({
    Key? key,
    required this.champions,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSortColumn,
  }) : super(key: key);

  final List<Champion> champions;
  final bool sortAscending;
  final int? sortColumnIndex;
  final DataColumnSortCallback? onSortColumn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
        columns: _buildChampionColumns(onSortColumn),
        rows: champions.map((champion) => _buildChampionRow(champion, _ChampionType.none)).toList(),
      ),
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
    return SingleChildScrollView(
      child: DataTable(
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
        columns: _buildChampionColumns(),
        rows: [
          if (myChampion != null) _buildChampionRow(myChampion!, _ChampionType.my),
          ...benchChampions.map((e) => _buildChampionRow(e, _ChampionType.bench)),
          ...teamChampions.map((e) => _buildChampionRow(e, _ChampionType.teamMate)),
        ],
      ),
    );
  }
}

List<DataColumn> _buildChampionColumns([DataColumnSortCallback? onSortColumn]) {
  return <DataColumn>[
    DataColumn(
      onSort: onSortColumn,
      label: const Text('Чемпион'),
    ),
    DataColumn(
      onSort: onSortColumn,
      numeric: true,
      label: const Text('Уровень'),
    ),
    DataColumn(
      onSort: onSortColumn,
      numeric: true,
      label: const Text('Очков'),
    ),
    DataColumn(
      onSort: onSortColumn,
      numeric: true,
      label: const Text('До сл. ур.'),
    ),
    DataColumn(
      onSort: onSortColumn,
      label: const Text('Сундук?'),
    ),
  ];
}

enum _ChampionType {
  none,
  my,
  bench,
  teamMate,
}

DataRow _buildChampionRow(Champion champion, _ChampionType type) {
  MaterialStateProperty<Color>? rowColor;

  switch (type) {
    case _ChampionType.none:
      break;
    case _ChampionType.my:
      rowColor = MaterialStateProperty.all(Colors.green[900]!);
      break;
    case _ChampionType.bench:
      rowColor = MaterialStateProperty.all(Colors.yellow[900]!);
      break;
    case _ChampionType.teamMate:
      rowColor = MaterialStateProperty.all(Colors.blue[900]!);
      break;
  }

  return DataRow(
    color: rowColor,
    cells: <DataCell>[
      DataCell(Text(champion.name)),
      DataCell(Text(champion.mastery.championLevel.toString())),
      DataCell(Text(champion.mastery.championPoints.toString())),
      DataCell(Text(champion.mastery.championPointsUntilNextLevel.toString())),
      DataCell(Checkbox(value: champion.mastery.chestGranted, onChanged: null)),
    ],
  );
}