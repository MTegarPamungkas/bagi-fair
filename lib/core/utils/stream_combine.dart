import 'dart:async';

/// Combines the latest value of two or more streams into one.
///
/// The domain uses this to project the local cache into view models without
/// pulling in a reactive extensions dependency. Every produced stream is
/// single-subscription, matching what Bloc expects.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  return _combineLatest(<Stream<Object?>>[first, second], (values) {
    return combine(values[0] as A, values[1] as B);
  });
}

Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  R Function(A first, B second, C third) combine,
) {
  return _combineLatest(<Stream<Object?>>[first, second, third], (values) {
    return combine(values[0] as A, values[1] as B, values[2] as C);
  });
}

Stream<R> combineLatest4<A, B, C, D, R>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  Stream<D> fourth,
  R Function(A first, B second, C third, D fourth) combine,
) {
  return _combineLatest(
    <Stream<Object?>>[first, second, third, fourth],
    (values) =>
        combine(values[0] as A, values[1] as B, values[2] as C, values[3] as D),
  );
}

Stream<R> combineLatest5<A, B, C, D, E, R>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  Stream<D> fourth,
  Stream<E> fifth,
  R Function(A first, B second, C third, D fourth, E fifth) combine,
) {
  return _combineLatest(
    <Stream<Object?>>[first, second, third, fourth, fifth],
    (values) => combine(
      values[0] as A,
      values[1] as B,
      values[2] as C,
      values[3] as D,
      values[4] as E,
    ),
  );
}

Stream<R> combineLatest6<A, B, C, D, E, F, R>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  Stream<D> fourth,
  Stream<E> fifth,
  Stream<F> sixth,
  R Function(A first, B second, C third, D fourth, E fifth, F sixth) combine,
) {
  return _combineLatest(
    <Stream<Object?>>[first, second, third, fourth, fifth, sixth],
    (values) => combine(
      values[0] as A,
      values[1] as B,
      values[2] as C,
      values[3] as D,
      values[4] as E,
      values[5] as F,
    ),
  );
}

Stream<R> _combineLatest<R>(
  List<Stream<Object?>> sources,
  R Function(List<Object?>) combine,
) {
  late StreamController<R> controller;
  final subscriptions = <StreamSubscription<Object?>>[];
  final latest = List<Object?>.filled(sources.length, _sentinel);
  var completed = 0;
  var hasValue = false;

  void emit() {
    if (latest.contains(_sentinel)) return;
    hasValue = true;
    if (!controller.isClosed) {
      controller.add(combine(List<Object?>.from(latest)));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      for (var index = 0; index < sources.length; index++) {
        final position = index;
        subscriptions.add(
          sources[index].listen(
            (value) {
              latest[position] = value;
              emit();
            },
            onError: controller.addError,
            onDone: () {
              completed++;
              if (completed == sources.length && !hasValue) {
                controller.close();
              }
            },
          ),
        );
      }
    },
    onPause: () {
      for (final subscription in subscriptions) {
        subscription.pause();
      }
    },
    onResume: () {
      for (final subscription in subscriptions) {
        subscription.resume();
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    },
  );
  return controller.stream;
}

const Object _sentinel = Object();
