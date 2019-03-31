import 'dart:async';

import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  group('SELECT statements are generated', () {
    test('for simple statements', () {
      db.select(db.users).get();
      verify(executor.runSelect('SELECT * FROM users;', argThat(isEmpty)));
    });

    test('with limit statements', () {
      (db.select(db.users)..limit(10)).get();
      verify(executor.runSelect(
          'SELECT * FROM users LIMIT 10;', argThat(isEmpty)));
    });

    test('with like expressions', () {
      (db.select(db.users)..where((u) => u.name.like('Dash%'))).get();
      verify(executor
          .runSelect('SELECT * FROM users WHERE name LIKE ?;', ['Dash%']));
    });

    test('with order-by clauses', () async {
      await (db.select(db.users)
            ..orderBy([
              (u) => OrderingTerm(
                  expression: u.isAwesome, mode: OrderingMode.desc),
              (u) => OrderingTerm(expression: u.id)
            ]))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users ORDER BY '
          'is_awesome DESC, id ASC;',
          argThat(isEmpty)));
    });

    test('with complex predicates', () {
      (db.select(db.users)
            ..where((u) =>
                and(not(u.name.equals('Dash')), (u.id.isBiggerThanValue(12)))))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE (NOT name = ?) AND (id > ?);',
          ['Dash', 12]));
    });

    test('with expressions from boolean columns', () {
      (db.select(db.users)..where((u) => u.isAwesome)).get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE is_awesome;', argThat(isEmpty)));
    });

    test('with aliased tables', () async {
      final users = db.alias(db.users, 'u');
      await (db.select(users)..where((u) => u.id.isSmallerThan(Constant(5))))
          .get();

      verify(executor.runSelect('SELECT * FROM users u WHERE id < 5;', []));
    });
  });

  group('SELECT results are parsed', () {
    test('when all fields are non-null', () {
      final data = [
        {'id': 10, 'title': 'A todo title', 'content': 'Content', 'category': 3}
      ];
      final resolved = TodoEntry(
        id: 10,
        title: 'A todo title',
        content: 'Content',
        category: 3,
      );

      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value(data));

      expect(db.select(db.todosTable).get(), completion([resolved]));
    });

    test('when some fields are null', () {
      final data = [
        {
          'id': 10,
          'title': null,
          'content': 'Content',
          'category': null,
        }
      ];
      final resolved = TodoEntry(
        id: 10,
        title: null,
        content: 'Content',
        category: null,
      );

      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value(data));

      expect(db.select(db.todosTable).get(), completion([resolved]));
    });
  });
}
