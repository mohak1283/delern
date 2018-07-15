import 'dart:async';

import '../models/base/stream_demuxer.dart';
import '../models/base/transaction.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/scheduled_card.dart';

class LearningViewModel {
  ScheduledCard _scheduledCard;
  Card get card => _scheduledCard?.card;

  final Deck deck;

  LearningViewModel(this.deck);

  Stream<void> get updates => StreamDemuxer({
        0: deck.updates,
        1: ScheduledCard.next(deck.key, deck.uid).transform(StreamTransformer
            .fromHandlers(handleData: (sc, EventSink<void> sink) {
          // TODO(ksheremet): allow users to learn beyond the time horizon.
          if (sc.repeatAt.isAfter(DateTime.now().toUtc())) {
            sink.close();
            return;
          }
          _scheduledCard = sc;
          sink.add(null);
        })),
      });

  Future<void> answer(bool knows) {
    var cv = _scheduledCard.answer(knows);
    return (Transaction()..save(_scheduledCard)..save(cv)).commit();
  }

  Future<void> deleteCard() =>
      (Transaction()..delete(card)..delete(_scheduledCard)).commit();
}
