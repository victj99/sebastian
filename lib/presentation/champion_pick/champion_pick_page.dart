import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:sebastian/data/models/lcu_image.dart';
import 'package:sebastian/data/senpai/models/senpai_build.dart';
import 'package:sebastian/presentation/champion_pick/bloc/champion_pick_bloc.dart';
import 'package:sebastian/presentation/champion_pick/bloc/champion_pick_models.dart';
import 'package:sebastian/presentation/core/widgets/role_tag.dart';
import 'package:sebastian/presentation/core/widgets/snackbar_presenter.dart';
import 'package:sebastian/presentation/core/widgets/unknown_bloc_state.dart';

import 'widgets/build_details.dart';

class ChampionPickPage extends StatelessWidget {
  const ChampionPickPage({super.key, required this.summonerId});

  final int summonerId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChampionPickBloc, ChampionPickState>(
      builder: (context, state) {
        if (state is NoActiveChampionPickState) {
          return Center(
            child: Text(
              'Похоже ты сейчас не в лобби 🤷‍♀️',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (state is NoPickedChampionPickState) {
          return Center(
            child: Text(
              'Давай выбирай, ну...',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (state is ActiveChampionPickState) {
          return SnackbarPresenter(
            messageStream: context.read<ChampionPickBloc>().errorMessageStream,
            child: _ActiveChampionPickWidget(state: state),
          );
        }

        return UnknownBlocState(blocState: state);
      },
    );
  }
}

class _ActiveChampionPickWidget extends StatelessWidget {
  const _ActiveChampionPickWidget({
    required this.state,
  });

  final ActiveChampionPickState state;

  @override
  Widget build(BuildContext context) {
    final selectedBuild = state.builds[state.selectedBuildIndex];
    final selectedPerkStyle = PerkStyle.fromId(selectedBuild.build.runes.primaryPath);

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    state.pickedChampion.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 16),
                  _RoleTag(role: state.role),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<ChampionPickBloc>().add(TapImportBuildChampionPickEvent()),
                    icon: const Icon(Icons.file_upload_rounded),
                    label: const Text('ИМПОРТИРОВАТЬ'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  state.builds.length,
                  (index) {
                    final build = state.builds[index];

                    return _BuildTab(
                      keyPerkIcon: state.runesImages[build.keystoneId]!,
                      championBuild: build,
                      color: index == state.selectedBuildIndex ? selectedPerkStyle.color : null,
                      onTap: () => context.read<ChampionPickBloc>().add(TapAvailableBuildTabChampionPickEvent(index)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return BuildDetails(
                    singleColumn: constraints.maxWidth < 720,
                    championBuild: state.builds[state.selectedBuildIndex],
                    runesImages: state.runesImages,
                    itemImages: state.itemImages,
                    summonerSpellImages: state.summonerSpellImages,
                    color: selectedPerkStyle.color,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  final Role role;

  const _RoleTag({
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (role == Role.aram) {
      return Text(
        'ARAM',
        style: TextStyle(color: theme.colorScheme.primary),
      );
    }

    const iconSize = Size(32, 32);

    return DropdownButton<Role>(
      value: role,
      underline: const SizedBox.shrink(),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      onChanged: (role) => context.read<ChampionPickBloc>().add(SelectRoleChampionPickEvent(role!)),
      items: const [
        DropdownMenuItem(
          value: Role.toplane,
          child: CustomPaint(
            size: iconSize,
            painter: PositionTopPainter(),
          ),
        ),
        DropdownMenuItem(
          value: Role.jungler,
          child: CustomPaint(
            size: iconSize,
            painter: PositionJunglePainter(),
          ),
        ),
        DropdownMenuItem(
          value: Role.midlane,
          child: CustomPaint(
            size: iconSize,
            painter: PositionMidPainter(),
          ),
        ),
        DropdownMenuItem(
          value: Role.botlane,
          child: CustomPaint(
            size: iconSize,
            painter: PositionBotPainter(),
          ),
        ),
        DropdownMenuItem(
          value: Role.support,
          child: CustomPaint(
            size: iconSize,
            painter: PositionSupportPainter(),
          ),
        ),
      ],
    );
  }
}

class _BuildTab extends StatelessWidget {
  const _BuildTab({
    required this.championBuild,
    required this.color,
    required this.keyPerkIcon,
    this.onTap,
  });

  final SenpaiBuildInfo championBuild;
  final LcuImage keyPerkIcon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 12),
          child: Row(
            children: [
              Image.network(keyPerkIcon.url, headers: keyPerkIcon.headers, height: 50, width: 50),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(appLocalizations.winrate(championBuild.winRate), style: textStyle),
                  Text(appLocalizations.matchesCount(championBuild.numMatches), style: textStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
