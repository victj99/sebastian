import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:sebastian/data/lcu/lcu.dart';
import 'package:sebastian/data/lcu/models/item_build.dart';
import 'package:sebastian/data/lcu/models/lcu_error.dart';
import 'package:sebastian/data/lcu/models/rune_page.dart';
import 'package:sebastian/data/lcu/pick_session.dart';

class LeagueClientEventRepository {
  final LCU _lcu;

  LeagueClientEventRepository(this._lcu);

  final _pickSessionSubject = BehaviorSubject<PickSession?>.seeded(null);
  final _endGameSubject = PublishSubject<bool>();

  StreamSubscription? _pickSessionSubcription;
  StreamSubscription? _endGameSubscription;

  Stream<PickSession?> observePickSession() {
    _pickSessionSubcription ??= _lcu
        .subscribeToChampSelectEvent()
        .map(_parsePickSessionEvent)
        .listen((event) => _pickSessionSubject.add(event));

    return _pickSessionSubject.stream;
  }

  PickSession? _parsePickSessionEvent(dynamic eventMessage) {
    if (eventMessage == null) return null;

    if (eventMessage['eventType'] == 'Delete') return null;

    final data = eventMessage['data'];
    if (data == null) return null;

    return PickSession.fromJson(data);
  }

  Stream<dynamic> observeGameEndEvent() {
    _endGameSubscription ??= _lcu.subscribeToEndOfGameEvent().listen((event) {
      if (event['data'] == 'PreEndOfGame') {
        _endGameSubject.add(true);
      }
    });

    return _endGameSubject.stream;
  }

  Future<void> setRunePage(RunePage page) async {
    try {
      await _lcu.service.postRunePage(page);
    } on LcuError catch (error) {
      if (error.message == 'Max pages reached') {
        await _lcu.service.deleteCurrentPage();
        await _lcu.service.postRunePage(page);
      }
    }
  }

  Future<void> setItemBuild(ItemBuild build) async {
    _clearUpgradableItems(build);
    await _lcu.saveBuildFile(build);
  }

  /// Some items in builds appears in their final form which cannot be bought from the store
  /// so we shound replace them with
  void _clearUpgradableItems(ItemBuild build) {
    for (var block in build.blocks) {
      for (var i = 0; i < block.items.length; i++) {
        final dowgradeItemId = _downgradeItemsMap[block.items[i].id];
        if (dowgradeItemId != null) {
          block.items[i] = block.items[i].copyWith(id: dowgradeItemId);
        }
      }
    }
  }

  static const _downgradeItemsMap = {
    '3040': '3003', // Seraph's Embrace        -> Achangel's Staff
    '3042': '3004', // Muramana                -> Manamune
    '3121': '3042', // Fimbulwinter            -> Winter's Approach
    '3851': '3850', // Frostfang               -> Spellthief's Edge
    '3853': '3850', // Shard of True Ice       -> Spellthief's Edge
    '3855': '3854', // Runesteel Spaulders     -> Steel Shoulderguards
    '3857': '3854', // Pauldrons of Whiterock  -> Steel Shoulderguards
    '3859': '3858', // Targon's Buckler        -> Relic Shield
    '3860': '3858', // Bulwark of the Mountain -> Relic Shield
    '3863': '3862', // Harrowing Crescent      -> Spectral Sickle
    '3864': '3862', // Black Mist Scythe       -> Spectral Sickle
  };
}
