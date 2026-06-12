import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_wizard/form_wizard.dart';

void main() {
  testWidgets('updates only the interacted field', (tester) async {
    final controller = FormWizardController();
    var firstBuilds = 0;
    var secondBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'first',
                label: 'First',
                type: FieldType.custom,
                customBuilder: (textController, errorText, onChanged) {
                  firstBuilds++;
                  return TextField(
                    key: const ValueKey<String>('first-field'),
                    controller: textController,
                    onChanged: onChanged,
                    decoration: InputDecoration(errorText: errorText),
                  );
                },
              ),
              FormWizardFieldModel(
                name: 'second',
                label: 'Second',
                type: FieldType.custom,
                customBuilder: (textController, errorText, onChanged) {
                  secondBuilds++;
                  return TextField(
                    key: const ValueKey<String>('second-field'),
                    controller: textController,
                    onChanged: onChanged,
                    decoration: InputDecoration(errorText: errorText),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    firstBuilds = 0;
    secondBuilds = 0;

    await tester.enterText(
      find.byKey(const ValueKey<String>('first-field')),
      'a',
    );
    await tester.pump();

    expect(firstBuilds, greaterThan(0));
    expect(secondBuilds, 0);
    expect(controller.formData, containsPair('first', 'a'));
  });

  testWidgets('validates and submits form values', (tester) async {
    final controller = FormWizardController();
    Map<String, dynamic>? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'email',
                label: 'Email',
                type: FieldType.email,
                validators: [Validators.required(), Validators.email()],
              ),
            ],
            onSubmit: (values) => submitted = values,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('This field is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'hello@example.com');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, containsPair('email', 'hello@example.com'));
  });

  testWidgets('conditionally visible fields react to declared dependencies', (
    tester,
  ) async {
    final controller = FormWizardController();
    Map<String, dynamic>? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'country',
                label: 'Country',
                type: FieldType.text,
              ),
              FormWizardFieldModel(
                name: 'state',
                label: 'State',
                type: FieldType.text,
                validators: [Validators.required()],
                visibleWhenDependsOn: const ['country'],
                visibleWhen: (values) => values['country'] == 'USA',
              ),
            ],
            onSubmit: (values) => submitted = values,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'State'), findsNothing);

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, isNotNull);
    submitted = null;

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Country'),
      'USA',
    );
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'State'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('dynamic field arrays add, remove, and reorder items', (
    tester,
  ) async {
    final controller = FormWizardController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: const [],
            fieldArrays: [
              FormWizardFieldArrayModel(
                name: 'phones',
                label: 'Phone Numbers',
                initialItemCount: 1,
                minItems: 1,
                fieldBuilder: (context) {
                  return [
                    FormWizardFieldModel(
                      name: context.fieldName('number'),
                      label: 'Phone ${context.index + 1}',
                      type: FieldType.custom,
                      customBuilder: (textController, errorText, onChanged) {
                        return TextField(
                          key: ValueKey<String>(context.fieldName('number')),
                          controller: textController,
                          onChanged: onChanged,
                          decoration: InputDecoration(errorText: errorText),
                        );
                      },
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    var itemIds = controller.fieldArrays.value['phones']!;
    expect(itemIds, hasLength(1));

    await tester.enterText(
      find.byKey(ValueKey<String>('phones.${itemIds.first}.number')),
      '111',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pump();
    await tester.pump();

    itemIds = controller.fieldArrays.value['phones']!;
    expect(itemIds, hasLength(2));

    await tester.enterText(
      find.byKey(ValueKey<String>('phones.${itemIds.last}.number')),
      '222',
    );
    await tester.pump();

    controller.reorderFieldArrayItem('phones', 1, 0);
    await tester.pump();

    itemIds = controller.fieldArrays.value['phones']!;
    expect(controller.formData['phones.${itemIds.first}.number'], '222');
    expect(controller.formData['phones.${itemIds.last}.number'], '111');

    controller.removeFieldArrayItem('phones', itemIds.last);
    await tester.pump();

    itemIds = controller.fieldArrays.value['phones']!;
    expect(itemIds, hasLength(1));
    expect(controller.formData.values, isNot(contains('111')));
    expect(controller.formData.values, contains('222'));
  });

  testWidgets('stepper validates navigation and persists step data', (
    tester,
  ) async {
    Map<String, dynamic>? finished;
    var changedStep = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizardStepper(
            steps: [
              FormWizardStep(
                title: 'Personal',
                fields: [FormWizard.nameField(name: 'name')],
              ),
              FormWizardStep(
                title: 'Contact',
                fields: [FormWizard.emailField(name: 'email')],
              ),
            ],
            onStepChanged: (step) => changedStep = step,
            onFinish: (values) => finished = values,
            stepBuilder: (context, stepper) {
              return Column(
                children: [
                  Text(stepper.steps[stepper.currentStep].title),
                  stepper.fields,
                  ElevatedButton(
                    key: const ValueKey<String>('next-step'),
                    onPressed: stepper.onNext,
                    child: Text(
                      stepper.currentStep == stepper.steps.length - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
    bool nextEnabled() {
      return tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey<String>('next-step')),
          )
          .enabled;
    }

    expect(nextEnabled(), isFalse);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'Ava',
    );
    await tester.pump();
    await tester.pump();

    expect(nextEnabled(), isTrue);
    await tester.tap(find.byKey(const ValueKey<String>('next-step')));
    await tester.pump();

    expect(changedStep, 1);
    expect(find.widgetWithText(TextFormField, 'Full Name'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ava@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('next-step')));
    await tester.pump();

    expect(finished, containsPair('name', 'Ava'));
    expect(finished, containsPair('email', 'ava@example.com'));
  });

  testWidgets('login template calls onLogin with submitted credentials', (
    tester,
  ) async {
    String? identity;
    String? password;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginForm(
            onLogin: (submittedIdentity, submittedPassword) {
              identity = submittedIdentity;
              password = submittedPassword;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'hello@example.com',
    );
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(identity, 'hello@example.com');
    expect(password, 'password123');
  });

  testWidgets('tab switching does not update disposed provider scopes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: const TabBar(
              tabs: [Tab(text: 'Form'), Tab(text: 'Stepper')],
            ),
            body: TabBarView(
              children: [
                FormWizard(
                  controller: FormWizardController(),
                  fields: [
                    FormWizard.countryDropdown(
                      countries: const ['India', 'United States'],
                    ),
                    FormWizardFieldModel(
                      name: 'state',
                      label: 'State',
                      type: FieldType.text,
                      visibleWhenDependsOn: const ['country'],
                      visibleWhen:
                          (values) => values['country'] == 'United States',
                    ),
                  ],
                ),
                FormWizardStepper(
                  steps: [
                    FormWizardStep(
                      title: 'Personal',
                      fields: [FormWizard.nameField()],
                    ),
                    FormWizardStep(
                      title: 'Contact',
                      fields: [FormWizard.emailField()],
                    ),
                  ],
                  onFinish: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Stepper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Form'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('async validators update only their field state', (tester) async {
    final controller = FormWizardController();
    var usernameBuilds = 0;
    var emailBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'username',
                label: 'Username',
                type: FieldType.custom,
                asyncValidationDebounce: Duration.zero,
                asyncValidators: [
                  (value, context) async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 10),
                    );
                    return value == 'taken' ? 'Username is taken' : null;
                  },
                ],
                customBuilder: (textController, errorText, onChanged) {
                  usernameBuilds++;
                  return TextField(
                    key: const ValueKey<String>('username-field'),
                    controller: textController,
                    onChanged: onChanged,
                    decoration: InputDecoration(errorText: errorText),
                  );
                },
              ),
              FormWizardFieldModel(
                name: 'email',
                label: 'Email',
                type: FieldType.custom,
                customBuilder: (textController, errorText, onChanged) {
                  emailBuilds++;
                  return TextField(
                    key: const ValueKey<String>('email-field'),
                    controller: textController,
                    onChanged: onChanged,
                    decoration: InputDecoration(errorText: errorText),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    usernameBuilds = 0;
    emailBuilds = 0;

    await tester.enterText(
      find.byKey(const ValueKey<String>('username-field')),
      'taken',
    );
    await tester.pump();

    expect(controller.isValidating.value, isTrue);
    expect(emailBuilds, 0);

    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Username is taken'), findsOneWidget);
    expect(controller.isValidating.value, isFalse);
    expect(usernameBuilds, greaterThan(0));
    expect(emailBuilds, 0);
  });

  testWidgets('validation dependencies revalidate dependent fields', (
    tester,
  ) async {
    final controller = FormWizardController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'password',
                label: 'Password',
                type: FieldType.password,
              ),
              FormWizardFieldModel(
                name: 'confirm_password',
                label: 'Confirm Password',
                type: FieldType.password,
                contextValidators: [
                  Validators.matchesField(
                    'password',
                    message: 'Passwords do not match',
                  ),
                ],
                validationDependsOn: const ['password'],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'first-secret',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'first-secret',
    );
    await tester.pump();

    expect(find.text('Passwords do not match'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'second-secret',
    );
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('controller can submit transformed values', (tester) async {
    final controller = FormWizardController();
    Map<String, dynamic>? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormWizard(
            controller: controller,
            fields: [
              FormWizardFieldModel(
                name: 'age',
                label: 'Age',
                type: FieldType.number,
                validators: [Validators.required(), Validators.number()],
                valueTransformer:
                    (value, context) => int.tryParse(value?.toString() ?? ''),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '42');
    await tester.pump();

    final isSubmitted = await controller.submitFormAsync(
      (values) => submitted = values,
      transformValues: true,
    );

    expect(isSubmitted, isTrue);
    expect(submitted, containsPair('age', 42));
  });
}
